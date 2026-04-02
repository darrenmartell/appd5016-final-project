using System.ComponentModel.DataAnnotations;

namespace BlazorMigration.Models.Auth;

public sealed class ChangePasswordInput
{
    [Required]
    [RegularExpression(ValidationPatterns.Password, ErrorMessage = ValidationPatterns.PasswordError)]
    public string CurrentPassword { get; set; } = string.Empty;

    [Required]
    [RegularExpression(ValidationPatterns.Password, ErrorMessage = ValidationPatterns.PasswordError)]
    public string NewPassword { get; set; } = string.Empty;

    [Required]
    [Compare(nameof(NewPassword), ErrorMessage = "New Passwords do not match")]
    [RegularExpression(ValidationPatterns.Password, ErrorMessage = ValidationPatterns.PasswordError)]
    public string ConfirmPassword { get; set; } = string.Empty;
}