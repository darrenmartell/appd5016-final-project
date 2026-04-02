using Appd.Api.Contracts.Series;
using Appd.Infrastructure.MongoDb.Documents;

namespace Appd.Api.Mappers;

public static class SeriesDomainMapper
{
    public static SeriesDocument ToDocument(this SeriesUpsertRequest request)
    {
        return new SeriesDocument
        {
            Title = request.Title,
            PlotSummary = request.PlotSummary,
            RuntimeMinutes = request.RuntimeMinutes,
            ReleasedYear = request.ReleasedYear,
            Cast = request.Cast.Select(value => value.Trim()).ToList(),
            Directors = request.Directors.Select(value => value.Trim()).ToList(),
            Genres = request.Genres.Select(value => value.Trim()).ToList(),
            Countries = request.Countries.Select(value => value.Trim()).ToList(),
            Languages = request.Languages.Select(value => value.Trim()).ToList(),
            Producers = request.Producers.Select(value => value.Trim()).ToList(),
            ProductionCompanies = request.ProductionCompanies.Select(value => value.Trim()).ToList(),
            Ratings = new SeriesRatingsDocument
            {
                Imdb = request.Ratings.Imdb,
                RottenTomatoes = request.Ratings.RottenTomatoes,
                Metacritic = request.Ratings.Metacritic,
                UserAverage = request.Ratings.UserAverage
            },
            Episodes = request.Episodes.Select(episode => new SeriesEpisodeDocument
            {
                EpisodeNumber = episode.EpisodeNumber,
                EpisodeTitle = episode.EpisodeTitle.Trim(),
                RuntimeMinutes = episode.RuntimeMinutes
            }).ToList()
        };
    }

    public static void ApplyReplace(this SeriesDocument target, SeriesUpsertRequest request)
    {
        target.Title = request.Title;
        target.PlotSummary = request.PlotSummary;
        target.RuntimeMinutes = request.RuntimeMinutes;
        target.ReleasedYear = request.ReleasedYear;
        target.Cast = request.Cast.Select(value => value.Trim()).ToList();
        target.Directors = request.Directors.Select(value => value.Trim()).ToList();
        target.Genres = request.Genres.Select(value => value.Trim()).ToList();
        target.Countries = request.Countries.Select(value => value.Trim()).ToList();
        target.Languages = request.Languages.Select(value => value.Trim()).ToList();
        target.Producers = request.Producers.Select(value => value.Trim()).ToList();
        target.ProductionCompanies = request.ProductionCompanies.Select(value => value.Trim()).ToList();
        target.Ratings = new SeriesRatingsDocument
        {
            Imdb = request.Ratings.Imdb,
            RottenTomatoes = request.Ratings.RottenTomatoes,
            Metacritic = request.Ratings.Metacritic,
            UserAverage = request.Ratings.UserAverage
        };
        target.Episodes = request.Episodes.Select(episode => new SeriesEpisodeDocument
        {
            EpisodeNumber = episode.EpisodeNumber,
            EpisodeTitle = episode.EpisodeTitle.Trim(),
            RuntimeMinutes = episode.RuntimeMinutes
        }).ToList();
    }

    public static void ApplyPatch(this SeriesDocument target, SeriesPatchRequest patch)
    {
        if (patch.Title is not null)
        {
            target.Title = patch.Title;
        }

        if (patch.PlotSummary is not null)
        {
            target.PlotSummary = patch.PlotSummary;
        }

        if (patch.RuntimeMinutes.HasValue)
        {
            target.RuntimeMinutes = patch.RuntimeMinutes.Value;
        }

        if (patch.ReleasedYear.HasValue)
        {
            target.ReleasedYear = patch.ReleasedYear.Value;
        }

        if (patch.Cast is not null)
        {
            target.Cast = patch.Cast.Select(value => value.Trim()).ToList();
        }

        if (patch.Directors is not null)
        {
            target.Directors = patch.Directors.Select(value => value.Trim()).ToList();
        }

        if (patch.Genres is not null)
        {
            target.Genres = patch.Genres.Select(value => value.Trim()).ToList();
        }

        if (patch.Countries is not null)
        {
            target.Countries = patch.Countries.Select(value => value.Trim()).ToList();
        }

        if (patch.Languages is not null)
        {
            target.Languages = patch.Languages.Select(value => value.Trim()).ToList();
        }

        if (patch.Producers is not null)
        {
            target.Producers = patch.Producers.Select(value => value.Trim()).ToList();
        }

        if (patch.ProductionCompanies is not null)
        {
            target.ProductionCompanies = patch.ProductionCompanies.Select(value => value.Trim()).ToList();
        }

        if (patch.Ratings is not null)
        {
            target.Ratings = new SeriesRatingsDocument
            {
                Imdb = patch.Ratings.Imdb,
                RottenTomatoes = patch.Ratings.RottenTomatoes,
                Metacritic = patch.Ratings.Metacritic,
                UserAverage = patch.Ratings.UserAverage
            };
        }

        if (patch.Episodes is not null)
        {
            target.Episodes = patch.Episodes.Select(episode => new SeriesEpisodeDocument
            {
                EpisodeNumber = episode.EpisodeNumber,
                EpisodeTitle = episode.EpisodeTitle.Trim(),
                RuntimeMinutes = episode.RuntimeMinutes
            }).ToList();
        }
    }
}
