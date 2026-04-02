using BlazorMigration.Models.Auth;

namespace BlazorMigration.Services.Auth;

public interface IAuthService
{
    Task LoginAsync(LoginRequest request, CancellationToken cancellationToken = default);

    Task RegisterAsync(RegisterRequest request, CancellationToken cancellationToken = default);

    Task ChangePasswordAsync(ChangePasswordRequest request, CancellationToken cancellationToken = default);

    Task LogoutAsync();
}