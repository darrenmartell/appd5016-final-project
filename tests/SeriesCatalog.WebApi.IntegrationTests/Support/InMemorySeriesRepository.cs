using System.Collections.Concurrent;
using SeriesCatalog.Infrastructure.MongoDb.Documents;
using SeriesCatalog.Infrastructure.MongoDb.Repositories;
using MongoDB.Bson;

namespace SeriesCatalog.WebApi.IntegrationTests.Support;

internal sealed class InMemorySeriesRepository : ISeriesRepository
{
    private readonly ConcurrentDictionary<string, SeriesDocument> _series = new(StringComparer.OrdinalIgnoreCase);

    public Task<IReadOnlyList<SeriesDocument>> ListAsync(CancellationToken cancellationToken)
    {
        IReadOnlyList<SeriesDocument> items = _series.Values
            .OrderBy(item => item.Title, StringComparer.OrdinalIgnoreCase)
            .ToList();
        return Task.FromResult(items);
    }

    public Task<SeriesDocument?> FindByIdAsync(string id, CancellationToken cancellationToken)
    {
        _series.TryGetValue(id, out var series);
        return Task.FromResult(series);
    }

    public Task<SeriesDocument> AddAsync(SeriesDocument series, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(series.Id))
        {
            series.Id = ObjectId.GenerateNewId().ToString();
        }

        _series[series.Id] = series;
        return Task.FromResult(series);
    }

    public Task<SeriesDocument?> ReplaceAsync(string id, SeriesDocument series, CancellationToken cancellationToken)
    {
        if (!_series.ContainsKey(id))
        {
            return Task.FromResult<SeriesDocument?>(null);
        }

        series.Id = id;
        _series[id] = series;
        return Task.FromResult<SeriesDocument?>(series);
    }

    public Task<SeriesDocument?> DeleteByIdAsync(string id, CancellationToken cancellationToken)
    {
        _series.TryRemove(id, out var deleted);
        return Task.FromResult(deleted);
    }
}


