using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace Appd.Api.Contracts.Series;

public sealed class SeriesUpsertRequest : IValidatableObject
{
    [JsonPropertyName("title")]
    [Required]
    [StringLength(50, MinimumLength = 1)]
    public string Title { get; init; } = string.Empty;

    [JsonPropertyName("plot_summary")]
    [Required]
    [StringLength(500, MinimumLength = 1)]
    public string PlotSummary { get; init; } = string.Empty;

    [JsonPropertyName("runtime_minutes")]
    [Range(1, 999)]
    public int RuntimeMinutes { get; init; }

    [JsonPropertyName("released_year")]
    [Range(1, 9999)]
    public int ReleasedYear { get; init; }

    [JsonPropertyName("cast")]
    [Required]
    public List<string> Cast { get; init; } = [];

    [JsonPropertyName("directors")]
    [Required]
    public List<string> Directors { get; init; } = [];

    [JsonPropertyName("genres")]
    [Required]
    public List<string> Genres { get; init; } = [];

    [JsonPropertyName("countries")]
    [Required]
    public List<string> Countries { get; init; } = [];

    [JsonPropertyName("languages")]
    [Required]
    public List<string> Languages { get; init; } = [];

    [JsonPropertyName("producers")]
    [Required]
    public List<string> Producers { get; init; } = [];

    [JsonPropertyName("production_companies")]
    [Required]
    public List<string> ProductionCompanies { get; init; } = [];

    [JsonPropertyName("ratings")]
    [Required]
    public SeriesRatingsDto Ratings { get; init; } = new();

    [JsonPropertyName("episodes")]
    [Required]
    public List<SeriesEpisodeDto> Episodes { get; init; } = [];

    public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
    {
        foreach (var result in SeriesValidation.ValidateStringList(Cast, "cast"))
        {
            yield return result;
        }

        foreach (var result in SeriesValidation.ValidateStringList(Directors, "directors"))
        {
            yield return result;
        }

        foreach (var result in SeriesValidation.ValidateStringList(Genres, "genres"))
        {
            yield return result;
        }

        foreach (var result in SeriesValidation.ValidateStringList(Countries, "countries"))
        {
            yield return result;
        }

        foreach (var result in SeriesValidation.ValidateStringList(Languages, "languages"))
        {
            yield return result;
        }

        foreach (var result in SeriesValidation.ValidateStringList(Producers, "producers"))
        {
            yield return result;
        }

        foreach (var result in SeriesValidation.ValidateStringList(ProductionCompanies, "production_companies"))
        {
            yield return result;
        }

        foreach (var result in SeriesValidation.ValidateObject(Ratings, "ratings"))
        {
            yield return result;
        }

        if (Episodes is null)
        {
            yield return new ValidationResult("episodes is required.", ["episodes"]);
            yield break;
        }

        for (var i = 0; i < Episodes.Count; i++)
        {
            foreach (var result in SeriesValidation.ValidateObject(Episodes[i], $"episodes[{i}]") )
            {
                yield return result;
            }
        }
    }
}
