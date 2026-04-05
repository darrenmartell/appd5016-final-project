namespace SeriesCatalog.Frontend.Models.Series;

public static class SeriesFormMapper
{
    public static SeriesFormInput ToInput(SeriesRecord record)
    {
        return new SeriesFormInput
        {
            Title = record.Title,
            PlotSummary = record.PlotSummary ?? string.Empty,
            RuntimeMinutes = record.RuntimeMinutes?.ToString() ?? string.Empty,
            ReleasedYear = record.ReleasedYear?.ToString() ?? string.Empty,
            Cast = MapTagValues(record.Cast),
            Directors = MapTagValues(record.Directors),
            Genres = MapTagValues(record.Genres),
            Countries = MapTagValues(record.Countries),
            Languages = MapTagValues(record.Languages),
            Producers = MapTagValues(record.Producers),
            ProductionCompanies = MapTagValues(record.ProductionCompanies),
            Ratings = new SeriesRatingsInput
            {
                Imdb = record.Ratings.Imdb?.ToString() ?? string.Empty,
                RottenTomatoes = record.Ratings.RottenTomatoes?.ToString() ?? string.Empty,
                Metacritic = record.Ratings.Metacritic?.ToString() ?? string.Empty,
                UserAverage = record.Ratings.UserAverage?.ToString() ?? string.Empty
            },
            Episodes = record.Episodes
                .OrderBy(episode => episode.EpisodeNumber)
                .Select(episode => new SeriesEpisodeInput
                {
                    EpisodeNumber = episode.EpisodeNumber,
                    EpisodeTitle = episode.EpisodeTitle,
                    RuntimeMinutes = episode.RuntimeMinutes.ToString()
                })
                .ToList()
        };
    }

    public static SeriesUpsertRequest ToRequest(SeriesFormInput input)
    {
        return new SeriesUpsertRequest
        {
            Title = input.Title,
            PlotSummary = input.PlotSummary,
            RuntimeMinutes = ParseRequiredPositiveInteger(input.RuntimeMinutes, nameof(input.RuntimeMinutes)),
            ReleasedYear = ParseRequiredPositiveInteger(input.ReleasedYear, nameof(input.ReleasedYear)),
            Cast = Flatten(input.Cast),
            Directors = Flatten(input.Directors),
            Genres = Flatten(input.Genres),
            Countries = Flatten(input.Countries),
            Languages = Flatten(input.Languages),
            Producers = Flatten(input.Producers),
            ProductionCompanies = Flatten(input.ProductionCompanies),
            Ratings = new SeriesRatings
            {
                Imdb = ParseRequiredPositiveDouble(input.Ratings.Imdb, nameof(input.Ratings.Imdb)),
                RottenTomatoes = ParseRequiredPositiveDouble(input.Ratings.RottenTomatoes, nameof(input.Ratings.RottenTomatoes)),
                Metacritic = ParseRequiredPositiveDouble(input.Ratings.Metacritic, nameof(input.Ratings.Metacritic)),
                UserAverage = ParseRequiredPositiveDouble(input.Ratings.UserAverage, nameof(input.Ratings.UserAverage))
            },
            Episodes = input.Episodes
                .Select((episode, index) => new SeriesEpisode
                {
                    EpisodeNumber = index + 1,
                    EpisodeTitle = episode.EpisodeTitle,
                    RuntimeMinutes = ParseNumberOrZero(episode.RuntimeMinutes)
                })
                .ToList()
        };
    }

    private static List<SeriesTagValueInput> MapTagValues(IEnumerable<string>? values)
    {
        return values?
            .Where(value => !string.IsNullOrWhiteSpace(value))
            .Select(value => new SeriesTagValueInput { Value = value })
            .ToList() ?? [];
    }

    private static List<string> Flatten(IEnumerable<SeriesTagValueInput>? values)
    {
        return values?
            .Select(value => value.Value.Trim())
            .Where(value => !string.IsNullOrWhiteSpace(value))
            .ToList() ?? [];
    }

    private static int ParseNumberOrZero(string? value)
    {
        return int.TryParse(value, out var parsedValue) ? parsedValue : 0;
    }

    private static int ParseRequiredPositiveInteger(string? value, string fieldName)
    {
        if (!int.TryParse(value, out var parsedValue) || parsedValue <= 0)
        {
            throw new InvalidOperationException($"{fieldName} must be a positive whole number.");
        }

        return parsedValue;
    }

    private static double ParseRequiredPositiveDouble(string? value, string fieldName)
    {
        if (!double.TryParse(value, out var parsedValue) || parsedValue <= 0)
        {
            throw new InvalidOperationException($"{fieldName} must be a positive number.");
        }

        return parsedValue;
    }
}

