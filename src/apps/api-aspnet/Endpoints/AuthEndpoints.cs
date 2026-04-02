using Appd.Api.Common.Validation;
using Appd.Api.Contracts.Auth;
using Appd.Api.Services.Auth;

namespace Appd.Api.Endpoints;

public static class AuthEndpoints
{
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

        return endpoints;
    }
}
