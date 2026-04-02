using Appd.Infrastructure.MongoDb.Options;
using Appd.Infrastructure.MongoDb.Repositories;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;
using MongoDB.Driver;

namespace Appd.Infrastructure.MongoDb.DependencyInjection;

public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddMongoPersistence(this IServiceCollection services, IConfiguration configuration)
    {
        var mongoSection = configuration.GetSection(MongoOptions.SectionName);
        services.Configure<MongoOptions>(options =>
        {
            options.ConnectionString = mongoSection["ConnectionString"] ?? string.Empty;
            options.DatabaseName = mongoSection["DatabaseName"] ?? string.Empty;
        });

        services.AddDbContext<AppMongoDbContext>((serviceProvider, options) =>
        {
            var mongoOptions = serviceProvider.GetRequiredService<IOptions<MongoOptions>>().Value;
            var mongoClient = new MongoClient(mongoOptions.ConnectionString);
            options.UseMongoDB(mongoClient, mongoOptions.DatabaseName);
        });

        services.AddScoped<ISeriesRepository, SeriesRepository>();
        services.AddScoped<IUserRepository, UserRepository>();

        return services;
    }
}
