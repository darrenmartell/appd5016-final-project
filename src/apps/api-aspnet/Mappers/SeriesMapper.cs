using Appd.Api.Contracts.Series;
using Appd.Infrastructure.MongoDb.Documents;

namespace Appd.Api.Mappers;

public static class SeriesMapper
{
    public static SeriesDocument ToDocument(this CreateSeriesRequest request)
    {
        return new SeriesDocument
        {
            Title = request.Title,
            Genre = request.Genre,
            ReleaseYear = request.ReleaseYear
        };
    }
}
