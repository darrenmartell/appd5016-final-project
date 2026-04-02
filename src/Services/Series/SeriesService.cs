using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using BlazorMigration.Models.Series;
using BlazorMigration.Services.Api;
using BlazorMigration.Services.Auth;
using Microsoft.Extensions.Options;

namespace BlazorMigration.Services.Series;

public sealed class SeriesService : ISeriesService
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

    private readonly IHttpClientFactory _httpClientFactory;
    private readonly ClientAuthState _clientAuthState;
    private readonly ApiOptions _apiOptions;

    public SeriesService(IHttpClientFactory httpClientFactory, ClientAuthState clientAuthState, IOptions<ApiOptions> apiOptions)
    {
        _httpClientFactory = httpClientFactory;
        _clientAuthState = clientAuthState;
        _apiOptions = apiOptions.Value;
    }

    public async Task<IReadOnlyList<SeriesRecord>> GetSeriesAsync(CancellationToken cancellationToken = default)
    {
        try
        {
            var client = CreateClient();
            var series = await client.GetFromJsonAsync<List<SeriesRecord>>("series", JsonOptions, cancellationToken);
            return series ?? [];
        }
        catch (HttpRequestException)
        {
            throw new InvalidOperationException("Unable to load series from the API right now.");
        }
    }

    public async Task<SeriesRecord> CreateSeriesAsync(SeriesUpsertRequest request, CancellationToken cancellationToken = default)
    {
        using var response = await SendAuthorizedAsync(HttpMethod.Post, "series", request, cancellationToken);

        return await ReadSeriesResponseAsync(response, "Unable to create the series right now.", cancellationToken);
    }

    public async Task<SeriesRecord> UpdateSeriesAsync(string id, SeriesUpsertRequest request, CancellationToken cancellationToken = default)
    {
        using var response = await SendAuthorizedAsync(HttpMethod.Put, $"series/{id}", request, cancellationToken);

        return await ReadSeriesResponseAsync(response, "Unable to update the series right now.", cancellationToken);
    }

    public async Task<SeriesRecord> DeleteSeriesAsync(string id, CancellationToken cancellationToken = default)
    {
        using var response = await SendAuthorizedAsync(HttpMethod.Delete, $"series/{id}", null, cancellationToken);

        return await ReadSeriesResponseAsync(response, "Unable to delete the series right now.", cancellationToken);
    }

    private HttpClient CreateClient()
    {
        var client = _httpClientFactory.CreateClient("BackendApi");
        client.BaseAddress ??= new Uri(_apiOptions.BaseUrl);
        return client;
    }

    private async Task<HttpResponseMessage> SendAuthorizedAsync(HttpMethod method, string relativePath, object? requestBody, CancellationToken cancellationToken)
    {
        if (!_clientAuthState.IsAuthenticated || string.IsNullOrWhiteSpace(_clientAuthState.Token))
        {
            throw new InvalidOperationException("You must be logged in to manage series.");
        }

        try
        {
            var client = CreateClient();
            using var message = new HttpRequestMessage(method, relativePath);

            message.Headers.Authorization = new AuthenticationHeaderValue("Bearer", _clientAuthState.Token);

            if (requestBody is not null)
            {
                message.Content = JsonContent.Create(requestBody, options: JsonOptions);
            }

            var response = await client.SendAsync(message, cancellationToken);

            if (!response.IsSuccessStatusCode)
            {
                response.Dispose();
                throw new InvalidOperationException(GetFailureMessage(method));
            }

            return response;
        }
        catch (HttpRequestException)
        {
            throw new InvalidOperationException(GetFailureMessage(method));
        }
    }

    private static async Task<SeriesRecord> ReadSeriesResponseAsync(HttpResponseMessage response, string fallbackMessage, CancellationToken cancellationToken)
    {
        try
        {
            var series = await response.Content.ReadFromJsonAsync<SeriesRecord>(JsonOptions, cancellationToken);

            return series ?? throw new InvalidOperationException(fallbackMessage);
        }
        catch (JsonException)
        {
            throw new InvalidOperationException(fallbackMessage);
        }
    }

    private static string GetFailureMessage(HttpMethod method) => method.Method switch
    {
        "POST" => "Unable to create the series right now.",
        "PUT" => "Unable to update the series right now.",
        "DELETE" => "Unable to delete the series right now.",
        _ => "Unable to complete the series request right now."
    };
}