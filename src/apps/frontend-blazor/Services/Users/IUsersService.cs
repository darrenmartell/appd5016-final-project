using SeriesCatalog.Frontend.Models.Users;

namespace SeriesCatalog.Frontend.Services.Users;

public interface IUsersService
{
    Task<IReadOnlyList<UserSummary>> GetUsersAsync(CancellationToken cancellationToken = default);

    Task DeleteUserAsync(string userId, CancellationToken cancellationToken = default);
}

