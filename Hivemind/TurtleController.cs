using Microsoft.AspNetCore.Mvc;

namespace Hivemind;

public class TurtleController(TurtleService turtleService, BlockRepository blockRepository) : ControllerBase
{
    [HttpPost("/updateWorld")]
    public async Task UpdateWorld(
        [FromBody] List<BlockUpdate> updates,
        [FromHeader] string worldId,
        [FromHeader] byte dimensionId)
    {
        World world = turtleService.Worlds[worldId];
        Dimension dimension = world.GetDimension(dimensionId);
        List<BlockUpdate> added = [];
        List<BlockUpdate> updated = [];
        foreach (BlockUpdate worldUpdate in updates)
        {
            DateTime lastUpdate = DateTime.UnixEpoch.AddMilliseconds(worldUpdate.LastUpdate);
            dimension.Blocks.AddOrUpdate(
                worldUpdate.Coordinates,
                _ =>
                {
                    added.Add(worldUpdate);
                    return new(new(worldUpdate.Id), lastUpdate);
                },
                (_, block) =>
                {
                    if (lastUpdate <= block.UpdateTime)
                        return block;
                    updated.Add(worldUpdate);
                    return new(new(worldUpdate.Id), lastUpdate);
                });
        }

        await blockRepository.SaveUpdates(world, added, updated);
    }
}

public record BlockUpdate(byte DimensionId, Coordinates Coordinates, string Id, long LastUpdate);
