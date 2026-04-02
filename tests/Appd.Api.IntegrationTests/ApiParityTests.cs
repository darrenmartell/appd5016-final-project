using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Appd.Api.Contracts.Auth;
using Appd.Api.IntegrationTests.Support;
using Xunit;

namespace Appd.Api.IntegrationTests;

public sealed class ApiParityTests : IClassFixture<ApiTestFactory>
{
    private readonly HttpClient _client;
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

    public ApiParityTests(ApiTestFactory factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task Register_ReturnsTokenAndIdentityShape()
    {
        var request = new RegisterRequest
        {
            Email = NewEmail(),
            FirstName = "Test",
            LastName = "User",
            Password = "Password1!"
        };

        using var response = await _client.PostAsJsonAsync("/auth/register", request);
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);

        using var document = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        var root = document.RootElement;
        Assert.True(root.TryGetProperty("access_token", out var tokenProperty));
        Assert.False(string.IsNullOrWhiteSpace(tokenProperty.GetString()));
        Assert.True(root.TryGetProperty("_id", out var idProperty));
        Assert.False(string.IsNullOrWhiteSpace(idProperty.GetString()));
        Assert.True(root.TryGetProperty("email", out _));
        Assert.True(root.TryGetProperty("firstName", out _));
        Assert.True(root.TryGetProperty("lastName", out _));
    }

    [Fact]
    public async Task Login_InvalidCredentials_ReturnsUnauthorized()
    {
        var register = new RegisterRequest
        {
            Email = NewEmail(),
            FirstName = "Login",
            LastName = "Case",
            Password = "Password1!"
        };

        await _client.PostAsJsonAsync("/auth/register", register);

        var login = new LoginRequest
        {
            Email = register.Email,
            Password = "WrongPass1!"
        };

        using var response = await _client.PostAsJsonAsync("/auth/login", login);
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task Users_Delete_RequiresJwt()
    {
        var auth = await RegisterAndLoginAsync();
        Assert.False(string.IsNullOrWhiteSpace(auth.UserId));

        using var unauthDelete = await _client.DeleteAsync($"/users/{auth.UserId}");
        Assert.Equal(HttpStatusCode.Unauthorized, unauthDelete.StatusCode);

        using var authorizedRequest = new HttpRequestMessage(HttpMethod.Delete, $"/users/{auth.UserId}");
        authorizedRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", auth.Token);
        using var authDelete = await _client.SendAsync(authorizedRequest);
        Assert.Equal(HttpStatusCode.OK, authDelete.StatusCode);
    }

    [Fact]
    public async Task Series_CreateAndUpdateFlow_UsesExpectedContracts()
    {
        var auth = await RegisterAndLoginAsync();

        using var createRequest = new HttpRequestMessage(HttpMethod.Post, "/series")
        {
            Content = JsonContent.Create(SeriesPayload("Phase6 Title"), options: JsonOptions)
        };
        createRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", auth.Token);

        using var createResponse = await _client.SendAsync(createRequest);
        Assert.Equal(HttpStatusCode.Created, createResponse.StatusCode);

        var createdJson = JsonDocument.Parse(await createResponse.Content.ReadAsStringAsync()).RootElement;
        var seriesId = createdJson.GetProperty("_id").GetString();
        Assert.False(string.IsNullOrWhiteSpace(seriesId));
        Assert.True(createdJson.TryGetProperty("plot_summary", out _));
        Assert.True(createdJson.TryGetProperty("runtime_minutes", out _));
        Assert.True(createdJson.TryGetProperty("released_year", out _));

        using var getResponse = await _client.GetAsync($"/series/{seriesId}");
        Assert.Equal(HttpStatusCode.OK, getResponse.StatusCode);

        using var patchRequest = new HttpRequestMessage(HttpMethod.Patch, $"/series/{seriesId}")
        {
            Content = JsonContent.Create(new { title = "Phase6 Patched", genres = new[] { "Drama" } }, options: JsonOptions)
        };
        patchRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", auth.Token);

        using var patchResponse = await _client.SendAsync(patchRequest);
        Assert.Equal(HttpStatusCode.OK, patchResponse.StatusCode);

        using var deleteRequest = new HttpRequestMessage(HttpMethod.Delete, $"/series/{seriesId}");
        deleteRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", auth.Token);
        using var deleteResponse = await _client.SendAsync(deleteRequest);
        Assert.Equal(HttpStatusCode.OK, deleteResponse.StatusCode);
    }

    [Fact]
    public async Task ChangePassword_AllowsNewPasswordLogin()
    {
        var auth = await RegisterAndLoginAsync();

        using var changeRequest = new HttpRequestMessage(HttpMethod.Patch, $"/auth/{auth.UserId}/changepassword")
        {
            Content = JsonContent.Create("Password2!", options: JsonOptions)
        };
        changeRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", auth.Token);

        using var changeResponse = await _client.SendAsync(changeRequest);
        Assert.Equal(HttpStatusCode.OK, changeResponse.StatusCode);

        var oldPasswordLogin = new LoginRequest
        {
            Email = auth.Email,
            Password = "Password1!"
        };
        using var oldLoginResponse = await _client.PostAsJsonAsync("/auth/login", oldPasswordLogin);
        Assert.Equal(HttpStatusCode.Unauthorized, oldLoginResponse.StatusCode);

        var newPasswordLogin = new LoginRequest
        {
            Email = auth.Email,
            Password = "Password2!"
        };
        using var newLoginResponse = await _client.PostAsJsonAsync("/auth/login", newPasswordLogin);
        Assert.Equal(HttpStatusCode.OK, newLoginResponse.StatusCode);
    }

    [Fact]
    public async Task Series_InvalidPayload_ReturnsValidationProblem()
    {
        var auth = await RegisterAndLoginAsync();

        using var request = new HttpRequestMessage(HttpMethod.Post, "/series")
        {
            Content = JsonContent.Create(new
            {
                plot_summary = "Missing title",
                runtime_minutes = 30,
                released_year = 2020,
                cast = new[] { "A" },
                directors = new[] { "D" },
                genres = new[] { "Drama" },
                countries = new[] { "US" },
                languages = new[] { "English" },
                producers = new[] { "P" },
                production_companies = new[] { "C" },
                ratings = new { imdb = 7.5, rotten_tomatoes = 80, metacritic = 70, user_average = 7.8 },
                episodes = new[] { new { episode_number = 1, episode_title = "Ep1", runtime_minutes = 30 } }
            }, options: JsonOptions)
        };
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", auth.Token);

        using var response = await _client.SendAsync(request);
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);

        using var document = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        Assert.True(document.RootElement.TryGetProperty("errors", out var errors));
        Assert.True(errors.EnumerateObject().Any());
    }

