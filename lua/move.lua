require'queue'
require'world'
local Vec = require'vecMemo'

-- current turtle state
local t = {}
t.pos = Vec.new{0, 0, 0}
t.rot = 0

local moves = {
    east = {1, 0, 0, rot = 0},
    south = {0, 0, 1, rot = 1},
    west = {-1, 0, 0, rot = 2},
    north = {0, 0, -1, rot = 3},
    up = {0, 1, 0},
    down = {0, -1, 0},
}

local rotToMove = {
    [0] = moves.east,
    [1] = moves.south,
    [2] = moves.west,
    [3] = moves.north,
}

local function getBlockType(has_block, data)
    if not has_block then
        return BlockTypes.empty
    end
    if data.name == 'minecraft:lava' then
        if data.state.level == 0 then
            return BlockTypes.lava
        else
            return BlockTypes.empty
        end
    end
    return BlockTypes.solid
end

local function updateWorldForward()
    World[t.pos + rotToMove[t.rot]] = getBlockType(turtle.inspect())
end

local function updateWorldUp()
    World[t.pos + moves.up] = getBlockType(turtle.inspectUp())
end

local function updateWorldDown()
    World[t.pos + moves.down] = getBlockType(turtle.inspectDown())
end

local function turnToRot(rot)
    local diff = rot - t.rot
    if diff == 0 then
        return
    end
    if diff == 1 or diff == -3 then
        turtle.turnRight()
        t.rot = t.rot + 1
    elseif diff == -1 or diff == 3 then
        turtle.turnLeft()
        t.rot = t.rot - 1
    elseif diff == 2 or diff == -2 then
        turtle.turnRight()
        t.rot = t.rot + 1
        t.rot = t.rot % 4
        updateWorldForward()

        turtle.turnRight()
        t.rot = t.rot + 1
    else
        error'invalid rotation'
    end
    t.rot = t.rot % 4
    updateWorldForward()
end

local function updateWorld()
    World[t.pos] = BlockTypes.empty
    updateWorldUp()
    updateWorldDown()
    updateWorldForward()
end

local function executeHorizontalMove(move)
    return function()
        if not (math.abs(move.rot - t.rot) == 2 and turtle.back()) then
            turnToRot(move.rot)
            turtle.dig()
            if not turtle.forward() then
                World[t.pos + move] = BlockTypes.barrier
                return false
            end
        end
        t.pos = t.pos + move
        updateWorld()
        return true
    end
end

local function placeHorizontal(move)
    return function()
        turnToRot(move.rot)
        turtle.place()
        updateWorldForward()
    end
end

moves.east.execute = executeHorizontalMove(moves.east)
moves.east.place = placeHorizontal(moves.east)
moves.east.inv = moves.west

moves.south.execute = executeHorizontalMove(moves.south)
moves.south.place = placeHorizontal(moves.south)
moves.south.inv = moves.north

moves.west.execute = executeHorizontalMove(moves.west)
moves.west.place = placeHorizontal(moves.west)
moves.west.inv = moves.east

moves.north.execute = executeHorizontalMove(moves.north)
moves.north.place = placeHorizontal(moves.north)
moves.north.inv = moves.south

moves.up.execute = function()
    turtle.digUp()
    if not turtle.up() then
        World[t.pos + moves.up] = BlockTypes.barrier
        return false
    end
    t.pos = t.pos + moves.up
    updateWorld()
    return true
end
moves.up.place = function()
    turtle.placeUp()
    updateWorldUp()
end
moves.up.inv = moves.down

moves.down.execute = function()
    turtle.digDown()
    if not turtle.down() then
        World[t.pos + moves.down] = BlockTypes.barrier
        return false
    end
    t.pos = t.pos + moves.down
    updateWorld()
    return true
end
moves.down.place = function()
    turtle.placeDown()
    updateWorldDown()
end
moves.down.inv = moves.up

local function goTo(target)
    target = Vec.new(target)
    local nextMove = {}
    local queue = Queue:new()
    queue:push(target)
    while not queue:empty() do
        local current = queue:pop()

        for _, move in pairs(moves) do
            local next = current + move
            if World[next] == BlockTypes.empty and not nextMove[next] then
                queue:push(next)
                nextMove[next] = move.inv
                if next == t.pos then
                    break
                end
            end
        end
    end

    local current = t.pos

    if current == target then return end

    assert(nextMove[current], 'no path to target')

    while current ~= target do
        local move = nextMove[current]
        assert(move.execute(), 'failed to move')
        current = current + move
    end
end

local function home()
    goTo{0, 0, 0}
    turnToRot(0)
end

updateWorld()

return {
    goTo = goTo,
    home = home,
    east = moves.east.execute,
    south = moves.south.execute,
    west = moves.west.execute,
    north = moves.north.execute,
    up = moves.up.execute,
    down = moves.down.execute,
    turnToRot = turnToRot,
    moves = moves,
    getPos = function() return t.pos end,
}
