using Appd.Infrastructure.MongoDb.Documents;
using Microsoft.EntityFrameworkCore;

namespace Appd.Infrastructure.MongoDb.Repositories;

public sealed class SeriesRepository : ISeriesRepository
{
    private readonly AppMongoDbContext _dbContext;

    public SeriesRepository(AppMongoDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<IReadOnlyList<SeriesDocument>> ListAsync(CancellationToken cancellationToken)
    {
        return await _dbContext.Series
            .OrderBy(item => item.Title)
            .ToListAsync(cancellationToken);
    }

    public async Task<SeriesDocument> AddAsync(SeriesDocument series, CancellationToken cancellationToken)
    {
        _dbContext.Series.Add(series);
        await _dbContext.SaveChangesAsync(cancellationToken);
        return series;
    }
}
