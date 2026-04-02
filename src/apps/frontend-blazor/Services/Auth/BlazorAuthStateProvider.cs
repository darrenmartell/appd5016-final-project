using Microsoft.AspNetCore.Components.Authorization;

namespace BlazorMigration.Services.Auth;

public sealed class BlazorAuthStateProvider : AuthenticationStateProvider, IDisposable
{
    private readonly ClientAuthState _clientAuthState;

    public BlazorAuthStateProvider(ClientAuthState clientAuthState)
    {
        _clientAuthState = clientAuthState;
        _clientAuthState.StateChanged += HandleStateChanged;
    }

    public override Task<AuthenticationState> GetAuthenticationStateAsync()
    {
        return Task.FromResult(new AuthenticationState(_clientAuthState.CreatePrincipal()));
    }

    public void Dispose()
    {
        _clientAuthState.StateChanged -= HandleStateChanged;
    }

    private void HandleStateChanged()
    {
        NotifyAuthenticationStateChanged(GetAuthenticationStateAsync());
    }
}