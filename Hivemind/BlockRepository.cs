using Hivemind.Data;
using Microsoft.EntityFrameworkCore;

namespace Hivemind;

public class BlockRepository(Db db, WorldRepository worldRepository)
{
    public async Task SaveUpdates(World world, List<BlockUpdate> added, List<BlockUpdate> updated)
    {
        uint worldId = await worldRepository.GetWorldId(world.Name);
        foreach (BlockUpdate blockUpdate in added)
            db.Blocks.Add(new(
                worldId,
                blockUpdate.DimensionId,
                blockUpdate.Coordinates.X,
                blockUpdate.Coordinates.Y,
                blockUpdate.Coordinates.Z,
                blockUpdate.Id,
                DateTime.UnixEpoch.AddMilliseconds(blockUpdate.LastUpdate)
            ));
        foreach (BlockUpdate blockUpdate in updated)
            db.Blocks.Update(new(
                worldId,
                blockUpdate.DimensionId,
                blockUpdate.Coordinates.X,
                blockUpdate.Coordinates.Y,
                blockUpdate.Coordinates.Z,
                blockUpdate.Id,
                DateTime.UnixEpoch.AddMilliseconds(blockUpdate.LastUpdate)
            ));
        await db.SaveChangesAsync();
    }

    public async Task<List<DbBlock>> GetAll()
    {
        return await db.Blocks
            .Include(b => b.World)
            .AsNoTrackingWithIdentityResolution()
            .ToListAsync();
    }
}