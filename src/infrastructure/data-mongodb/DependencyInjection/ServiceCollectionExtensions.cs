using SeriesCatalog.Infrastructure.MongoDb.Options;
using SeriesCatalog.Infrastructure.MongoDb.Repositories;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;
using MongoDB.Driver;

namespace SeriesCatalog.Infrastructure.MongoDb.DependencyInjection;

public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddMongoPersistence(this IServiceCollection services, IConfiguration configuration)
    {
        var mongoSection = configuration.GetSection(MongoOptions.SectionName);
        var connectionString = mongoSection["ConnectionString"] ?? string.Empty;
        var databaseName = mongoSection["DatabaseName"] ?? string.Empty;

        services.Configure<MongoOptions>(options =>
        {
            options.ConnectionString = connectionString;
            options.DatabaseName = databaseName;
        });

        services.AddSingleton<IMongoClient>(_ => new MongoClient(connectionString));
        services.AddScoped(sp =>
        {
            var client = sp.GetRequiredService<IMongoClient>();
            return client.GetDatabase(databaseName);
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

