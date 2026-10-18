using P21_Price_Lookup.Services;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddRazorPages();

builder.Services.AddOptions<P21Options>()
    .Bind(builder.Configuration.GetSection(P21Options.SectionName))
    .ValidateDataAnnotations();

// Username/password are never in appsettings.json — user-secrets locally, env vars when deployed.
builder.Services.PostConfigure<P21Options>(o =>
{
    o.Username = Environment.GetEnvironmentVariable("P21_USERNAME") ?? o.Username;
    o.Password = Environment.GetEnvironmentVariable("P21_PASSWORD") ?? o.Password;
});

// AllowAutoRedirect stays off: .NET's default handler strips the Authorization header when it
// follows a redirect, which silently turns a valid Bearer request into an unauthenticated one.
builder.Services.AddHttpClient<P21PricingClient>()
    .ConfigurePrimaryHttpMessageHandler(() => new HttpClientHandler { AllowAutoRedirect = false });

var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error");
}

app.UseRouting();

app.UseAuthorization();

app.MapStaticAssets();
app.MapRazorPages()
   .WithStaticAssets();

app.Run();
