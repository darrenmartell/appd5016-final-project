using Appd.Api.Contracts.Series;
using Appd.Infrastructure.MongoDb.Documents;

namespace Appd.Api.Mappers;

public static class SeriesMapper
{
    public static SeriesDocument ToDocument(this CreateSeriesRequest request)
    {
        var normalizedGenre = request.Genre.Trim();

        return new SeriesDocument
        {
            Title = request.Title,
            PlotSummary = string.Empty,
            RuntimeMinutes = 1,
            ReleasedYear = request.ReleaseYear,
            Genre = normalizedGenre,
            ReleaseYear = request.ReleaseYear,
            Genres = string.IsNullOrWhiteSpace(normalizedGenre) ? [] : [normalizedGenre],
            Ratings = new SeriesRatingsDocument
            {
                Imdb = 1,
                RottenTomatoes = 1,
                Metacritic = 1,
                UserAverage = 1
            }
        };
    }
}
