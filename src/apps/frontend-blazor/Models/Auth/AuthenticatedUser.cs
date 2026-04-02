namespace SeriesCatalog.Frontend.Models.Auth;

public sealed class AuthenticatedUser
{
    public string? Id { get; init; }

    public string? LegacyId { get; init; }

    public string? Email { get; init; }

    public string? FirstName { get; init; }

    public string? LastName { get; init; }

    public string? EffectiveId => !string.IsNullOrWhiteSpace(LegacyId) ? LegacyId : Id;
}

