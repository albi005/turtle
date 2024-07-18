using Microsoft.AspNetCore.Mvc;

namespace Hivemind;

public class TurtleController(TurtleService turtleService, BlockRepository blockRepository) : ControllerBase
{
    [HttpPost("/updateWorld")]
    public async Task UpdateWorld(
        [FromBody] List<BlockUpdate> updates,
        [FromHeader] string worldId)
    {
        World world = turtleService.Worlds[worldId];
        List<BlockUpdate> added = [];
        List<BlockUpdate> updated = [];
        foreach (BlockUpdate worldUpdate in updates)
        {
            DateTime lastUpdate = DateTime.UnixEpoch.AddMilliseconds(worldUpdate.LastUpdate);
            Dimension dimension = world.GetDimension(worldUpdate.DimensionId);
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

    [HttpGet("/lavaPool")]
    public async Task<IEnumerable<BlockResponse>> GetLavaPool(
        [FromHeader] string worldId,
        [FromHeader] byte dimensionId,
        [FromQuery] long x, [FromQuery] long y, [FromQuery] long z)
    {
        World world = turtleService.Worlds[worldId];
        Dimension dimension = world.GetDimension(dimensionId);
        Coordinates start = new(x, y, z);

        Dictionary<Coordinates, BlockResponse?> visited = [];
        if (!dimension.Blocks.TryGetValue(start, out Block? startBlock))
            return [];
        visited[start] = new(start, startBlock.Type.Id);

        Queue<Coordinates> queue = [];
        queue.Enqueue(start);

        while (queue.Count > 0)
        {
            Coordinates prev = queue.Dequeue();

            foreach (Move move in Move.All)
            {
                Coordinates next = prev + move.Delta;
                if (next.Y > y)
                    continue;
                if (!visited.TryAdd(next, null))
                    continue;
                if (!dimension.Blocks.TryGetValue(next, out Block? block))
                    continue;
                visited[next] = new(next, block.Type.Id);

                if (block.Type == BlockType.Air) // only continue searching from air
                    queue.Enqueue(next);
            }
        }

        return visited.Values.Where(r => r != null)!;
    }
}

public record BlockUpdate(byte DimensionId, Coordinates Coordinates, string Id, long LastUpdate);

public record BlockResponse(Coordinates Coordinates, string Id);