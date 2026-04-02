namespace Appd.Api.Auth;

public interface IAuthTokenService
{
    string CreateToken(string subject);
}
