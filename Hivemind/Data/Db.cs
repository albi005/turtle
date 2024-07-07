using System.ComponentModel.DataAnnotations;
using Microsoft.EntityFrameworkCore;

namespace Hivemind.Data;

public class Db : DbContext
{
    public DbSet<DbWorld> Worlds => Set<DbWorld>();
    public DbSet<DbBlock> Blocks => Set<DbBlock>();

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
    {
        optionsBuilder.UseSqlite("Data Source=hivemind.db");
    }
}

[Index(nameof(Name), IsUnique = true)]
public record DbWorld(string Name)
{
    public uint Id { get; set; }
}

[PrimaryKey(nameof(WorldId), nameof(Dimension), nameof(X), nameof(Y), nameof(Z))]
public record DbBlock(
    uint WorldId,
    byte Dimension, // 0 = overworld, 1 = nether, 2 = end
    long X,
    long Y,
    long Z,
    [MaxLength(40)] string Type,
    DateTime LastUpdate
)
{
    public DbWorld World { get; set; } = null!;

    public string Type { get; set; } = Type;
    public DateTime LastUpdate { get; set; } = LastUpdate; // UTC
}