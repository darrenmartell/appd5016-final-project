namespace SeriesCatalog.Frontend.Models.Auth;

public sealed record AuthResult(AuthenticatedUser User, string Token);

