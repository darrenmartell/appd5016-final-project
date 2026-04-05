using System.Text.Json.Serialization;

namespace SeriesCatalog.Frontend.Models.Series;

public sealed class SeriesRecord
{
    [JsonPropertyName("_id")]
    public string Id { get; set; } = string.Empty;

    [JsonPropertyName("title")]
    public string Title { get; set; } = string.Empty;

    [JsonPropertyName("plot_summary")]
    public string? PlotSummary { get; set; }

    [JsonPropertyName("runtime_minutes")]
    public int? RuntimeMinutes { get; set; }

    [JsonPropertyName("released_year")]
    public int? ReleasedYear { get; set; }

    [JsonPropertyName("cast")]
    public List<string> Cast { get; set; } = [];

    [JsonPropertyName("directors")]
    public List<string> Directors { get; set; } = [];

    [JsonPropertyName("genres")]
    public List<string> Genres { get; set; } = [];

    [JsonPropertyName("countries")]
    public List<string> Countries { get; set; } = [];

    [JsonPropertyName("languages")]
    public List<string> Languages { get; set; } = [];

    [JsonPropertyName("production_companies")]
    public List<string> ProductionCompanies { get; set; } = [];

    [JsonPropertyName("producers")]
    public List<string> Producers { get; set; } = [];

    [JsonPropertyName("ratings")]
    public SeriesRatings Ratings { get; set; } = new();

    [JsonPropertyName("episodes")]
    public List<SeriesEpisode> Episodes { get; set; } = [];
}

