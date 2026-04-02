using System.ComponentModel.DataAnnotations;

namespace BlazorMigration.Models.Series;

public sealed class SeriesFormInput : IValidatableObject
{
    [Required(ErrorMessage = "Title is required.")]
    public string Title { get; set; } = string.Empty;

    public string PlotSummary { get; set; } = string.Empty;

    public string RuntimeMinutes { get; set; } = string.Empty;

    public string ReleasedYear { get; set; } = string.Empty;

    public List<SeriesTagValueInput> Cast { get; set; } = [];

    public List<SeriesTagValueInput> Directors { get; set; } = [];

    public List<SeriesTagValueInput> Genres { get; set; } = [];

    public List<SeriesTagValueInput> Countries { get; set; } = [];

    public List<SeriesTagValueInput> Languages { get; set; } = [];

    public List<SeriesTagValueInput> Producers { get; set; } = [];

    public List<SeriesTagValueInput> ProductionCompanies { get; set; } = [];

    public SeriesRatingsInput Ratings { get; set; } = new();

    public List<SeriesEpisodeInput> Episodes { get; set; } = [];

    public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
    {
        if (!TryParsePositiveInteger(RuntimeMinutes, out _))
        {
            yield return new ValidationResult("Runtime (minutes) is required and must be a positive whole number.", [nameof(RuntimeMinutes)]);
        }

        if (!TryParsePositiveInteger(ReleasedYear, out _))
        {
            yield return new ValidationResult("Released year is required and must be a positive whole number.", [nameof(ReleasedYear)]);
        }

        if (!TryParsePositiveDouble(Ratings.Imdb, 10, out _))
        {
            yield return new ValidationResult("IMDb rating is required and must be between 0 and 10.", [$"{nameof(Ratings)}.{nameof(Ratings.Imdb)}"]);
        }

        if (!TryParsePositiveInteger(Ratings.RottenTomatoes, out var rottenTomatoes) || rottenTomatoes > 100)
        {
            yield return new ValidationResult("Rotten Tomatoes rating is required and must be a whole number between 1 and 100.", [$"{nameof(Ratings)}.{nameof(Ratings.RottenTomatoes)}"]);
        }

        if (!TryParsePositiveInteger(Ratings.Metacritic, out var metacritic) || metacritic > 100)
        {
            yield return new ValidationResult("Metacritic rating is required and must be a whole number between 1 and 100.", [$"{nameof(Ratings)}.{nameof(Ratings.Metacritic)}"]);
        }

        if (!TryParsePositiveDouble(Ratings.UserAverage, 10, out _))
        {
            yield return new ValidationResult("User average rating is required and must be between 0 and 10.", [$"{nameof(Ratings)}.{nameof(Ratings.UserAverage)}"]);
        }
    }

    private static bool TryParsePositiveInteger(string? value, out int parsedValue)
    {
        return int.TryParse(value, out parsedValue) && parsedValue > 0;
    }

    private static bool TryParsePositiveDouble(string? value, double maxValue, out double parsedValue)
    {
        return double.TryParse(value, out parsedValue) && parsedValue > 0 && parsedValue <= maxValue;
    }
}