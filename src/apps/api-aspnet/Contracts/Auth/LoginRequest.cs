using System.ComponentModel.DataAnnotations;

namespace SeriesCatalog.WebApi.Contracts.Auth;

public sealed class LoginRequest
{
    [Required]
    [EmailAddress]
    public string Email { get; init; } = string.Empty;

    [Required]
    [StringLength(128, MinimumLength = 8)]
    [RegularExpression(
        @"^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[!@#$%^&*()_+\-=[\]{};':\""\\|,.<>/?]).+$",
        ErrorMessage = "Password must contain uppercase, lowercase, digit, and special character")]
    public string Password { get; init; } = string.Empty;
}

