using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using SeriesCatalog.Infrastructure.MongoDb.Documents;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;

namespace SeriesCatalog.WebApi.Auth;

public sealed class JwtAuthTokenService : IAuthTokenService
{
    private readonly IOptions<JwtOptions> _jwtOptions;

    public JwtAuthTokenService(IOptions<JwtOptions> jwtOptions)
    {
        _jwtOptions = jwtOptions;
    }

    public string CreateToken(UserDocument user)
    {
        var options = _jwtOptions.Value;
        var key = Encoding.UTF8.GetBytes(options.Key);
        var credentials = new SigningCredentials(new SymmetricSecurityKey(key), SecurityAlgorithms.HmacSha256);

        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, user.Email),
            new("_id", user.Id),
            new("firstName", user.FirstName),
            new("lastName", user.LastName)
        };

        var expires = DateTime.UtcNow.AddMinutes(options.ExpiresMinutes <= 0 ? 30 : options.ExpiresMinutes);

        var token = new JwtSecurityToken(
            issuer: options.Issuer,
            audience: options.Audience,
            claims: claims,
            expires: expires,
            signingCredentials: credentials);

        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}


