using Appd.Api.Contracts.Auth;
using Appd.Api.Auth;
using Appd.Infrastructure.MongoDb.Documents;
using Appd.Infrastructure.MongoDb.Repositories;

namespace Appd.Api.Services.Auth;

public sealed class AuthService : IAuthService
{
    private readonly IUserRepository _users;
    private readonly IAuthTokenService _tokenService;

    public AuthService(IUserRepository users, IAuthTokenService tokenService)
    {
        _users = users;
        _tokenService = tokenService;
    }

    public async Task<LoginResponse?> LoginAsync(LoginRequest request, CancellationToken cancellationToken)
    {
        var normalizedEmail = NormalizeEmail(request.Email);
        var user = await _users.FindByEmailAsync(normalizedEmail, cancellationToken);

        if (user is null)
        {
            return null;
        }

        var validPassword = BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash);
        if (!validPassword)
        {
            return null;
        }

        return BuildResponse(user, "Login successful");
    }

    public async Task<(LoginResponse? Response, bool UserExists)> RegisterAsync(RegisterRequest request, CancellationToken cancellationToken)
    {
        var normalizedEmail = NormalizeEmail(request.Email);
        var existing = await _users.FindByEmailAsync(normalizedEmail, cancellationToken);

        if (existing is not null)
        {
            return (null, true);
        }

        var user = new UserDocument
        {
            Email = normalizedEmail,
            FirstName = request.FirstName.Trim(),
            LastName = request.LastName.Trim(),
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password)
        };

        var created = await _users.AddAsync(user, cancellationToken);
        return (BuildResponse(created, "Registration successful"), false);
    }

    private LoginResponse BuildResponse(UserDocument user, string message)
    {
        return new LoginResponse
        {
            Message = message,
            AccessToken = _tokenService.CreateToken(user),
            Id = user.Id,
            Email = user.Email,
            FirstName = user.FirstName,
            LastName = user.LastName
        };
    }

    private static string NormalizeEmail(string email)
    {
        return email.Trim().ToLowerInvariant();
    }
}
