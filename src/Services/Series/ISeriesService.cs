using BlazorMigration.Models.Series;

namespace BlazorMigration.Services.Series;

public interface ISeriesService
{
    Task<IReadOnlyList<SeriesRecord>> GetSeriesAsync(CancellationToken cancellationToken = default);

    Task<SeriesRecord> CreateSeriesAsync(SeriesUpsertRequest request, CancellationToken cancellationToken = default);

    Task<SeriesRecord> UpdateSeriesAsync(string id, SeriesUpsertRequest request, CancellationToken cancellationToken = default);

    Task<SeriesRecord> DeleteSeriesAsync(string id, CancellationToken cancellationToken = default);
}