using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace Appd.Api.Contracts.Series;

public sealed class SeriesEpisodeDto
{
    [JsonPropertyName("episode_number")]
    [Range(1, int.MaxValue)]
    public int EpisodeNumber { get; init; }

    [JsonPropertyName("episode_title")]
    [Required]
    [StringLength(50, MinimumLength = 1)]
    public string EpisodeTitle { get; init; } = string.Empty;

    [JsonPropertyName("runtime_minutes")]
    [Range(1, int.MaxValue)]
    public int RuntimeMinutes { get; init; }
}
