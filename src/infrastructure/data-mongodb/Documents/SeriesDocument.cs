using System.Text.Json.Serialization;
using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace SeriesCatalog.Infrastructure.MongoDb.Documents;

[BsonIgnoreExtraElements]
public sealed class SeriesDocument
{
    [BsonId]
    [BsonRepresentation(BsonType.ObjectId)]
    [JsonPropertyName("_id")]
    public string Id { get; set; } = ObjectId.GenerateNewId().ToString();

    [BsonElement("title")]
    [JsonPropertyName("title")]
    public string Title { get; set; } = string.Empty;

    [BsonElement("plot_summary")]
    [JsonPropertyName("plot_summary")]
    public string PlotSummary { get; set; } = string.Empty;

    [BsonElement("runtime_minutes")]
    [JsonPropertyName("runtime_minutes")]
    public int RuntimeMinutes { get; set; }

    [BsonElement("released_year")]
    [JsonPropertyName("released_year")]
    public int ReleasedYear { get; set; }

    [BsonElement("cast")]
    [JsonPropertyName("cast")]
    public List<string> Cast { get; set; } = [];

    [BsonElement("directors")]
    [JsonPropertyName("directors")]
    public List<string> Directors { get; set; } = [];

    [BsonElement("genres")]
    [JsonPropertyName("genres")]
    public List<string> Genres { get; set; } = [];

    [BsonElement("countries")]
    [JsonPropertyName("countries")]
    public List<string> Countries { get; set; } = [];

    [BsonElement("languages")]
    [JsonPropertyName("languages")]
    public List<string> Languages { get; set; } = [];

    [BsonElement("producers")]
    [JsonPropertyName("producers")]
    public List<string> Producers { get; set; } = [];

    [BsonElement("production_companies")]
    [JsonPropertyName("production_companies")]
    public List<string> ProductionCompanies { get; set; } = [];

    [BsonElement("ratings")]
    [JsonPropertyName("ratings")]
    public SeriesRatingsDocument Ratings { get; set; } = new();

    [BsonElement("episodes")]
    [JsonPropertyName("episodes")]
    public List<SeriesEpisodeDocument> Episodes { get; set; } = [];

    // Legacy field retained for /api endpoint compatibility during migration.
    [JsonIgnore]
    public string Genre { get; set; } = string.Empty;

    // Legacy field retained for /api endpoint compatibility during migration.
    [JsonIgnore]
    public int ReleaseYear { get; set; }
}

[BsonIgnoreExtraElements]
public sealed class SeriesRatingsDocument
{
    [BsonElement("imdb")]
    [JsonPropertyName("imdb")]
    public double? Imdb { get; set; }

    [BsonElement("rotten_tomatoes")]
    [JsonPropertyName("rotten_tomatoes")]
    public int? RottenTomatoes { get; set; }

    [BsonElement("metacritic")]
    [JsonPropertyName("metacritic")]
    public int? Metacritic { get; set; }

    [BsonElement("user_average")]
    [JsonPropertyName("user_average")]
    public double? UserAverage { get; set; }
}

[BsonIgnoreExtraElements]
public sealed class SeriesEpisodeDocument
{
    [BsonElement("episode_number")]
    [JsonPropertyName("episode_number")]
    public int EpisodeNumber { get; set; }

    [BsonElement("episode_title")]
    [JsonPropertyName("episode_title")]
    public string EpisodeTitle { get; set; } = string.Empty;

    [BsonElement("runtime_minutes")]
    [JsonPropertyName("runtime_minutes")]
    public int RuntimeMinutes { get; set; }
}

