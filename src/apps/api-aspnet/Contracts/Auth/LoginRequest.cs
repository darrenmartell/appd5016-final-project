using System.ComponentModel.DataAnnotations;

namespace SeriesCatalog.WebApi.Contracts.Auth;

public sealed class LoginRequest
{
    [Required]
    [EmailAddress]
    public string Email { get; init; } = string.Empty;

    [Required]
    [StringLength(128, MinimumLength = 1)]
    public string Password { get; init; } = string.Empty;
}

