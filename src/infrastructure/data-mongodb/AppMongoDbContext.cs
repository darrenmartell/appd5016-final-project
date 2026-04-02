using Appd.Infrastructure.MongoDb.Documents;
using Microsoft.EntityFrameworkCore;

namespace Appd.Infrastructure.MongoDb;

public sealed class AppMongoDbContext(DbContextOptions<AppMongoDbContext> options) : DbContext(options)
{
    public DbSet<SeriesDocument> Series => Set<SeriesDocument>();

    public DbSet<UserDocument> Users => Set<UserDocument>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<SeriesDocument>(entity =>
        {
            entity.HasKey(s => s.Id);
            entity.Property(s => s.Title).IsRequired();
            entity.Property(s => s.Genre).IsRequired();
        });

        modelBuilder.Entity<UserDocument>(entity =>
        {
            entity.HasKey(user => user.Id);
            entity.Property(user => user.Email).IsRequired();
            entity.Property(user => user.FirstName).IsRequired();
            entity.Property(user => user.LastName).IsRequired();
            entity.Property(user => user.PasswordHash).IsRequired();
        });
    }
}
