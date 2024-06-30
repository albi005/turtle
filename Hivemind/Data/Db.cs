using System.ComponentModel.DataAnnotations;
using Microsoft.EntityFrameworkCore;

namespace Hivemind.Data;

public class Db : DbContext
{
    public DbSet<World> Worlds => Set<World>();
    public DbSet<Block> Blocks => Set<Block>();

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
    {
        optionsBuilder.UseSqlite("Data Source=hivemind.db");
    }
}

public record World(uint Id, string Name);

[PrimaryKey(nameof(World), nameof(Dimension), nameof(X), nameof(Y), nameof(Z))]
public record Block(
    World World,
    byte Dimension, // 0 = overworld, 1 = nether, 2 = end
    long X,
    long Y,
    long Z,
    [MaxLength(40)] string Type,
    DateTime? LastUpdated = null
)
{
    public uint WorldId { get; set; } = World.Id;
    public string Type { get; set; } = Type;
    public DateTime? LastUpdated { get; set; } = LastUpdated; // UTC
}