    private static object SeriesPayload(string title)
    {
        return new
        {
            title,
            plot_summary = "A detailed summary",
            runtime_minutes = 30,
            released_year = 2020,
            cast = new[] { "Actor A" },
            directors = new[] { "Director A" },
            genres = new[] { "Drama" },
            countries = new[] { "US" },
            languages = new[] { "English" },
            producers = new[] { "Producer A" },
            production_companies = new[] { "Company A" },
            ratings = new { imdb = 7.5, rotten_tomatoes = 80, metacritic = 70, user_average = 7.8 },
            episodes = new[] { new { episode_number = 1, episode_title = "Episode 1", runtime_minutes = 30 } }
        };
    }

    private async Task<(string Token, string UserId, string Email)> RegisterAndLoginAsync()
    {
        var email = NewEmail();
        var register = new RegisterRequest
        {
            Email = email,
            FirstName = "Phase",
            LastName = "Six",
            Password = "Password1!"
        };

        using var registerResponse = await _client.PostAsJsonAsync("/auth/register", register);
        registerResponse.EnsureSuccessStatusCode();

        using var registerDoc = JsonDocument.Parse(await registerResponse.Content.ReadAsStringAsync());
        var token = registerDoc.RootElement.GetProperty("access_token").GetString() ?? string.Empty;
        var userId = registerDoc.RootElement.GetProperty("_id").GetString() ?? string.Empty;

        return (token, userId, email);
    }

    private static string NewEmail()
    {
        return $"phase6_{Guid.NewGuid():N}@example.com";
    }
}
