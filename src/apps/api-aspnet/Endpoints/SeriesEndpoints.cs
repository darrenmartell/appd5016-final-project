using Appd.Api.Contracts.Series;
using Appd.Api.Common.Validation;
using Appd.Api.Mappers;
using Appd.Infrastructure.MongoDb.Repositories;

namespace Appd.Api.Endpoints;

public static class SeriesEndpoints
{
    public static IEndpointRouteBuilder MapSeriesEndpoints(this IEndpointRouteBuilder endpoints)
    {
        endpoints.MapGet("/api/series", async (ISeriesRepository repository, CancellationToken cancellationToken) =>
        {
            var items = await repository.ListAsync(cancellationToken);
            return Results.Ok(items);
        });

        endpoints.MapPost("/api/series", async (CreateSeriesRequest request, ISeriesRepository repository, CancellationToken cancellationToken) =>
            {
                var item = await repository.AddAsync(request.ToDocument(), cancellationToken);
                return Results.Created($"/api/series/{item.Id}", item);
            })
            .AddEndpointFilter<DataAnnotationsValidationFilter<CreateSeriesRequest>>();

        return endpoints;
    }
}
