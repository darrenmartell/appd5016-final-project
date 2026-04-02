namespace BlazorMigration.Models.Auth;

public sealed record AuthResult(AuthenticatedUser User, string Token);