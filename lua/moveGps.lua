local move = {}

-- public record Move(string Id, Vec Delta)
-- {
--     public Move Inverse { get; set; } = null!;

--     public static Move East { get; } = new("east", new(1, 0, 0));
--     public static Move South { get; } = new("south", new(0, 0, 1));
--     public static Move West { get; } = new("west", new(-1, 0, 0));
--     public static Move North { get; } = new("north", new(0, 0, -1));
--     public static Move Up { get; } = new("up", new(0, 1, 0));
--     public static Move Down { get; } = new("down", new(0, -1, 0));
--     public static IReadOnlyList<Move> All { get; } = [East, South, West, North, Up, Down];

--     static Move()
--     {
--         East.Inverse = West;
--         South.Inverse = North;
--         West.Inverse = East;
--         North.Inverse = South;
--         Up.Inverse = Down;
--         Down.Inverse = Up;
--     }
-- }

move.east = { 1, 0, 0 }
move.south = { 0, 0, 1 }
move.west = { -1, 0, 0 }
move.north = { 0, 0, -1 }
move.up = { 0, 1, 0 }
move.down = { 0, -1, 0 }

move.east.inv = move.west
move.south.inv = move.north
move.west.inv = move.east
move.north.inv = move.south
move.up.inv = move.down
move.down.inv = move.up

move.rotToMove = {
    [0] = move.east,
    [1] = move.south,
    [2] = move.west,
    [3] = move.north,
}

return move