local move = require'moveGps'
local config = require'config'
local path = require'path'
local Vec = require'vec'
local inventory = require'inventory'
local world = require'worldHm'
local log = require'log'

local COL_COUNT = 69
local TARGETS = {'iron', 'diamond', 'emerald', 'gold', 'redstone', 'lapis', 'coal'}

local M = {}

local moveForward
local moveBackward
local moveNextRow
local state = {basePos = {0, 0, 0}, resumePos = {0, 0, 0}, direction = 0}

local function check(mov)
    log('checking ', Vec.new(move.position) + mov)
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
    log('col ', col, 'row ', row)
    local evenRow = row % 2 == 0
    if (evenRow and col >= COL_COUNT) or (not evenRow and col == 0) then
        return moveNextRow
    end
    if evenRow then
        return moveForward
    end
    return moveBackward
end

local function saveState()
    config.save('mine', {
        basePos = Vec.new(state.basePos),
        resumePos = Vec.new(state.resumePos),
        direction = state.direction
    })
end

function M.stop()
    path.goTo(state.basePos)
    move.turnToRot(state.direction + 2)
    inventory.dropAllExcept()
end

local function getColAndRow()
    local fromBase = move.position - state.basePos
    if state.direction == 0 then
        return fromBase[1], fromBase[3]
    elseif state.direction == 1 then
        return fromBase[3], -fromBase[1]
    elseif state.direction == 2 then
        return -fromBase[1], -fromBase[3]
    else
        return -fromBase[3], fromBase[1]
    end
end

function M.run()
    state = config.load'mine'
    if not state then
        state = {}
        state.basePos = move.position
        state.direction = move.rotation
        state.resumePos = move.position
        saveState()
    end
    state.basePos = Vec.new(state.basePos)
    state.resumePos = Vec.new(state.resumePos)
    moveForward = move.rotToMove[state.direction]
    moveBackward = move.rotToMove[(state.direction + 2) % 4]
    moveNextRow = move.rotToMove[(state.direction + 1) % 4]
    while true do
        turtle.select(1)
        if not inventory.unsafeIsFull() and turtle.getFuelLevel() > 1000 then
            log('resuming mining at', state.resumePos, 'facing', state.direction)
            path.goTo(state.resumePos)
        end

        while not inventory.unsafeIsFull() and turtle.getFuelLevel() > 1000 do
            check(move.up)
            check(move.down)
            local nextMove = getNextMove(getColAndRow())
            nextMove.move()
            check(move.getForward())

            state.resumePos = move.position
            saveState()
            coroutine.yield() -- can be stopped by here
        end

        M.stop()

        if turtle.getFuelLevel() < 1000 then
            log'out of fuel'
            os.setComputerLabel'OUT OF FUEL'
            -- TODO: set status
            return
        end
    end
end

return M
