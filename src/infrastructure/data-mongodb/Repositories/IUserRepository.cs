using SeriesCatalog.Infrastructure.MongoDb.Documents;

namespace SeriesCatalog.Infrastructure.MongoDb.Repositories;

public interface IUserRepository
{
    Task<IReadOnlyList<UserDocument>> ListAsync(CancellationToken cancellationToken);

    Task<UserDocument?> FindByIdAsync(string id, CancellationToken cancellationToken);

    Task<UserDocument?> FindByEmailAsync(string email, CancellationToken cancellationToken);

    Task<UserDocument> AddAsync(UserDocument user, CancellationToken cancellationToken);

    Task<UserDocument?> UpdatePasswordHashAsync(string id, string passwordHash, CancellationToken cancellationToken);

    Task<UserDocument?> DeleteByIdAsync(string id, CancellationToken cancellationToken);
}

