using SeriesCatalog.Infrastructure.MongoDb.Documents;
using Microsoft.EntityFrameworkCore;

namespace SeriesCatalog.Infrastructure.MongoDb;

public sealed class AppMongoDbContext(DbContextOptions<AppMongoDbContext> options) : DbContext(options)
{
    public DbSet<UserDocument> Users => Set<UserDocument>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
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

