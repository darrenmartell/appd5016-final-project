using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace SeriesCatalog.WebApi.Contracts.Series;

public sealed class SeriesPatchRequest : IValidatableObject
{
    [JsonPropertyName("title")]
    [StringLength(50, MinimumLength = 1)]
    public string? Title { get; init; }

    [JsonPropertyName("plot_summary")]
    [StringLength(500, MinimumLength = 1)]
    public string? PlotSummary { get; init; }

    [JsonPropertyName("runtime_minutes")]
    [Range(1, 999)]
    public int? RuntimeMinutes { get; init; }

    [JsonPropertyName("released_year")]
    [Range(1, 9999)]
    public int? ReleasedYear { get; init; }

    [JsonPropertyName("cast")]
    public List<string>? Cast { get; init; }

    [JsonPropertyName("directors")]
    public List<string>? Directors { get; init; }

    [JsonPropertyName("genres")]
    public List<string>? Genres { get; init; }

    [JsonPropertyName("countries")]
    public List<string>? Countries { get; init; }

    [JsonPropertyName("languages")]
    public List<string>? Languages { get; init; }

    [JsonPropertyName("producers")]
    public List<string>? Producers { get; init; }

    [JsonPropertyName("production_companies")]
    public List<string>? ProductionCompanies { get; init; }

    [JsonPropertyName("ratings")]
    public SeriesRatingsDto? Ratings { get; init; }

    [JsonPropertyName("episodes")]
    public List<SeriesEpisodeDto>? Episodes { get; init; }

    public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
    {
        foreach (var result in SeriesValidation.ValidateOptionalStringList(Cast, "cast"))
        {
            yield return result;
        }

        foreach (var result in SeriesValidation.ValidateOptionalStringList(Directors, "directors"))
        {
            yield return result;
        }

        foreach (var result in SeriesValidation.ValidateOptionalStringList(Genres, "genres"))
        {
            yield return result;
        }

        foreach (var result in SeriesValidation.ValidateOptionalStringList(Countries, "countries"))
        {
            yield return result;
        }

        foreach (var result in SeriesValidation.ValidateOptionalStringList(Languages, "languages"))
        {
            yield return result;
        }

        foreach (var result in SeriesValidation.ValidateOptionalStringList(Producers, "producers"))
        {
            yield return result;
        }

        foreach (var result in SeriesValidation.ValidateOptionalStringList(ProductionCompanies, "production_companies"))
        {
            yield return result;
        }

        if (Ratings is not null)
        {
            foreach (var result in SeriesValidation.ValidateObject(Ratings, "ratings"))
            {
                yield return result;
            }
        }

        if (Episodes is null)
        {
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

