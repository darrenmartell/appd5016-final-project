using System.Security.Claims;
using BlazorMigration.Models.Auth;

namespace BlazorMigration.Services.Auth;

public sealed class ClientAuthState
{
    public event Action? StateChanged;

    public AuthenticatedUser? User { get; private set; }

    public string? Token { get; private set; }

    public bool IsAuthenticated => !string.IsNullOrWhiteSpace(Token) && User is not null;

    public void SetAuthentication(AuthenticatedUser user, string token)
    {
        User = user;
        Token = token;
        StateChanged?.Invoke();
    }

    public void Clear()
    {
        User = null;
        Token = null;
        StateChanged?.Invoke();
    }

    public ClaimsPrincipal CreatePrincipal()
    {
        if (!IsAuthenticated || User is null)
        {
            return new ClaimsPrincipal(new ClaimsIdentity());
        }

        var claims = new List<Claim>();

        if (!string.IsNullOrWhiteSpace(User.EffectiveId))
        {
            claims.Add(new Claim(ClaimTypes.NameIdentifier, User.EffectiveId));
        }

        if (!string.IsNullOrWhiteSpace(User.Email))
        {
            claims.Add(new Claim(ClaimTypes.Email, User.Email));
            claims.Add(new Claim(ClaimTypes.Name, User.Email));
        }

        if (!string.IsNullOrWhiteSpace(User.FirstName))
        {
            claims.Add(new Claim(ClaimTypes.GivenName, User.FirstName));
        }

        if (!string.IsNullOrWhiteSpace(User.LastName))
        {
            claims.Add(new Claim(ClaimTypes.Surname, User.LastName));
        }

        return new ClaimsPrincipal(new ClaimsIdentity(claims, "CustomAuth"));
    }
}