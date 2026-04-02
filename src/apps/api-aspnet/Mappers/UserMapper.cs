using SeriesCatalog.WebApi.Contracts.Users;
using SeriesCatalog.Infrastructure.MongoDb.Documents;

namespace SeriesCatalog.WebApi.Mappers;

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


