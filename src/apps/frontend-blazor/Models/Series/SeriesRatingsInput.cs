namespace BlazorMigration.Models.Series;

public sealed class SeriesRatingsInput
{
    public string Imdb { get; set; } = string.Empty;

    public string RottenTomatoes { get; set; } = string.Empty;

    public string Metacritic { get; set; } = string.Empty;

    public string UserAverage { get; set; } = string.Empty;
}