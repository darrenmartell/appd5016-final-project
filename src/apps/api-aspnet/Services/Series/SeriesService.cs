using SeriesCatalog.WebApi.Contracts.Series;
using SeriesCatalog.WebApi.Mappers;
using SeriesCatalog.Infrastructure.MongoDb.Documents;
using SeriesCatalog.Infrastructure.MongoDb.Repositories;

namespace SeriesCatalog.WebApi.Services.Series;

public sealed class SeriesService : ISeriesService
{
    private readonly ISeriesRepository _seriesRepository;

    public SeriesService(ISeriesRepository seriesRepository)
    {
        _seriesRepository = seriesRepository;
    }

    public Task<IReadOnlyList<SeriesDocument>> ListAsync(CancellationToken cancellationToken)
    {
        return _seriesRepository.ListAsync(cancellationToken);
    }

    public Task<SeriesDocument?> FindByIdAsync(string id, CancellationToken cancellationToken)
    {
        return _seriesRepository.FindByIdAsync(id, cancellationToken);
    }

    public Task<SeriesDocument> CreateAsync(SeriesUpsertRequest request, CancellationToken cancellationToken)
    {
        return _seriesRepository.AddAsync(request.ToDocument(), cancellationToken);
    }

    public async Task<SeriesDocument?> ReplaceAsync(string id, SeriesUpsertRequest request, CancellationToken cancellationToken)
    {
        var existing = await _seriesRepository.FindByIdAsync(id, cancellationToken);
        if (existing is null)
        {
            return null;
        }

        existing.ApplyReplace(request);
        return await _seriesRepository.ReplaceAsync(id, existing, cancellationToken);
    }

    public async Task<SeriesDocument?> PatchAsync(string id, SeriesPatchRequest request, CancellationToken cancellationToken)
    {
        var existing = await _seriesRepository.FindByIdAsync(id, cancellationToken);
        if (existing is null)
        {
            return null;
        }

        existing.ApplyPatch(request);
        return await _seriesRepository.ReplaceAsync(id, existing, cancellationToken);
    }

    public Task<SeriesDocument?> DeleteAsync(string id, CancellationToken cancellationToken)
    {
        return _seriesRepository.DeleteByIdAsync(id, cancellationToken);
    }
}


