using Appd.Api.Contracts.Series;
using Appd.Infrastructure.MongoDb.Documents;

namespace Appd.Api.Services.Series;

public interface ISeriesService
{
    Task<IReadOnlyList<SeriesDocument>> ListAsync(CancellationToken cancellationToken);

    Task<SeriesDocument?> FindByIdAsync(string id, CancellationToken cancellationToken);

    Task<SeriesDocument> CreateAsync(SeriesUpsertRequest request, CancellationToken cancellationToken);

    Task<SeriesDocument?> ReplaceAsync(string id, SeriesUpsertRequest request, CancellationToken cancellationToken);

    Task<SeriesDocument?> PatchAsync(string id, SeriesPatchRequest request, CancellationToken cancellationToken);

    Task<SeriesDocument?> DeleteAsync(string id, CancellationToken cancellationToken);
}
