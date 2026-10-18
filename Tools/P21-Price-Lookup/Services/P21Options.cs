namespace P21_Price_Lookup.Services;

// Non-secret settings come from appsettings.json.
// Username/Password are deliberately NOT read from appsettings.json — see appsettings.json comment.
public class P21Options
{
    public const string SectionName = "P21";

    public required string BaseUrl { get; set; }
    public required string StoreName { get; set; }
    public required string DefaultLocationId { get; set; }
    public string Username { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
}
