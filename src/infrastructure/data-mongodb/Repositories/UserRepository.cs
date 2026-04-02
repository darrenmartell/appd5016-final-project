using SeriesCatalog.Infrastructure.MongoDb.Documents;
using MongoDB.Driver;

namespace SeriesCatalog.Infrastructure.MongoDb.Repositories;

public sealed class UserRepository : IUserRepository
{
    private readonly IMongoCollection<UserDocument> _users;

    public UserRepository(IMongoDatabase database)
    {
        _users = database.GetCollection<UserDocument>("users");
    }

    public async Task<IReadOnlyList<UserDocument>> ListAsync(CancellationToken cancellationToken)
    {
        return await _users.Find(FilterDefinition<UserDocument>.Empty)
            .SortBy(user => user.FirstName)
            .ThenBy(user => user.LastName)
            .ToListAsync(cancellationToken);
    }

    public async Task<UserDocument?> FindByIdAsync(string id, CancellationToken cancellationToken)
    {
        return await _users.Find(user => user.Id == id)
            .SingleOrDefaultAsync(cancellationToken);
    }

    public async Task<UserDocument?> FindByEmailAsync(string email, CancellationToken cancellationToken)
    {
        return await _users.Find(user => user.Email == email)
            .SingleOrDefaultAsync(cancellationToken);
    }

    public async Task<UserDocument> AddAsync(UserDocument user, CancellationToken cancellationToken)
    {
        await _users.InsertOneAsync(user, cancellationToken: cancellationToken);
        return user;
    }

    public async Task<UserDocument?> UpdatePasswordHashAsync(string id, string passwordHash, CancellationToken cancellationToken)
    {
        var options = new FindOneAndUpdateOptions<UserDocument>
        {
            ReturnDocument = ReturnDocument.After
        };

        var update = Builders<UserDocument>.Update
            .Set(user => user.PasswordHash, passwordHash);

        return await _users.FindOneAndUpdateAsync(user => user.Id == id, update, options, cancellationToken);
    }

    public async Task<UserDocument?> DeleteByIdAsync(string id, CancellationToken cancellationToken)
    {
        return await _users.FindOneAndDeleteAsync(user => user.Id == id, cancellationToken: cancellationToken);
    }
}

