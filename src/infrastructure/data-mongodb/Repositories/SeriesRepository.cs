using SeriesCatalog.Infrastructure.MongoDb.Documents;
using MongoDB.Driver;

namespace SeriesCatalog.Infrastructure.MongoDb.Repositories;

public sealed class SeriesRepository : ISeriesRepository
{
    private readonly IMongoCollection<SeriesDocument> _series;

    public SeriesRepository(IMongoDatabase database)
    {
        _series = database.GetCollection<SeriesDocument>("series");
    }

    public async Task<IReadOnlyList<SeriesDocument>> ListAsync(CancellationToken cancellationToken)
    {
        return await _series.Find(FilterDefinition<SeriesDocument>.Empty)
            .SortBy(item => item.Title)
            .ToListAsync(cancellationToken);
    }

    public async Task<SeriesDocument?> FindByIdAsync(string id, CancellationToken cancellationToken)
    {
        return await _series.Find(item => item.Id == id)
            .FirstOrDefaultAsync(cancellationToken);
    }

    public async Task<SeriesDocument> AddAsync(SeriesDocument series, CancellationToken cancellationToken)
    {
        await _series.InsertOneAsync(series, cancellationToken: cancellationToken);
        return series;
    }

    public async Task<SeriesDocument?> ReplaceAsync(string id, SeriesDocument series, CancellationToken cancellationToken)
    {
        series.Id = id;
        var options = new FindOneAndReplaceOptions<SeriesDocument>
        {
            ReturnDocument = ReturnDocument.After
        };

        return await _series.FindOneAndReplaceAsync(item => item.Id == id, series, options, cancellationToken);
    }

    public async Task<SeriesDocument?> DeleteByIdAsync(string id, CancellationToken cancellationToken)
    {
        return await _series.FindOneAndDeleteAsync(item => item.Id == id, cancellationToken: cancellationToken);
    }
}

