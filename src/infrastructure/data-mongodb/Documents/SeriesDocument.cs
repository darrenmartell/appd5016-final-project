using System.Text.Json.Serialization;
using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace Appd.Infrastructure.MongoDb.Documents;

public sealed class SeriesDocument
{
    [BsonId]
    [BsonRepresentation(BsonType.ObjectId)]
    [JsonPropertyName("_id")]
    public string Id { get; set; } = ObjectId.GenerateNewId().ToString();

    [JsonPropertyName("title")]
    public string Title { get; set; } = string.Empty;

    [JsonPropertyName("plot_summary")]
    public string PlotSummary { get; set; } = string.Empty;

    [JsonPropertyName("runtime_minutes")]
    public int RuntimeMinutes { get; set; }

    [JsonPropertyName("released_year")]
    public int ReleasedYear { get; set; }

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

    [JsonPropertyName("producers")]
    public List<string> Producers { get; set; } = [];

    [JsonPropertyName("production_companies")]
    public List<string> ProductionCompanies { get; set; } = [];

    [JsonPropertyName("ratings")]
    public SeriesRatingsDocument Ratings { get; set; } = new();

    [JsonPropertyName("episodes")]
    public List<SeriesEpisodeDocument> Episodes { get; set; } = [];

    // Legacy field retained for /api endpoint compatibility during migration.
    [JsonIgnore]
    public string Genre { get; set; } = string.Empty;

    // Legacy field retained for /api endpoint compatibility during migration.
    [JsonIgnore]
    public int ReleaseYear { get; set; }
}

public sealed class SeriesRatingsDocument
{
    [JsonPropertyName("imdb")]
    public double Imdb { get; set; }

    [JsonPropertyName("rotten_tomatoes")]
    public int RottenTomatoes { get; set; }

    [JsonPropertyName("metacritic")]
    public int Metacritic { get; set; }

    [JsonPropertyName("user_average")]
    public double UserAverage { get; set; }
}

public sealed class SeriesEpisodeDocument
{
    [JsonPropertyName("episode_number")]
    public int EpisodeNumber { get; set; }

    [JsonPropertyName("episode_title")]
    public string EpisodeTitle { get; set; } = string.Empty;

    [JsonPropertyName("runtime_minutes")]
    public int RuntimeMinutes { get; set; }
}
