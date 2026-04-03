using SeriesCatalog.Frontend.Components;
using SeriesCatalog.Frontend.Services.Api;
using SeriesCatalog.Frontend.Services.Auth;
using SeriesCatalog.Frontend.Services.Series;
using SeriesCatalog.Frontend.Services.Users;
using Microsoft.AspNetCore.Components.Authorization;
using Microsoft.AspNetCore.DataProtection;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddRazorComponents()
    .AddInteractiveServerComponents();
var dataProtectionPath = builder.Configuration["DataProtection:KeyRingPath"]
    ?? Path.Combine(builder.Environment.ContentRootPath, ".aspnet", "DataProtection-Keys");
Directory.CreateDirectory(dataProtectionPath);
builder.Services
    .AddDataProtection()
    .SetApplicationName("SeriesCatalog.Frontend")
    .PersistKeysToFileSystem(new DirectoryInfo(dataProtectionPath));
builder.Services.Configure<ApiOptions>(builder.Configuration.GetSection(ApiOptions.SectionName));
builder.Services.AddAuthorizationCore();
builder.Services.AddCascadingAuthenticationState();
builder.Services.AddScoped<ClientAuthState>();
builder.Services.AddScoped<BlazorAuthStateProvider>();
builder.Services.AddScoped<AuthenticationStateProvider>(sp => sp.GetRequiredService<BlazorAuthStateProvider>());
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<SeriesSearchState>();
builder.Services.AddScoped<ISeriesService, SeriesService>();
builder.Services.AddScoped<IUsersService, UsersService>();
builder.Services.AddHttpClient("BackendApi", (sp, client) =>
{
    var apiOptions = sp.GetRequiredService<Microsoft.Extensions.Options.IOptions<ApiOptions>>().Value;
    client.BaseAddress = new Uri(apiOptions.BaseUrl);
});

var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error", createScopeForErrors: true);
}
app.UseStatusCodePagesWithReExecute("/not-found", createScopeForStatusCodePages: true);
app.Use(async (context, next) =>
{
    var startedAt = DateTime.UtcNow;
    await next();
    var elapsedMs = (DateTime.UtcNow - startedAt).TotalMilliseconds;
    app.Logger.LogInformation(
        "HTTP {Method} {Path} => {StatusCode} in {ElapsedMs:0.0}ms",
        context.Request.Method,
        context.Request.Path,
        context.Response.StatusCode,
        elapsedMs);
});
app.UseAntiforgery();

app.MapStaticAssets();
app.MapRazorComponents<App>()
    .AddInteractiveServerRenderMode();

await app.RunAsync();


