using BlazorMigration.Models.Users;

namespace BlazorMigration.Services.Users;

public interface IUsersService
{
    Task<IReadOnlyList<UserSummary>> GetUsersAsync(CancellationToken cancellationToken = default);

    Task DeleteUserAsync(string userId, CancellationToken cancellationToken = default);
}