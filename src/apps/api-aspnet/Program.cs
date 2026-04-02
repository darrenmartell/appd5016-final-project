using Appd.Api.Common.DependencyInjection;
using Appd.Api.Endpoints;
using Appd.Infrastructure.MongoDb.DependencyInjection;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddApiApplication();
builder.Services.AddMongoPersistence(builder.Configuration);

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.MapHealthEndpoints();
app.MapSeriesEndpoints();

app.Run();
