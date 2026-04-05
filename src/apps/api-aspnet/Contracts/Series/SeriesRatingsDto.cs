using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace SeriesCatalog.WebApi.Contracts.Series;

public sealed class SeriesRatingsDto
{
    [JsonPropertyName("imdb")]
    [Range(0.0000001, 10)]
    public double Imdb { get; init; }

    [JsonPropertyName("rotten_tomatoes")]
    [Range(1, 100)]
    public int RottenTomatoes { get; init; }

    [JsonPropertyName("metacritic")]
    [Range(1, 100)]
    public int Metacritic { get; init; }

    [JsonPropertyName("user_average")]
    [Range(0.0000001, 10)]
    public double UserAverage { get; init; }
}

