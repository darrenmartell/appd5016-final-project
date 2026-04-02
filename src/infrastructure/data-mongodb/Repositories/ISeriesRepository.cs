using Appd.Infrastructure.MongoDb.Documents;

namespace Appd.Infrastructure.MongoDb.Repositories;

public interface ISeriesRepository
{
    Task<IReadOnlyList<SeriesDocument>> ListAsync(CancellationToken cancellationToken);

    Task<SeriesDocument> AddAsync(SeriesDocument series, CancellationToken cancellationToken);
}
