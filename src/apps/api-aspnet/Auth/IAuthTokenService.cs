using Appd.Infrastructure.MongoDb.Documents;

namespace Appd.Api.Auth;

public interface IAuthTokenService
{
    string CreateToken(UserDocument user);
}
