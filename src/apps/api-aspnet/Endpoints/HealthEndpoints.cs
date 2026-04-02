namespace Appd.Api.Endpoints;

public static class HealthEndpoints
{
    public static IEndpointRouteBuilder MapHealthEndpoints(this IEndpointRouteBuilder endpoints)
    {
        endpoints.MapGet("/api/health", () => Results.Ok(new { status = "ok" }));
        endpoints.MapGet("/api/protected/ping", () => Results.Ok(new { status = "authorized" }))
            .RequireAuthorization();
        return endpoints;
    }
}
