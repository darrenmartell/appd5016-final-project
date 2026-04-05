using System.Text.Json.Serialization;

namespace SeriesCatalog.WebApi.Contracts.Users;

public class UserResponse
{
    [JsonPropertyName("_id")]
    public string Id { get; init; } = string.Empty;

    public string Email { get; init; } = string.Empty;

    public string FirstName { get; init; } = string.Empty;

    public string LastName { get; init; } = string.Empty;
}

