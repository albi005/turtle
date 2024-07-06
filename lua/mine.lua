require'inventory'
local move = require'moveGps'
local config = require'config'
local path = require'path'
local Vec = require'vec'
local inventory = require'inventory'
local world = require'worldHm'

local COL_COUNT = 100
local TARGETS = {'iron', 'diamond', 'emerald', 'gold', 'redstone', 'lapis', 'coal'}

local M = {}

local moveForward
local moveBackward
local moveNextRow
local state = {basePos = {0, 0, 0}, resumePos = {0, 0, 0}, direction = 0}

local function check(mov)
    local block = world.get(move.position + mov)
    if block ~= 'air' then
        for _, target in ipairs(TARGETS) do
            if block:find(target) then
                mov.dig()
                return
            end
        end
    end
end

local function getNextMove(col, row)
    local evenRow = row % 2 == 0
    if (evenRow and col == COL_COUNT) or (not evenRow and col == 1) then
        return moveNextRow
    end
    if evenRow then
        return moveForward
    end
    return moveBackward
end

function M.run()
    while true do
        state = config.load'mine'
        if not state then
            state = {}
            state.basePos = move.position
            state.direction = move.rotation
            state.resumePos = move.position
            config.save('mine', state)
        end
        state.basePos = Vec.new(state.basePos)
        state.resumePos = Vec.new(state.resumePos)
        moveForward = move.rotToMove[state.direction]
        moveBackward = move.rotToMove[(state.direction + 2) % 4]
        moveNextRow = move.rotToMove[(state.direction + 1) % 4]

        path.goTo(state.base)
        move.turnToRot(state.direction + 2)
        inventory.dropAllExcept()
        turtle.select(1)

        path.goTo(state.resumePos)

        while not inventory.unsafeIsFull() and turtle.getFuelLevel() > 1000 do
            check(move.up)
            check(move.down)
            local fromBase = move.position - state.basePos
            local nextMove = getNextMove(fromBase[1], fromBase[3])
            nextMove.move()
            check(move.getForward())

            state.resumePos = move.position
            config.save('mine', state)
            coroutine.yield() -- can be stopped by here
        end
    end
end

return M
