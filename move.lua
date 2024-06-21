require'vector'
require'queue'

-- current turtle state
local t = {}
t.pos = Vec:new{ 0, 0, 0 }
t.rot = 0
t.air = {} -- known air blocks

local moves = {
    fw = { 1, 0, 0, rot = 0 },
    right = { 0, 0, 1, rot = 1 },
    bw = { -1, 0, 0, rot = 2 },
    left = { 0, 0, -1, rot = 3 },
    up = { 0, 1, 0 },
    down = { 0, -1, 0 },
}

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
        turtle.turnRight()
        t.rot = t.rot + 2
    else
        error'invalid rotation'
    end
    t.rot = t.rot % 4
end

local function executeHorizontalMove(move)
    return function()
        if not (math.abs(move.rot - t.rot) == 2 and turtle.back()) then
            turnToRot(move.rot)
            turtle.dig()
            if not turtle.forward() then
                t.air[t.pos + move] = nil
                return false
            end
        end
        t.pos = t.pos + move
        t.air[t.pos] = true
        return true
    end
end

moves.fw.execute = executeHorizontalMove(moves.fw)
moves.fw.inv = moves.bw
moves.right.execute = executeHorizontalMove(moves.right)
moves.right.inv = moves.left
moves.bw.execute = executeHorizontalMove(moves.bw)
moves.bw.inv = moves.fw
moves.left.execute = executeHorizontalMove(moves.left)
moves.left.inv = moves.right
moves.up.execute = function()
    turtle.digUp()
    if not turtle.up() then
        t.air[t.pos + moves.up] = nil
        return false
    end
    t.pos = t.pos + moves.up
    t.air[t.pos] = true
    return true
end
moves.up.inv = moves.down
moves.down.execute = function()
    turtle.digDown()
    if not turtle.down() then
        t.air[t.pos + moves.down] = nil
        return false
    end
    t.pos = t.pos + moves.down
    t.air[t.pos] = true
    return true
end
moves.down.inv = moves.up

local function goTo(target)
    target = Vec:new(target)
    local nextMove = {}
    local queue = Queue:new()
    queue:push(target)
    while not queue:empty() do
        local current = queue:pop()

        for _, move in pairs(moves) do
            local next = current + move
            if t.air[next] and not nextMove[next] then
                queue:push(next)
                nextMove[next] = move.inv
                if next == t.pos then
                    break
                end
            end
        end
    end

    local current = t.pos
    while current ~= target do
        local move = nextMove[current]
        if not move.execute() then
            print'failed to move'
            return
        end
        current = current + move
    end
end

local function home()
    goTo{ 0, 0, 0 }
    turnToRot(0)
end

t.air[t.pos] = true

return {
    goTo = goTo,
    home = home,
    fw = moves.fw.execute,
    right = moves.right.execute,
    bw = moves.bw.execute,
    left = moves.left.execute,
    up = moves.up.execute,
    down = moves.down.execute,
}
