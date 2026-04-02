namespace BlazorMigration.Models.Auth;

public static class ValidationPatterns
{
    public const string Password = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[@$!%*?&])[A-Za-z\\d@$!%*?&]{8,}$";
    public const string PasswordError = "Password must be 8+ characters with uppercase, lowercase, number, and special character.";
}