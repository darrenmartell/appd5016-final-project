using System.Net.Http.Headers;
using System.Text.Json;
using SeriesCatalog.Frontend.Models.Users;
using SeriesCatalog.Frontend.Services.Auth;
using SeriesCatalog.Frontend.Services.Api;
using Microsoft.Extensions.Options;

namespace SeriesCatalog.Frontend.Services.Users;

public sealed class UsersService : IUsersService
{
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly ClientAuthState _clientAuthState;
    private readonly ApiOptions _apiOptions;

    public UsersService(IHttpClientFactory httpClientFactory, ClientAuthState clientAuthState, IOptions<ApiOptions> apiOptions)
    {
        _httpClientFactory = httpClientFactory;
        _clientAuthState = clientAuthState;
        _apiOptions = apiOptions.Value;
    }

    public async Task<IReadOnlyList<UserSummary>> GetUsersAsync(CancellationToken cancellationToken = default)
    {
        try
        {
            var client = CreateClient();
            using var response = await client.GetAsync("users", cancellationToken);

            if (!response.IsSuccessStatusCode)
            {
                throw new InvalidOperationException("An error occurred while loading users.");
            }

            await using var contentStream = await response.Content.ReadAsStreamAsync(cancellationToken);
            using var document = await JsonDocument.ParseAsync(contentStream, cancellationToken: cancellationToken);

            var items = new List<UserSummary>();
            foreach (var element in document.RootElement.EnumerateArray())
            {
                var id = TryGetString(element, "_id") ?? TryGetString(element, "id");
                if (string.IsNullOrWhiteSpace(id))
                {
                    continue;
                }

                items.Add(new UserSummary
                {
                    Id = id,
                    FirstName = TryGetString(element, "firstName") ?? string.Empty,
                    LastName = TryGetString(element, "lastName") ?? string.Empty,
                    Email = TryGetString(element, "email") ?? string.Empty
                });
            }

            return items;
        }
        catch (HttpRequestException)
        {
            throw new InvalidOperationException("An error occurred while loading users.");
        }
    }

    public async Task DeleteUserAsync(string userId, CancellationToken cancellationToken = default)
    {
        if (!_clientAuthState.IsAuthenticated || string.IsNullOrWhiteSpace(_clientAuthState.Token))
        {
            throw new InvalidOperationException("You must be logged in to delete a user.");
        }

        try
        {
            var client = CreateClient();
            using var message = new HttpRequestMessage(HttpMethod.Delete, $"users/{userId}");
            message.Headers.Authorization = new AuthenticationHeaderValue("Bearer", _clientAuthState.Token);

            using var response = await client.SendAsync(message, cancellationToken);
            if (!response.IsSuccessStatusCode)
            {
                throw new InvalidOperationException("An error occurred while deleting the user.");
            }
        }
        catch (HttpRequestException)
        {
            throw new InvalidOperationException("An error occurred while deleting the user.");
        }
    }

    private HttpClient CreateClient()
    {
        var client = _httpClientFactory.CreateClient("BackendApi");
        client.BaseAddress ??= new Uri(_apiOptions.BaseUrl);
        return client;
    }

    private static string? TryGetString(JsonElement element, string propertyName)
    {
        if (!element.TryGetProperty(propertyName, out var propertyValue))
        {
            return null;
        }

        return propertyValue.ValueKind switch
        {
            JsonValueKind.String => propertyValue.GetString(),
            JsonValueKind.Number => propertyValue.ToString(),
            _ => null
        };
    }
}

