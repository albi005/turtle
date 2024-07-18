require'queue'
local move = require'moveGps'
local inventory = require'inventory'
local hivemind = require'hivemind'
local world = require'worldHm'
local config = require'config'
local Vec = require'vec'
local VecStore = require'vecStore'
local log = require'log'
local path = require'path'

local M = {}

local moveForward ---@type Move -- as compared to the starting direction
local moveBackward ---@type Move
local moveRight ---@type Move
local moveLeft ---@type Move
local firstBlock ---@type Vec -- base + fw + down, first block in the pool
---@type {basePos: Vec, direction: integer}
local state = {}

local function saveState()
    config.save('lava', {
        basePos = Vec:new(state.basePos),
        direction = state.direction,
    })
end

local function loadState()
    state = config.load'lava' or {
        basePos = move.position,
        direction = move.rotation,
    }
    state.basePos = Vec:new(state.basePos)
    moveForward = move.rotToMove[state.direction]
    moveBackward = move.rotToMove[(state.direction + 2) % 4]
    moveRight = move.rotToMove[(state.direction + 1) % 4]
    moveLeft = move.rotToMove[(state.direction + 3) % 4]
    firstBlock = state.basePos + moveForward + move.down
    saveState()
    log('loaded state', state)
end

local function assertInventoryEmpty()
    for i = 1, 16 do
        assert(turtle.getItemCount(i) == 0, 'Inventory not empty')
    end
end

local function assertOnlyLava()
    for i = 1, 16 do
        if turtle.getItemCount(i) > 0 then
            assert(turtle.getItemDetail(i).name == 'minecraft:lava_bucket', 'Not only lava buckets')
        end
    end
end

local dirs = {
    move.down,
    move.east,
    move.south,
    move.west,
    move.north,
    move.up
}

---@return Vec
local function getClosestTarget(start, prevMoves)
    local queue = Queue:new()
    queue:push(start)

    local maxY = firstBlock[2] ---@type integer

    while not queue:empty() do
        local current = queue:pop() ---@type Vec

        for _, nextMove in ipairs(dirs) do
            local next = current + nextMove ---@type Vec
            if next[2] <= maxY and not prevMoves:get(next) then
                prevMoves:set(next, nextMove)

                local nextBlock = world.get(next)
                if nextBlock == nil or nextBlock == 'minecraft:lava' then
                    return next                -- found an unknown block or lava, return its coordinates
                elseif nextBlock == 'air' then -- only check around air/flowing lava
                    queue:push(next)
                end
            end
        end
    end

    error'Ran out of lava'
end

local function getTasks()
    local start = move.position
    local prevMoves = VecStore:new()
    local target = getClosestTarget(start, prevMoves)

    local reversed = {} ---@type Move[]
    local curr = target
    while curr ~= start do
        local prevMove = prevMoves:get(curr)
        table.insert(reversed, prevMove)
        curr = curr + prevMove.inv
    end

    local tasks = {} ---@type function[]
    local n = #reversed
    for i = n, 1, -1 do
        table.insert(tasks, reversed[i].move)
    end

    local targetType = world.get(target)
    if targetType == 'minecraft:lava' then
        log('n', n, 'place')
        tasks[n] = reversed[1].place
    else
        log('n', n, 'inspect')
        tasks[n] = reversed[1].inspect
    end

    return tasks
end

function M.run()
    loadState()
    world.upload()
    log('firstBlock', firstBlock)
    world.downloadLavaPool(firstBlock)

    if world.get(firstBlock) == nil then
        log('firstBlock unknown')
        moveForward.move()
    end

    while true do
        while inventory.containsBuckets() do
            local tasks = getTasks()
            for _, task in ipairs(tasks) do
                task()
                coroutine.yield()
            end
        end

        path.goTo(state.basePos)
        moveRight.move()
        move.turnToRot(state.direction + 2)
        inventory.dropAllExcept()
        moveLeft.move()
        move.turnToRot(state.direction + 2)
        inventory.ensureBuckets()
        moveForward.move()
        move.down.move()
    end
end

function M.stop()
    --TODO: lava.stop()
end

return M
