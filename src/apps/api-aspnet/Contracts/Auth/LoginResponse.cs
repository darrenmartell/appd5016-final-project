using System.Text.Json.Serialization;
using SeriesCatalog.WebApi.Contracts.Users;

namespace SeriesCatalog.WebApi.Contracts.Auth;

public sealed class LoginResponse : UserResponse
{
    public string Message { get; init; } = string.Empty;

    [JsonPropertyName("access_token")]
    public string AccessToken { get; init; } = string.Empty;
}

