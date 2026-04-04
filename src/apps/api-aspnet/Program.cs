using SeriesCatalog.WebApi.Common.Authorization;
using SeriesCatalog.WebApi.Common.DependencyInjection;
using SeriesCatalog.WebApi.Endpoints;
using SeriesCatalog.Infrastructure.MongoDb.DependencyInjection;
using SeriesCatalog.Infrastructure.MongoDb.Options;
using System.Linq;
using Microsoft.Extensions.Options;
using MongoDB.Driver;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddApiApplication(builder.Configuration);
builder.Services.AddMongoPersistence(builder.Configuration);

var app = builder.Build();

LogMongoTarget(app);

app.UseExceptionHandler();
app.UseStatusCodePages();
app.UseCors(ApiPolicies.CorsPolicyName);
app.UseAuthentication();
app.UseAuthorization();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.MapHealthEndpoints();
app.MapAuthEndpoints();
app.MapUserEndpoints();
app.MapSeriesDomainEndpoints();

app.Run();

static void LogMongoTarget(WebApplication app)
{
    var mongoOptions = app.Services.GetRequiredService<IOptions<MongoOptions>>().Value;

    try
    {
        var mongoUrl = new MongoUrl(mongoOptions.ConnectionString);
        var hosts = string.Join(",", mongoUrl.Servers.Select(server => server.ToString()));
        hosts = string.IsNullOrWhiteSpace(hosts) ? "<unknown>" : hosts;

        app.Logger.LogInformation(
            "Mongo target configured. Database: {DatabaseName}; Hosts: {Hosts}",
            mongoOptions.DatabaseName,
            hosts);
    }
    catch
    {
        app.Logger.LogInformation(
            "Mongo target configured. Database: {DatabaseName}; Host parsing unavailable.",
            mongoOptions.DatabaseName);
    }
}
