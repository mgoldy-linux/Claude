using System.Net;
using System.Xml.Linq;
using Microsoft.Extensions.Options;

namespace P21_Price_Lookup.Services;

public record PriceLookupResult(
    bool Success,
    string? ErrorMessage,
    decimal? NetPrice,
    decimal? ListPrice,
    bool PricedByContract,
    string? PricePageUid);

// Talks to P21's /api/ecommerce GetItemPrice call — same request shape proven working
// against P21Dev via Postman on 2026-09-22 (customer 3000143 / item FUT150553809-23 / 75 RL
// matched Order Entry's $2.04/RL).
public class P21PricingClient
{
    private readonly HttpClient _http;
    private readonly P21Options _options;
    private readonly ILogger<P21PricingClient> _logger;

    private string? _cachedToken;
    private DateTimeOffset _tokenExpiresAt = DateTimeOffset.MinValue;
    private readonly SemaphoreSlim _tokenLock = new(1, 1);

    public P21PricingClient(HttpClient http, IOptions<P21Options> options, ILogger<P21PricingClient> logger)
    {
        _http = http;
        _options = options.Value;
        _logger = logger;
    }

    public async Task<PriceLookupResult> GetItemPriceAsync(
        string customerId, string itemId, decimal qtyOrdered, string unitName, CancellationToken ct)
    {
        var token = await GetAccessTokenAsync(ct);

        var requestXml =
            $"""
             <GetItemPrice>
               <Request>
                 <B2BSellerVersion>
                   <MajorVersion xmlns="Request">5</MajorVersion>
                   <MinorVersion xmlns="Request">11</MinorVersion>
                   <BuildNumber xmlns="Request">100</BuildNumber>
                 </B2BSellerVersion>
                 <CustomerCode>{XmlEscape(customerId)}</CustomerCode>
                 <StoreName>{XmlEscape(_options.StoreName)}</StoreName>
                 <LocationID>{XmlEscape(_options.DefaultLocationId)}</LocationID>
                 <GetAvailabilityOnly>FALSE</GetAvailabilityOnly>
                 <ShipToID>{XmlEscape(customerId)}</ShipToID>
                 <ListOfItems>
                   <Item>
                     <ItemID xmlns="Request">{XmlEscape(itemId)}</ItemID>
                     <Quantity xmlns="Request">{qtyOrdered}</Quantity>
                     <UnitName xmlns="Request">{XmlEscape(unitName)}</UnitName>
                   </Item>
                 </ListOfItems>
                 <GetListOfItemLocationQuantities>FALSE</GetListOfItemLocationQuantities>
               </Request>
             </GetItemPrice>
             """;

        // Trailing slash required — the WCF endpoint 301s "/api/ecommerce" -> "/api/ecommerce/",
        // and .NET's redirect handling strips the Authorization header when it follows that.
        using var request = new HttpRequestMessage(HttpMethod.Post, $"{_options.BaseUrl}/api/ecommerce/")
        {
            Content = new StringContent(requestXml, System.Text.Encoding.UTF8, "application/xml"),
            Version = HttpVersion.Version11,
            VersionPolicy = HttpVersionPolicy.RequestVersionExact
        };
        request.Headers.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", token);

        using var response = await _http.SendAsync(request, ct);
        var body = await response.Content.ReadAsStringAsync(ct);

        if (!response.IsSuccessStatusCode)
        {
            var wwwAuth = response.Headers.WwwAuthenticate.ToString();
            _logger.LogWarning(
                "P21 GetItemPrice returned {Status} for customer {Customer} / item {Item}. WWW-Authenticate: {WwwAuth}. Body: {Body}",
                response.StatusCode, customerId, itemId, wwwAuth, body);

            var bodySnippet = body.Length > 300 ? body[..300] + "…" : body;
            var detail = string.IsNullOrWhiteSpace(bodySnippet) ? "" : $" Body: {bodySnippet}";
            var authDetail = string.IsNullOrWhiteSpace(wwwAuth) ? "" : $" WWW-Authenticate: {wwwAuth}.";
            var locationDetail = response.Headers.Location is not null ? $" Redirected to: {response.Headers.Location}." : "";
            return new PriceLookupResult(false, $"P21 returned HTTP {(int)response.StatusCode}.{authDetail}{locationDetail}{detail}", null, null, false, null);
        }

        var doc = XDocument.Parse(body);
        var result = doc.Descendants().FirstOrDefault(e => e.Name.LocalName == "Result")?.Value?.Trim();

        if (result != "0")
        {
            var message = doc.Descendants().FirstOrDefault(e => e.Name.LocalName == "Message")?.Value?.Trim();
            return new PriceLookupResult(false, string.IsNullOrWhiteSpace(message) ? $"P21 returned Result {result}." : message, null, null, false, null);
        }

        var netPriceText = doc.Descendants().FirstOrDefault(e => e.Name.LocalName == "NetPrice")?.Value?.Trim();
        var listPriceText = doc.Descendants().FirstOrDefault(e => e.Name.LocalName == "ListPrice")?.Value?.Trim();
        var pricedByContract = doc.Descendants().FirstOrDefault(e => e.Name.LocalName == "PricedByContract")?.Value?.Trim();
        var pricePageUid = doc.Descendants().FirstOrDefault(e => e.Name.LocalName == "PricePageUID")?.Value?.Trim();

        if (!decimal.TryParse(netPriceText, out var netPrice))
        {
            return new PriceLookupResult(false, "P21 response did not include a NetPrice — check the customer/item/qty combination.", null, null, false, null);
        }

        decimal? listPrice = decimal.TryParse(listPriceText, out var lp) ? lp : null;

        return new PriceLookupResult(
            Success: true,
            ErrorMessage: null,
            NetPrice: netPrice,
            ListPrice: listPrice,
            PricedByContract: string.Equals(pricedByContract, "TRUE", StringComparison.OrdinalIgnoreCase),
            PricePageUid: string.IsNullOrWhiteSpace(pricePageUid) ? null : pricePageUid);
    }

