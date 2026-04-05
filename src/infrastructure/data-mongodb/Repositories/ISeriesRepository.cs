using SeriesCatalog.Infrastructure.MongoDb.Documents;

namespace SeriesCatalog.Infrastructure.MongoDb.Repositories;

public interface ISeriesRepository
{
    Task<IReadOnlyList<SeriesDocument>> ListAsync(CancellationToken cancellationToken);

    Task<SeriesDocument?> FindByIdAsync(string id, CancellationToken cancellationToken);

    Task<SeriesDocument> AddAsync(SeriesDocument series, CancellationToken cancellationToken);

    Task<SeriesDocument?> ReplaceAsync(string id, SeriesDocument series, CancellationToken cancellationToken);

    Task<SeriesDocument?> DeleteByIdAsync(string id, CancellationToken cancellationToken);
}

