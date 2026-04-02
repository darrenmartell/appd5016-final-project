using Appd.Api.Mappers;
using Appd.Infrastructure.MongoDb.Repositories;

namespace Appd.Api.Endpoints;

public static class UserEndpoints
{
    public static IEndpointRouteBuilder MapUserEndpoints(this IEndpointRouteBuilder endpoints)
    {
        endpoints.MapGet("/users", async Task<IResult> (IUserRepository users, CancellationToken cancellationToken) =>
        {
            var items = await users.ListAsync(cancellationToken);
            if (items.Count == 0)
            {
                return Results.NotFound(new { message = "No users found" });
            }

            return Results.Ok(items.Select(user => user.ToResponse()));
        });

        endpoints.MapGet("/users/{id}", async Task<IResult> (string id, IUserRepository users, CancellationToken cancellationToken) =>
        {
            var user = await users.FindByIdAsync(id, cancellationToken);
            if (user is null)
            {
                return Results.NotFound(new { message = $"User with id {id} not found" });
            }

            return Results.Ok(user.ToResponse());
        });

        endpoints.MapDelete("/users/{id}", async Task<IResult> (string id, IUserRepository users, CancellationToken cancellationToken) =>
            {
                var deleted = await users.DeleteByIdAsync(id, cancellationToken);
                if (deleted is null)
                {
                    return Results.NotFound(new { message = $"User with id {id} not found" });
                }

                return Results.Ok(deleted.ToResponse());
            })
            .RequireAuthorization();

        return endpoints;
    }
}
