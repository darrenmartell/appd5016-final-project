using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text.RegularExpressions;
using SeriesCatalog.WebApi.Common.Validation;
using SeriesCatalog.WebApi.Contracts.Auth;
using SeriesCatalog.WebApi.Services.Auth;
using SeriesCatalog.Infrastructure.MongoDb.Repositories;
using Microsoft.AspNetCore.Mvc;

namespace SeriesCatalog.WebApi.Endpoints;

public static class AuthEndpoints
{
    private static readonly Regex PasswordPolicyRegex = new(
        "^(?=.*[A-Z])(?=.*[a-z])(?=.*\\d)(?=.*[!@#$%^&*()_+\\-=[\\]{};':\"\\|,.<>/?]).+$",
        RegexOptions.Compiled);

    public static IEndpointRouteBuilder MapAuthEndpoints(this IEndpointRouteBuilder endpoints)
    {
        endpoints.MapPost("/auth/login", async Task<IResult> (LoginRequest request, IAuthService authService, CancellationToken cancellationToken) =>
            {
                var response = await authService.LoginAsync(request, cancellationToken);
                if (response is null)
                {
                    return Results.Unauthorized();
                }

                return Results.Ok(response);
            })
            .AddEndpointFilter<DataAnnotationsValidationFilter<LoginRequest>>();

        endpoints.MapPost("/auth/register", async Task<IResult> (RegisterRequest request, IAuthService authService, CancellationToken cancellationToken) =>
            {
                var (response, userExists) = await authService.RegisterAsync(request, cancellationToken);
                if (userExists)
                {
                    return Results.Conflict(new { message = "User already exists" });
                }

                return Results.Created("/auth/register", response);
            })
            .AddEndpointFilter<DataAnnotationsValidationFilter<RegisterRequest>>();

        endpoints.MapPatch("/auth/{id}/changepassword", async Task<IResult> (
                string id,
                [FromBody] string newPassword,
                ClaimsPrincipal user,
                IUserRepository users,
                CancellationToken cancellationToken) =>
            {
                var userIdFromToken = user.FindFirstValue("_id") ?? user.FindFirstValue(JwtRegisteredClaimNames.Sub);
                if (string.IsNullOrWhiteSpace(userIdFromToken))
                {
                    return Results.Unauthorized();
                }

                if (!string.Equals(userIdFromToken, id, StringComparison.Ordinal))
                {
                    return Results.Forbid();
                }

                var errors = ValidatePassword(newPassword);
                if (errors.Count > 0)
                {
                    return Results.ValidationProblem(errors);
                }

                var hashed = BCrypt.Net.BCrypt.HashPassword(newPassword);
                var updated = await users.UpdatePasswordHashAsync(id, hashed, cancellationToken);
                if (updated is null)
                {
                    return Results.NotFound(new { message = $"User with id {id} not found" });
                }

                return Results.Ok(new { message = "Password changed successfully" });
            })
            .RequireAuthorization();

        return endpoints;
    }

    private static Dictionary<string, string[]> ValidatePassword(string password)
    {
        var errors = new Dictionary<string, string[]>(StringComparer.OrdinalIgnoreCase);

        if (string.IsNullOrWhiteSpace(password))
        {
            errors["newPassword"] = ["newPassword is required."];
            return errors;
        }

        var messages = new List<string>();
        if (password.Length is < 8 or > 128)
        {
            messages.Add("newPassword must be between 8 and 128 characters.");
        }

        if (!PasswordPolicyRegex.IsMatch(password))
        {
            messages.Add("Password must contain uppercase, lowercase, digit, and special character");
        }

        if (messages.Count > 0)
        {
            errors["newPassword"] = messages.ToArray();
        }

        return errors;
    }
}


