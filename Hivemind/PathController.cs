using Microsoft.AspNetCore.Mvc;

namespace Hivemind;

public class PathController(TurtleService turtleService) : ControllerBase
{
    public record PathRequest(Coordinates Start, Coordinates End);

    [HttpPost("/path")]
    public IEnumerable<string>? Get([FromHeader] string worldId, [FromHeader] uint turtleId,
        [FromBody] PathRequest request)
    {
        World world = turtleService.Worlds[worldId];
        Turtle turtle = world.Turtles[turtleId];
        Dimension dimension = turtle.Dimension;
        var moves = dimension.CalculatePath(request.Start, request.End);
        return moves?.Select(m => m.Id);
    }
}