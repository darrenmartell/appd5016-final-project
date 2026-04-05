using SeriesCatalog.WebApi.Contracts.Auth;

namespace SeriesCatalog.WebApi.Services.Auth;

public interface IAuthService
{
    Task<LoginResponse?> LoginAsync(LoginRequest request, CancellationToken cancellationToken);

    Task<(LoginResponse? Response, bool UserExists)> RegisterAsync(RegisterRequest request, CancellationToken cancellationToken);
}

