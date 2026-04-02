using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace SeriesCatalog.Infrastructure.MongoDb.Documents;

[BsonIgnoreExtraElements]
public sealed class UserDocument
{
    [BsonId]
    [BsonRepresentation(BsonType.ObjectId)]
    public string Id { get; set; } = ObjectId.GenerateNewId().ToString();

    [BsonElement("email")]
    public string Email { get; set; } = string.Empty;

    [BsonElement("firstName")]
    public string FirstName { get; set; } = string.Empty;

    [BsonElement("lastName")]
    public string LastName { get; set; } = string.Empty;

    [BsonElement("password")]
    public string PasswordHash { get; set; } = string.Empty;
}

