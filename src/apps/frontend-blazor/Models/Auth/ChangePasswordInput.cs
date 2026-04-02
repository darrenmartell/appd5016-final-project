using System.ComponentModel.DataAnnotations;

namespace SeriesCatalog.Frontend.Models.Auth;

public sealed class ChangePasswordInput
{
    [Required]
    [RegularExpression(ValidationPatterns.StrongSecretRegex, ErrorMessage = ValidationPatterns.PasswordError)]
    public string CurrentPassword { get; set; } = string.Empty;

    [Required]
    [RegularExpression(ValidationPatterns.StrongSecretRegex, ErrorMessage = ValidationPatterns.PasswordError)]
    public string NewPassword { get; set; } = string.Empty;

    [Required]
    [Compare(nameof(NewPassword), ErrorMessage = "New Passwords do not match")]
    [RegularExpression(ValidationPatterns.StrongSecretRegex, ErrorMessage = ValidationPatterns.PasswordError)]
    public string ConfirmPassword { get; set; } = string.Empty;
}

