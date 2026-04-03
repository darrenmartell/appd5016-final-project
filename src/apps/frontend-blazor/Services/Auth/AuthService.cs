using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using SeriesCatalog.Frontend.Models.Auth;
using SeriesCatalog.Frontend.Services.Api;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace SeriesCatalog.Frontend.Services.Auth;

public sealed class AuthService : IAuthService
{
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly ClientAuthState _clientAuthState;
    private readonly ApiOptions _apiOptions;
    private readonly ILogger<AuthService> _logger;

    public AuthService(
        IHttpClientFactory httpClientFactory,
        ClientAuthState clientAuthState,
        IOptions<ApiOptions> apiOptions,
        ILogger<AuthService> logger)
    {
        _httpClientFactory = httpClientFactory;
        _clientAuthState = clientAuthState;
        _apiOptions = apiOptions.Value;
        _logger = logger;
    }

    public async Task LoginAsync(LoginRequest request, CancellationToken cancellationToken = default)
    {
        try
        {
            var client = CreateClient();
            using var timeoutCts = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
            timeoutCts.CancelAfter(TimeSpan.FromSeconds(20));

            _logger.LogInformation("Starting login request for {Email}", request.Email);
            using var response = await client.PostAsJsonAsync("auth/login", request, timeoutCts.Token);
            _logger.LogInformation("Login response status: {StatusCode}", (int)response.StatusCode);

            if (!response.IsSuccessStatusCode)
            {
                throw new InvalidOperationException("Error logging in. Please check your credentials and try again.");
            }

            var authResult = await ParseAuthResultAsync(response, timeoutCts.Token);
            _clientAuthState.SetAuthentication(authResult.User, authResult.Token);
        }
        catch (TaskCanceledException)
        {
            _logger.LogWarning("Login request timed out for {Email}", request.Email);
            throw new InvalidOperationException("Login timed out. Please try again.");
        }
        catch (HttpRequestException)
        {
            _logger.LogWarning("Login request network error for {Email}", request.Email);
            throw new InvalidOperationException("Error logging in. Please check your credentials and try again.");
        }
        catch (InvalidOperationException)
        {
            throw;
        }
        catch (Exception exception)
        {
            _logger.LogError(exception, "Unexpected login error for {Email}", request.Email);
            throw new InvalidOperationException("Unexpected login error. Please try again.");
        }
    }

    public async Task RegisterAsync(RegisterRequest request, CancellationToken cancellationToken = default)
    {
        try
        {
            var client = CreateClient();
            using var response = await client.PostAsJsonAsync("auth/register", request, cancellationToken);

            if (!response.IsSuccessStatusCode)
            {
                _clientAuthState.Clear();
                throw new InvalidOperationException("Error registering. Please check your credentials and try again.");
            }

            var authResult = await ParseAuthResultAsync(response, cancellationToken);
            _clientAuthState.SetAuthentication(authResult.User, authResult.Token);
        }
        catch (HttpRequestException)
        {
            _clientAuthState.Clear();
            throw new InvalidOperationException("Error registering. Please check your credentials and try again.");
        }
    }

    public async Task ChangePasswordAsync(ChangePasswordRequest request, CancellationToken cancellationToken = default)
    {
        if (!_clientAuthState.IsAuthenticated || _clientAuthState.User is null || string.IsNullOrWhiteSpace(_clientAuthState.Token))
        {
            throw new InvalidOperationException("You must be logged in to change your password.");
        }

        if (string.IsNullOrWhiteSpace(_clientAuthState.User.EffectiveId))
        {
            throw new InvalidOperationException("Authenticated user ID is missing. Sign in again and retry.");
        }

        try
        {
            var client = CreateClient();
            using var message = new HttpRequestMessage(HttpMethod.Patch, $"auth/{_clientAuthState.User.EffectiveId}/changepassword")
            {
                Content = JsonContent.Create(request.NewPassword)
            };

            message.Headers.Authorization = new AuthenticationHeaderValue("Bearer", _clientAuthState.Token);

            using var response = await client.SendAsync(message, cancellationToken);

            if (!response.IsSuccessStatusCode)
            {
                throw new InvalidOperationException("Error changing password. Please check your credentials and try again.");
            }
        }
        catch (HttpRequestException)
        {
            throw new InvalidOperationException("Error changing password. Please check your credentials and try again.");
        }
    }

    public Task LogoutAsync()
    {
        _clientAuthState.Clear();
        return Task.CompletedTask;
    }

    private HttpClient CreateClient()
    {
        var client = _httpClientFactory.CreateClient("BackendApi");
        client.BaseAddress ??= new Uri(_apiOptions.BaseUrl);
        return client;
    }

    private static async Task<AuthResult> ParseAuthResultAsync(HttpResponseMessage response, CancellationToken cancellationToken)
    {
        await using var contentStream = await response.Content.ReadAsStreamAsync(cancellationToken);
        using var document = await JsonDocument.ParseAsync(contentStream, cancellationToken: cancellationToken);
        var root = document.RootElement;

        var token = TryGetString(root, "access_token")
            ?? TryGetString(root, "accessToken")
            ?? throw new InvalidOperationException("The API did not return an access token.");

        var resolvedId = TryGetString(root, "_id") ?? TryGetString(root, "id");

        var user = new AuthenticatedUser
        {
            Id = TryGetString(root, "id") ?? resolvedId,
            LegacyId = TryGetString(root, "_id") ?? resolvedId,
            Email = TryGetString(root, "email"),
            FirstName = TryGetString(root, "firstName"),
            LastName = TryGetString(root, "lastName")
        };

        return new AuthResult(user, token);
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

