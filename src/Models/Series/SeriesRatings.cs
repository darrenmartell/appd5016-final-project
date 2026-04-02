using System.Text.Json.Serialization;

namespace BlazorMigration.Models.Series;

public sealed class SeriesRatings
{
    [JsonPropertyName("imdb")]
    public double? Imdb { get; set; }

    [JsonPropertyName("rotten_tomatoes")]
    public double? RottenTomatoes { get; set; }

    [JsonPropertyName("metacritic")]
    public double? Metacritic { get; set; }

    [JsonPropertyName("user_average")]
    public double? UserAverage { get; set; }
}