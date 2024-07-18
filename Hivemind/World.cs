using System.Collections.Concurrent;

namespace Hivemind;

public record Turtle(uint Id, World World, Dimension Dimension)
{
    public TurtleConnection? Connection { get; set; }

    public Dimension Dimension { get; set; } = Dimension;
    public Coordinates? Position { get; set; }
    public int? FuelLevel { get; set; }
    public int? FuelLimit { get; set; }
    public string? CurrentJob { get; set; }
    public string? NextJob { get; set; }
}

public record World(string Name)
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
    public ConcurrentDictionary<Coordinates, Block> Blocks { get; } = new();

    public List<Move>? CalculatePath(Coordinates start, Coordinates end)
    {
        if (start == end) return [];

        Queue<Coordinates> queue = [];
        queue.Enqueue(end);
        Dictionary<Coordinates, Move> nextMoves = [];

        Coordinates current;
        while (queue.Count > 0)
        {
            current = queue.Dequeue();
            foreach (Move move in Move.All)
            {
                Coordinates next = current + move.Delta;
                if (!Blocks.TryGetValue(next, out var nextBlock)
                    || nextBlock.Type != BlockType.Air
                    || nextMoves.ContainsKey(next))
                    continue;
                queue.Enqueue(next);
                nextMoves[next] = move.Inverse;
                if (next == start)
                    break;
            }
        }

        if (!nextMoves.ContainsKey(start))
        {
            long minX = Math.Min(start.X, end.X);
            long minZ = Math.Min(start.Z, end.Z);
            long maxX = Math.Max(start.X, end.X);
            long maxZ = Math.Max(start.Z, end.Z);
            for (long x = minX; x <= maxX; x++)
            {
                for (long z = minZ; z < maxZ; z++)
                {
                    Coordinates coordinates = new(x, start.Y, z);
                    if (coordinates == start) Console.Write('S');
                    else if (coordinates == end) Console.Write('E');
                    else
                    {
                        var b = Blocks.GetValueOrDefault(coordinates);
                        if (b == null) Console.Write('.');
                        else
                        {
                            Console.Write(b.Type.Id switch
                            {
                                "air" => 'O',
                                _ => 'X'
                            });
                        }
                    }
                }
                Console.WriteLine();
            }
            return null;
        }

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

public record struct Coordinates(long X, long Y, long Z);

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
    public static Coordinates operator +(Coordinates a, Vec b) => new(a.X + b.X, a.Y + b.Y, a.Z + b.Z);
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

public record struct BlockType(string Id)
{
    public static BlockType Air { get; } = new("air");
}