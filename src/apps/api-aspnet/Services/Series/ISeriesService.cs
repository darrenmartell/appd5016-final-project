using SeriesCatalog.WebApi.Contracts.Series;
using SeriesCatalog.Infrastructure.MongoDb.Documents;

namespace SeriesCatalog.WebApi.Services.Series;

public interface ISeriesService
{
    Task<IReadOnlyList<SeriesDocument>> ListAsync(CancellationToken cancellationToken);

    Task<SeriesDocument?> FindByIdAsync(string id, CancellationToken cancellationToken);

    Task<SeriesDocument> CreateAsync(SeriesUpsertRequest request, CancellationToken cancellationToken);

    Task<SeriesDocument?> ReplaceAsync(string id, SeriesUpsertRequest request, CancellationToken cancellationToken);

    Task<SeriesDocument?> PatchAsync(string id, SeriesPatchRequest request, CancellationToken cancellationToken);

    Task<SeriesDocument?> DeleteAsync(string id, CancellationToken cancellationToken);
}


