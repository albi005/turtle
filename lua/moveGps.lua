local world = require'worldHm'

local M = {}

M.position = {0, 0, 0} -- current turtle position
M.rotation = 0         -- current turtle rotation

M.east = {1, 0, 0}
M.south = {0, 0, 1}
M.west = {-1, 0, 0}
M.north = {0, 0, -1}
M.up = {0, 1, 0}
M.down = {0, -1, 0}

M.east.inv = M.west
M.south.inv = M.north
M.west.inv = M.east
M.north.inv = M.south
M.up.inv = M.down
M.down.inv = M.up

M.east.rot = 0
M.south.rot = 1
M.west.rot = 2
M.north.rot = 3

M.rotToMove = {
    [0] = M.east,
    [1] = M.south,
    [2] = M.west,
    [3] = M.north,
}

local function updateWorldForward()
    world.update(M.position + M.rotToMove[M.rotation], turtle.inspect())
end
local function updateWorldUp()
    world.update(M.position + M.up, turtle.inspectUp())
end
local function updateWorldDown()
    world.update(M.position + M.down, turtle.inspectDown())
end
local function updateWorldAtPosition()
    world.update(M.position, false)
end
local function updateWorldAfterHorizontalMove()
    updateWorldAtPosition()
    updateWorldUp()
    updateWorldDown()
end

local function turnToRot(rot)
    if not rot then return end
    local diff = rot - M.rotation
    diff = diff % 4
    if diff == 0 then
        return
    end
    if diff == 1 then
        turtle.turnRight()
        M.rotation = M.rotation + 1
    elseif diff == 3 then
        turtle.turnLeft()
        M.rotation = M.rotation - 1
    elseif diff == 2 then
        turtle.turnRight()
        M.rotation = M.rotation + 1
        M.rotation = M.rotation % 4
        updateWorldForward()

        turtle.turnRight()
        M.rotation = M.rotation + 1
    end
    M.rotation = M.rotation % 4
    updateWorldForward()
end

local function dig(move, digDir)
    digDir = digDir or turtle.dig
    return function()
        turnToRot(move.rot)
        if world.get(M.position + move) == 'air' then
            return
        end
        local didDig = digDir()
        if didDig then
            world.update(M.position + move, false)
        end
    end
end
M.east.dig = dig(M.east)
M.south.dig = dig(M.south)
M.west.dig = dig(M.west)
M.north.dig = dig(M.north)
M.up.dig = dig(M.up, turtle.digUp)
M.down.dig = dig(M.down, turtle.digDown)

local function executeHorizontalMove(move)
    return function()
        if not (math.abs(move.rot - M.rotation) == 2 and turtle.back()) then
            move.dig()
            if not turtle.forward() then
                return false
            end
        end
        M.position = M.position + move
        updateWorldAfterHorizontalMove()
        return true
    end
end
M.east.move = executeHorizontalMove(M.east)
M.south.move = executeHorizontalMove(M.south)
M.west.move = executeHorizontalMove(M.west)
M.north.move = executeHorizontalMove(M.north)
M.up.move = function()
    turtle.digUp()
    if not turtle.up() then
        return false
    end
    M.position = M.position + M.up
    updateWorldAtPosition()
    updateWorldUp()
    updateWorldForward()
    return true
end
M.down.move = function()
    turtle.digDown()
    if not turtle.down() then
        return false
    end
    M.position = M.position + M.down
    updateWorldAtPosition()
    updateWorldDown()
    updateWorldForward()
    return true
end

local function placeHorizontal(move)
    return function()
        turnToRot(move.rot)
        turtle.place()
        updateWorldForward()
    end
end
M.east.place = placeHorizontal(M.east)
M.south.place = placeHorizontal(M.south)
M.west.place = placeHorizontal(M.west)
M.north.place = placeHorizontal(M.north)
M.up.place = function()
    turtle.placeUp()
    updateWorldUp()
end
M.down.place = function()
    turtle.placeDown()
    updateWorldDown()
end

local function getDir(rotationDelta)
    return function ()
        return M.rotToMove[(M.rotation + rotationDelta) % 4]
    end
end
M.getForward = getDir(0)
M.getRight = getDir(1)
M.getBackward = getDir(2)
M.getLeft = getDir(3)

function M.init(position, rotation)
    M.position = position
    print('rotation', rotation)
    M.rotation = rotation
    updateWorldAtPosition()
    updateWorldForward()
    updateWorldUp()
    updateWorldDown()
end

return M
