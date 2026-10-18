using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using P21_Price_Lookup.Services;

namespace P21_Price_Lookup.Pages;

public class IndexModel : PageModel
{
    private readonly P21PricingClient _pricingClient;
    private readonly ILogger<IndexModel> _logger;

    public IndexModel(P21PricingClient pricingClient, ILogger<IndexModel> logger)
    {
        _pricingClient = pricingClient;
        _logger = logger;
    }

    [BindProperty]
    public PriceLookupInput Input { get; set; } = new();

    public PriceLookupResult? Result { get; private set; }

    public void OnGet()
    {
    }

    public async Task OnPostAsync(CancellationToken ct)
    {
        if (!ModelState.IsValid)
        {
            return;
        }

        try
        {
            Result = await _pricingClient.GetItemPriceAsync(
                Input.CustomerId.Trim(), Input.ItemId.Trim(), Input.QtyOrdered, Input.UnitName.Trim(), ct);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Price lookup failed for customer {Customer} / item {Item}", Input.CustomerId, Input.ItemId);
            Result = new PriceLookupResult(false, $"Lookup failed: {ex.Message}", null, null, false, null);
        }
    }

    public class PriceLookupInput
    {
        [Required(ErrorMessage = "Customer ID is required.")]
        [Display(Name = "Customer ID")]
        public string CustomerId { get; set; } = string.Empty;

        [Required(ErrorMessage = "Item ID is required.")]
        [Display(Name = "Item ID")]
        public string ItemId { get; set; } = string.Empty;

        [Required(ErrorMessage = "Quantity is required.")]
        [Range(0.0001, double.MaxValue, ErrorMessage = "Quantity must be greater than 0.")]
        [Display(Name = "Qty Ordered")]
        public decimal QtyOrdered { get; set; } = 1;

        [Required(ErrorMessage = "Unit is required.")]
        [Display(Name = "Unit")]
        public string UnitName { get; set; } = "EA";
    }
}
