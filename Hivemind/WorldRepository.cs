using Hivemind.Data;
using Microsoft.EntityFrameworkCore;

namespace Hivemind;

public class WorldRepository(Db db)
{
    public async Task<uint> GetWorldId(string worldName)
        => (await db.Worlds.FirstAsync(w => w.Name == worldName)).Id;

    public async Task Add(World world)
    {
        db.Worlds.Add(new(world.Name));
        await db.SaveChangesAsync();
    }
}