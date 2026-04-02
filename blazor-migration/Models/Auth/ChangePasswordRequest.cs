namespace BlazorMigration.Models.Auth;

public sealed record ChangePasswordRequest(string CurrentPassword, string NewPassword);