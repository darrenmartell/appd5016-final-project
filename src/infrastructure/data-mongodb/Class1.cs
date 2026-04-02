using Microsoft.EntityFrameworkCore;

namespace Appd.Infrastructure.MongoDb;

public sealed class AppMongoDbContext(DbContextOptions<AppMongoDbContext> options) : DbContext(options)
{
	public DbSet<SeriesDocument> Series => Set<SeriesDocument>();

	protected override void OnModelCreating(ModelBuilder modelBuilder)
	{
		modelBuilder.Entity<SeriesDocument>(entity =>
		{
			entity.HasKey(s => s.Id);
			entity.Property(s => s.Title).IsRequired();
			entity.Property(s => s.Genre).IsRequired();
		});
	}
}

public sealed class SeriesDocument
{
	public string Id { get; set; } = Guid.NewGuid().ToString("N");

	public string Title { get; set; } = string.Empty;

	public string Genre { get; set; } = string.Empty;

	public int ReleaseYear { get; set; }
}
