local VecStore = require'vecStoreXyzArr'
local hivemind = require'hivemind'
local log = require'log'
local Vec = require'vec'

local M = {}

local worldCache = VecStore:new()
local updateStore = VecStore:new()
local dimensionId ---@type 0|1|2

---@param hasBlock boolean
---@param data {name: string, state: any}?
local function getId(hasBlock, data)
    if not hasBlock then
        return 'air'
    end
    ---@cast data -?
    if (data.name == 'minecraft:water' or data.name == 'minecraft:lava') and data.state.level ~= 0 then
        return 'air'
    end
    return data.name
end

local compact = {compact = true}

---@param coordinates Vec
---@param hasBlock boolean
---@param data {name: string, state: any}?
function M.update(coordinates, hasBlock, data)
    local lastUpdate = os.epoch'utc'
    local id = getId(hasBlock, data)

    local f = fs.open('worldUpdateQueue.txt', 'a')
    f.write(textutils.serialize({coordinates, id, lastUpdate, dimensionId}, compact) .. '\n')
    f.close()

    worldCache:set(coordinates, id)
    updateStore:set(coordinates, {id, lastUpdate, dimensionId})
end

---@return string?
function M.get(vec)
    return worldCache:get(vec)
end

local prevTimerId
local lastHivemindUpdate

local function resetTimer()
    if prevTimerId then
        os.cancelTimer(prevTimerId)
    end
    lastHivemindUpdate = os.epoch'utc'
    prevTimerId = os.startTimer(30)
end

function M.upload()
    resetTimer()

    local updates = {}
    updateStore:forEach(function(coordinates, data)
        table.insert(updates, {
            coordinates = {x = coordinates[1], y = coordinates[2], z = coordinates[3]},
            id = data[1],
            lastUpdate = data[2],
            dimensionId = data[3]
        })
    end)

    hivemind.updateWorld(updates)
    fs.delete'worldUpdateQueue.txt'
    updateStore:clear()
end

---@param start Vec
function M.downloadLavaPool(start)
    local lastUpdate = os.epoch'utc'
    local blocks = hivemind.getLavaPool(start[1], start[2], start[3])
    for _, block in pairs(blocks) do
        local coords = Vec.fromCcVector(block.coordinates)
        local id = block.id
        worldCache:set(coords, id)
    end
end

function M.init(_dimensionId)
    dimensionId = _dimensionId
end

function M.run()
    M.upload()
    while true do
        coroutine.yield'timer'
        if os.epoch'utc' - lastHivemindUpdate >= 25000 then
            M.upload()
        end
    end
end

do
    if fs.exists'worldUpdateQueue.txt' then
        local f = fs.open('worldUpdateQueue.txt', 'r')
        for line in f.readLine do
            local data = textutils.unserialize(line)
            worldCache:set(data[1], data[2])
            updateStore:set(data[1], {data[2], data[3], data[4]})
        end
        f.close()
    end
end

return M
