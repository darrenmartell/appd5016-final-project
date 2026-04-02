using Appd.Infrastructure.MongoDb.Repositories;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;

namespace Appd.Api.IntegrationTests.Support;

public sealed class ApiTestFactory : WebApplicationFactory<Program>
{
    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment("Development");

        builder.ConfigureServices(services =>
        {
            services.RemoveAll<ISeriesRepository>();
            services.RemoveAll<IUserRepository>();

            services.AddSingleton<ISeriesRepository, InMemorySeriesRepository>();
            services.AddSingleton<IUserRepository, InMemoryUserRepository>();
        });
    }
}
