namespace BlazorMigration.Models.Auth;

public sealed record RegisterRequest(string FirstName, string LastName, string Email, string Password);