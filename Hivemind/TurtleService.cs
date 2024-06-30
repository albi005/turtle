using System.Collections.Concurrent;
using System.Net.WebSockets;
using Hivemind.Data;
using Microsoft.EntityFrameworkCore;

namespace Hivemind;

public class TurtleService(IDbContextFactory<Db> dbContextFactory) : IHostedService
{
    public ConcurrentDictionary<string, World> Worlds { get; } = [];

    public event Action? OnChanged;

    public void Register(string worldId, byte dimensionId, uint turtleId, WebSocket webSocket, TaskCompletionSource tcs)
    {
        World world = Worlds.GetOrAdd(worldId, _ => new(worldId));
        Dimension dimension = world.GetDimension(dimensionId);

        world.Turtles.AddOrUpdate(turtleId, _ =>
        {
            Turtle turtle = new(turtleId);
            turtle.Dimension = dimension;
            turtle.Connection = new(turtle, webSocket, tcs);
            return turtle;
        }, (_, turtle) =>
        {
            turtle.Dimension = dimension;
            turtle.Connection = new(turtle, webSocket, tcs);
            return turtle;
        });
        OnChanged?.Invoke();
    }

    public async Task StartAsync(CancellationToken cancellationToken)
    {
        await using Db db = await dbContextFactory.CreateDbContextAsync(cancellationToken);

        var blocks = await db.Blocks
            .AsNoTrackingWithIdentityResolution()
            .Include(block => block.World)
            .ToListAsync(cancellationToken);
    }

    public Task StopAsync(CancellationToken cancellationToken) => Task.CompletedTask;

    public async Task Update(string worldId, List<BlockUpdate> updates)
    {
        throw new NotImplementedException();
    }
}

public record Turtle(uint Id)
{
    public TurtleConnection? Connection { get; set; }
    public Dimension? Dimension { get; set; }
    public Coordinate? Position { get; set; }
}

public record World(string Id)
{
    public Dimension GetDimension(byte id) => id switch
    {
        0 => Overworld, 1 => Nether, 2 => End, _ => throw new ArgumentOutOfRangeException(nameof(id))
    };

    public Dimension Overworld { get; } = new(nameof(Overworld));
    public Dimension Nether { get; } = new(nameof(Nether));
    public Dimension End { get; } = new(nameof(End));
    public ConcurrentDictionary<uint, Turtle> Turtles { get; } = new();
}

public record Dimension(string Name)
{
    public ConcurrentDictionary<Coordinate, BlockType> Blocks { get; } = new();

    public List<Move>? CalculatePath(Coordinate start, Coordinate end)
    {
        Queue<Coordinate> queue = [];
        queue.Enqueue(end);
        Dictionary<Coordinate, Move> nextMoves = [];

        Coordinate current;
        while (queue.Count > 0)
        {
            current = queue.Dequeue();
            foreach (Move move in Move.All)
            {
                Coordinate next = current + move.Delta;
                if (Blocks[next] != BlockType.Air || nextMoves.ContainsKey(next))
                    continue;
                queue.Enqueue(next);
                nextMoves[next] = move.Inverse;
                if (next == start)
                    break;
            }
        }

        if (!nextMoves.ContainsKey(start))
            return null;

        current = start;
        List<Move> moves = [];
        while (current != end)
        {
            var nextMove = nextMoves[current];
            current += nextMove.Delta;
            moves.Add(nextMove);
        }

        return moves;
    }
}

public record struct Coordinate(long X, long Y, long Z);

public record Move(string Id, Vec Delta)
{
    public Move Inverse { get; set; } = null!;

    public static Move East { get; } = new("east", new(1, 0, 0));
    public static Move South { get; } = new("south", new(0, 0, 1));
    public static Move West { get; } = new("west", new(-1, 0, 0));
    public static Move North { get; } = new("north", new(0, 0, -1));
    public static Move Up { get; } = new("up", new(0, 1, 0));
    public static Move Down { get; } = new("down", new(0, -1, 0));
    public static IReadOnlyList<Move> All { get; } = [East, South, West, North, Up, Down];

    static Move()
    {
        East.Inverse = West;
        South.Inverse = North;
        West.Inverse = East;
        North.Inverse = South;
        Up.Inverse = Down;
        Down.Inverse = Up;
    }
}

public record struct Vec(long X, long Y, long Z)
{
    public static Coordinate operator +(Coordinate a, Vec b) => new(a.X + b.X, a.Y + b.Y, a.Z + b.Z);
}

public record Block(BlockType Type, DateTime UpdateTime)
{
    public BlockType Type { get; private set; } = Type;
    public DateTime UpdateTime { get; private set; } = UpdateTime;

    public void Update(BlockType type, DateTime updateTime)
    {
        Type = type;
        UpdateTime = updateTime;
    }
}

public record class BlockType(string Id)
{
    public static BlockType Air { get; } = new("air");
    public static BlockType Lava { get; } = new("lava");
    public static BlockType Solid { get; } = new("solid");
    public static BlockType Barrier { get; } = new("barrier");
}

public record BlockUpdate(byte Dimension, long X, long Y, long Z, string Type);