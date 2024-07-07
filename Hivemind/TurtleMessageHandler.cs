using System.Text.Json;
using System.Text.Json.Nodes;

namespace Hivemind;

public class TurtleMessageHandler(TurtleService turtleService, BlockRepository blockRepository)
{
    public Turtle Turtle { private get; set; } = null!;

    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

    public async Task Handle(Stream message)
    {
        message.Seek(0, SeekOrigin.Begin);
        var json = JsonSerializer.Deserialize<JsonObject>(message, JsonOptions);
        string type = json!["type"]!.AsValue().GetValue<string>();
        JsonNode data = json["data"]!;
        await Handle(type, data);
    }

    private async Task Handle(string type, JsonNode data)
    {
        switch (type)
        {
            case "updateWorld":
                await UpdateWorld(data.Deserialize<List<BlockUpdate>>(JsonOptions)!);
                return;
        }

        throw new NotSupportedException("Unknown message type " + type);
    }

    private async Task UpdateWorld(List<BlockUpdate> updates)
    {
        Dimension dimension = Turtle.Dimension;
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

        await blockRepository.SaveUpdates(Turtle.World, added, updated);
    }
}

public record BlockUpdate(byte DimensionId, Coordinates Coordinates, string Id, long LastUpdate);

