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
        }

        throw new NotSupportedException("Unknown message type " + type);
    }

}

