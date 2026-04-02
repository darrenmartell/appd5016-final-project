using System.Collections.Concurrent;
using Appd.Infrastructure.MongoDb.Documents;
using Appd.Infrastructure.MongoDb.Repositories;
using MongoDB.Bson;

namespace Appd.Api.IntegrationTests.Support;

internal sealed class InMemoryUserRepository : IUserRepository
{
    private readonly ConcurrentDictionary<string, UserDocument> _users = new(StringComparer.OrdinalIgnoreCase);

    public Task<IReadOnlyList<UserDocument>> ListAsync(CancellationToken cancellationToken)
    {
        IReadOnlyList<UserDocument> users = _users.Values
            .OrderBy(user => user.FirstName, StringComparer.OrdinalIgnoreCase)
            .ThenBy(user => user.LastName, StringComparer.OrdinalIgnoreCase)
            .ToList();
        return Task.FromResult(users);
    }

    public Task<UserDocument?> FindByIdAsync(string id, CancellationToken cancellationToken)
    {
        _users.TryGetValue(id, out var user);
        return Task.FromResult(user);
    }

    public Task<UserDocument?> FindByEmailAsync(string email, CancellationToken cancellationToken)
    {
        var normalized = email.Trim().ToLowerInvariant();
        var user = _users.Values.FirstOrDefault(candidate => string.Equals(candidate.Email, normalized, StringComparison.OrdinalIgnoreCase));
        return Task.FromResult(user);
    }

    public Task<UserDocument> AddAsync(UserDocument user, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(user.Id))
        {
            user.Id = ObjectId.GenerateNewId().ToString();
        }

        _users[user.Id] = user;
        return Task.FromResult(user);
    }

    public Task<UserDocument?> UpdatePasswordHashAsync(string id, string passwordHash, CancellationToken cancellationToken)
    {
        if (!_users.TryGetValue(id, out var user))
        {
            return Task.FromResult<UserDocument?>(null);
        }

        user.PasswordHash = passwordHash;
        return Task.FromResult<UserDocument?>(user);
    }

    public Task<UserDocument?> DeleteByIdAsync(string id, CancellationToken cancellationToken)
    {
        _users.TryRemove(id, out var removed);
        return Task.FromResult(removed);
    }
}
