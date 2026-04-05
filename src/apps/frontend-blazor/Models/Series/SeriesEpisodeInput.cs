namespace SeriesCatalog.Frontend.Models.Series;

public sealed class SeriesEpisodeInput
{
    public int EpisodeNumber { get; set; }

    public string EpisodeTitle { get; set; } = string.Empty;

    public string RuntimeMinutes { get; set; } = string.Empty;
}

