using Appd.Infrastructure.MongoDb;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using MongoDB.Driver;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddOpenApi();
builder.Services.Configure<MongoOptions>(builder.Configuration.GetSection(MongoOptions.SectionName));

builder.Services.AddDbContext<AppMongoDbContext>((sp, options) =>
{
    var mongoOptions = sp.GetRequiredService<IOptions<MongoOptions>>().Value;
    var mongoClient = new MongoClient(mongoOptions.ConnectionString);
    options.UseMongoDB(mongoClient, mongoOptions.DatabaseName);
});

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.MapGet("/api/health", () => Results.Ok(new { status = "ok" }));

app.MapGet("/api/series", async (AppMongoDbContext dbContext, CancellationToken cancellationToken) =>
{
    var items = await dbContext.Series
        .OrderBy(item => item.Title)
        .ToListAsync(cancellationToken);

    return Results.Ok(items);
});

app.MapPost("/api/series", async (CreateSeriesRequest request, AppMongoDbContext dbContext, CancellationToken cancellationToken) =>
{
    var item = new SeriesDocument
    {
        Title = request.Title,
        Genre = request.Genre,
        ReleaseYear = request.ReleaseYear
    };

    dbContext.Series.Add(item);
    await dbContext.SaveChangesAsync(cancellationToken);

    return Results.Created($"/api/series/{item.Id}", item);
});

app.Run();

public sealed class MongoOptions
{
    public const string SectionName = "Mongo";

    public string ConnectionString { get; set; } = string.Empty;

    public string DatabaseName { get; set; } = string.Empty;
}

public sealed record CreateSeriesRequest(string Title, string Genre, int ReleaseYear);
