using Appd.Infrastructure.MongoDb.Documents;

namespace Appd.Infrastructure.MongoDb.Repositories;

public interface IUserRepository
{
    Task<UserDocument?> FindByEmailAsync(string email, CancellationToken cancellationToken);

    Task<UserDocument> AddAsync(UserDocument user, CancellationToken cancellationToken);
}
