using Appd.Infrastructure.MongoDb.Documents;
using Microsoft.EntityFrameworkCore;

namespace Appd.Infrastructure.MongoDb.Repositories;

public sealed class UserRepository : IUserRepository
{
    private readonly AppMongoDbContext _dbContext;

    public UserRepository(AppMongoDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<UserDocument?> FindByEmailAsync(string email, CancellationToken cancellationToken)
    {
        return await _dbContext.Users
            .SingleOrDefaultAsync(user => user.Email == email, cancellationToken);
    }

    public async Task<UserDocument> AddAsync(UserDocument user, CancellationToken cancellationToken)
    {
        _dbContext.Users.Add(user);
        await _dbContext.SaveChangesAsync(cancellationToken);
        return user;
    }
}
