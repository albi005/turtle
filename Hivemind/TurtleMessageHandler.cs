using System.Text.Json;
using System.Text.Json.Nodes;

namespace Hivemind;

public class TurtleMessageHandler(TurtleService turtleService)
{
    public Turtle Turtle { private get; set; } = null!;

    public async Task Handle(Stream message)
    {
        message.Seek(0, SeekOrigin.Begin);
        var json = JsonSerializer.Deserialize<JsonObject>(message);
        string type = json!["type"]!.AsValue().GetValue<string>();
        switch (type)
        {
            case "updateWorld":
                await UpdateWorld(json["updates"].Deserialize<List<WorldUpdate>>()!);
                return;
        }

        throw new NotSupportedException("Unknown message type " + type);
    }

    private async Task UpdateWorld(List<WorldUpdate> updates)
    {
    }
}

public record WorldUpdate(Coordinates Coordinates, string Id, long LastUpdate);