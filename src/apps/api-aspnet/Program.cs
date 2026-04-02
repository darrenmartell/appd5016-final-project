using Appd.Api.Common.Authorization;
using Appd.Api.Common.DependencyInjection;
using Appd.Api.Endpoints;
using Appd.Infrastructure.MongoDb.DependencyInjection;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddApiApplication(builder.Configuration);
builder.Services.AddMongoPersistence(builder.Configuration);

var app = builder.Build();

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

public partial class Program
{
}
