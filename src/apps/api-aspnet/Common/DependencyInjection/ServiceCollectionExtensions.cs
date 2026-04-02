using System.Text;
using SeriesCatalog.WebApi.Auth;
using SeriesCatalog.WebApi.Common.Authorization;
using SeriesCatalog.WebApi.Services.Auth;
using SeriesCatalog.WebApi.Services.Series;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;

namespace SeriesCatalog.WebApi.Common.DependencyInjection;

public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddApiApplication(this IServiceCollection services, IConfiguration configuration)
    {
        services.AddOpenApi();
        services.AddProblemDetails();

        var jwtSection = configuration.GetSection(JwtOptions.SectionName);
        services.Configure<JwtOptions>(jwtSection);
        var configuredSigningKey = jwtSection["Key"];
        var signingKey = string.IsNullOrWhiteSpace(configuredSigningKey)
            ? "development-signing-key-change-before-production"
            : configuredSigningKey;

        services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
            .AddJwtBearer(options =>
            {
                var issuer = jwtSection["Issuer"];
                var audience = jwtSection["Audience"];

                options.TokenValidationParameters = new TokenValidationParameters
                {
                    ValidateIssuerSigningKey = true,
                    IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(signingKey)),
                    ValidateIssuer = !string.IsNullOrWhiteSpace(issuer),
                    ValidIssuer = issuer,
                    ValidateAudience = !string.IsNullOrWhiteSpace(audience),
                    ValidAudience = audience,
                    ValidateLifetime = true,
                    ClockSkew = TimeSpan.FromSeconds(30)
                };
            });

        services.AddAuthorization();
        services.AddScoped<IAuthTokenService, JwtAuthTokenService>();
        services.AddScoped<IAuthService, AuthService>();
        services.AddScoped<ISeriesService, SeriesService>();

        var corsOrigins = configuration
            .GetSection("Cors:AllowedOrigins")
            .GetChildren()
            .Select(section => section.Value)
            .Where(value => !string.IsNullOrWhiteSpace(value))
            .Cast<string>()
            .ToArray();

        services.AddCors(options =>
        {
            options.AddPolicy(ApiPolicies.CorsPolicyName, policyBuilder =>
            {
                var supportsCredentials = corsOrigins.Length > 0;

                if (corsOrigins.Length > 0)
                {
                    policyBuilder.WithOrigins(corsOrigins);
                }
                else
                {
                    policyBuilder.AllowAnyOrigin();
                }

                policyBuilder
                    .WithMethods("GET", "HEAD", "PUT", "PATCH", "POST", "DELETE")
                    .WithHeaders("Content-Type", "Accept", "Authorization");

                if (supportsCredentials)
                {
                    policyBuilder.AllowCredentials();
                }
            });
        });

        return services;
    }
}

