using System.ComponentModel.DataAnnotations;

namespace BlazorMigration.Models.Auth;

public sealed class LoginInput
{
    [Required]
    [EmailAddress]
    public string Email { get; set; } = string.Empty;

    [Required]
    [RegularExpression(ValidationPatterns.Password, ErrorMessage = ValidationPatterns.PasswordError)]
    public string Password { get; set; } = string.Empty;
}