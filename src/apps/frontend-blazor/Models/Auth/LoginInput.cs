using System.ComponentModel.DataAnnotations;

namespace SeriesCatalog.Frontend.Models.Auth;

public sealed class LoginInput
{
    [Required]
    [EmailAddress]
    public string Email { get; set; } = string.Empty;

    [Required]
    [StringLength(128, MinimumLength = 1)]
    public string Password { get; set; } = string.Empty;
}

