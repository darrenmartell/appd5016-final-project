using System.Text.RegularExpressions;
using Appd.Api.Common.Validation;
using Appd.Api.Contracts.Series;
using Appd.Api.Services.Series;

namespace Appd.Api.Endpoints;

public static partial class SeriesDomainEndpoints
{
    [GeneratedRegex("^[a-fA-F0-9]{24}$", RegexOptions.Compiled)]
    private static partial Regex MongoObjectIdRegex();

    public static IEndpointRouteBuilder MapSeriesDomainEndpoints(this IEndpointRouteBuilder endpoints)
    {
        endpoints.MapGet("/series", async (ISeriesService seriesService, CancellationToken cancellationToken) =>
        {
            var items = await seriesService.ListAsync(cancellationToken);
            return Results.Ok(items);
        });

        endpoints.MapGet("/series/{id}", async Task<IResult> (string id, ISeriesService seriesService, CancellationToken cancellationToken) =>
        {
            if (!IsValidId(id))
            {
                return Results.BadRequest(new { message = "Invalid id format." });
            }

            var item = await seriesService.FindByIdAsync(id, cancellationToken);
            if (item is null)
            {
                return Results.NotFound(new { message = $"Resource with id {id} not found" });
            }

            return Results.Ok(item);
        });

        endpoints.MapPost("/series", async (SeriesUpsertRequest request, ISeriesService seriesService, CancellationToken cancellationToken) =>
            {
                var created = await seriesService.CreateAsync(request, cancellationToken);
                return Results.Created($"/series/{created.Id}", created);
            })
            .AddEndpointFilter<DataAnnotationsValidationFilter<SeriesUpsertRequest>>()
            .RequireAuthorization();

        endpoints.MapPut("/series/{id}", async Task<IResult> (string id, SeriesUpsertRequest request, ISeriesService seriesService, CancellationToken cancellationToken) =>
            {
                if (!IsValidId(id))
                {
                    return Results.BadRequest(new { message = "Invalid id format." });
                }

                var updated = await seriesService.ReplaceAsync(id, request, cancellationToken);
                if (updated is null)
                {
                    return Results.NotFound(new { message = $"Resource with id {id} not found" });
                }

                return Results.Ok(updated);
            })
            .AddEndpointFilter<DataAnnotationsValidationFilter<SeriesUpsertRequest>>()
            .RequireAuthorization();

        endpoints.MapPatch("/series/{id}", async Task<IResult> (string id, SeriesPatchRequest request, ISeriesService seriesService, CancellationToken cancellationToken) =>
            {
                if (!IsValidId(id))
                {
                    return Results.BadRequest(new { message = "Invalid id format." });
                }

                var patched = await seriesService.PatchAsync(id, request, cancellationToken);
                if (patched is null)
                {
                    return Results.NotFound(new { message = $"Resource with id {id} not found" });
                }

                return Results.Ok(patched);
            })
            .AddEndpointFilter<DataAnnotationsValidationFilter<SeriesPatchRequest>>()
            .RequireAuthorization();

        endpoints.MapDelete("/series/{id}", async Task<IResult> (string id, ISeriesService seriesService, CancellationToken cancellationToken) =>
            {
                if (!IsValidId(id))
                {
                    return Results.BadRequest(new { message = "Invalid id format." });
                }

                var deleted = await seriesService.DeleteAsync(id, cancellationToken);
                if (deleted is null)
                {
                    return Results.NotFound(new { message = $"Resource with id {id} not found" });
                }

                return Results.Ok(deleted);
            })
            .RequireAuthorization();

        return endpoints;
    }

    private static bool IsValidId(string id)
    {
        return !string.IsNullOrWhiteSpace(id) && MongoObjectIdRegex().IsMatch(id);
    }
}
