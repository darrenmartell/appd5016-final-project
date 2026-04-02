namespace Appd.Infrastructure.MongoDb.Documents;

public sealed class SeriesDocument
{
    public string Id { get; set; } = Guid.NewGuid().ToString("N");

    public string Title { get; set; } = string.Empty;

    public string Genre { get; set; } = string.Empty;

    public int ReleaseYear { get; set; }
}
