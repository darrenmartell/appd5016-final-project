using System.Text.Json.Serialization;

namespace SeriesCatalog.Frontend.Models.Series;

public sealed class SeriesEpisode
{
    [JsonPropertyName("episode_number")]
    public int EpisodeNumber { get; set; }

    [JsonPropertyName("episode_title")]
    public string EpisodeTitle { get; set; } = string.Empty;

    [JsonPropertyName("runtime_minutes")]
    public int RuntimeMinutes { get; set; }
}