    private async Task<string> GetAccessTokenAsync(CancellationToken ct)
    {
        if (_cachedToken is not null && DateTimeOffset.UtcNow < _tokenExpiresAt)
        {
            return _cachedToken;
        }

        await _tokenLock.WaitAsync(ct);
        try
        {
            if (_cachedToken is not null && DateTimeOffset.UtcNow < _tokenExpiresAt)
            {
                return _cachedToken;
            }

            if (string.IsNullOrEmpty(_options.Username) || string.IsNullOrEmpty(_options.Password))
            {
                throw new InvalidOperationException(
                    "P21 username/password are not configured. Set them via user-secrets (dev) or the P21_USERNAME / P21_PASSWORD environment variables.");
            }

            using var request = new HttpRequestMessage(HttpMethod.Post, $"{_options.BaseUrl}/api/security/token/")
            {
                Version = HttpVersion.Version11,
                VersionPolicy = HttpVersionPolicy.RequestVersionExact
            };
            request.Headers.Add("username", _options.Username);
            request.Headers.Add("password", _options.Password);

            using var response = await _http.SendAsync(request, ct);
            var body = await response.Content.ReadAsStringAsync(ct);
            response.EnsureSuccessStatusCode();

            var doc = XDocument.Parse(body);
            var accessToken = doc.Descendants().FirstOrDefault(e => e.Name.LocalName == "AccessToken")?.Value?.Trim();
            var expiresInText = doc.Descendants().FirstOrDefault(e => e.Name.LocalName == "ExpiresIn")?.Value?.Trim();

            if (string.IsNullOrEmpty(accessToken))
            {
                throw new InvalidOperationException("P21 token response did not contain an AccessToken.");
            }

            var expiresInSeconds = int.TryParse(expiresInText, out var s) ? s : 300;
            // Refresh a minute early so an in-flight price lookup never races an expiry.
            _tokenExpiresAt = DateTimeOffset.UtcNow.AddSeconds(Math.Max(expiresInSeconds - 60, 30));
            _cachedToken = accessToken;
            return _cachedToken;
        }
        finally
        {
            _tokenLock.Release();
        }
    }

    private static string XmlEscape(string value) => new XText(value).ToString();
}
