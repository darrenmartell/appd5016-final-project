using Appd.Api.Contracts.Auth;

namespace Appd.Api.Services.Auth;

public interface IAuthService
{
    Task<LoginResponse?> LoginAsync(LoginRequest request, CancellationToken cancellationToken);

    Task<(LoginResponse? Response, bool UserExists)> RegisterAsync(RegisterRequest request, CancellationToken cancellationToken);
}
