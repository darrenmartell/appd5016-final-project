using SeriesCatalog.Infrastructure.MongoDb.Documents;

namespace SeriesCatalog.WebApi.Auth;

public interface IAuthTokenService
{
    string CreateToken(UserDocument user);
}


