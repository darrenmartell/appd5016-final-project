namespace Appd.Api.Common.DependencyInjection;

public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddApiApplication(this IServiceCollection services)
    {
        services.AddOpenApi();
        return services;
    }
}
