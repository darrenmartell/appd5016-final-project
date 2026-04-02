using Appd.Api.Contracts.Users;
using Appd.Infrastructure.MongoDb.Documents;

namespace Appd.Api.Mappers;

public static class UserMapper
{
    public static UserResponse ToResponse(this UserDocument user)
    {
        return new UserResponse
        {
            Id = user.Id,
            Email = user.Email,
            FirstName = user.FirstName,
            LastName = user.LastName
        };
    }
}
