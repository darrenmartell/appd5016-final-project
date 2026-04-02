using System.ComponentModel.DataAnnotations;

namespace BlazorMigration.Models.Auth;

public sealed class RegisterInput
{
    [Required(ErrorMessage = "First Name required")]
    public string FirstName { get; set; } = string.Empty;

    [Required(ErrorMessage = "Last Name required")]
    public string LastName { get; set; } = string.Empty;

    [Required]
    [EmailAddress]
    public string Email { get; set; } = string.Empty;

    [Required]
    [RegularExpression(ValidationPatterns.StrongSecretRegex, ErrorMessage = ValidationPatterns.PasswordError)]
    public string Password { get; set; } = string.Empty;

    [Required]
    [Compare(nameof(Password), ErrorMessage = "Passwords do not match")]
    [RegularExpression(ValidationPatterns.StrongSecretRegex, ErrorMessage = ValidationPatterns.PasswordError)]
    public string ConfirmPassword { get; set; } = string.Empty;
}