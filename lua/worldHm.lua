local VecStore = require'vecStoreXyzArr'
local hivemind = require'hivemind'
local log = require'log'

local M = {}

local worldCache = VecStore:new()
local updateStore = VecStore:new()

local function getId(hasBlock, data)
    if not hasBlock then
        return 'air'
    end
    if (data.name == 'minecraft:water' or data.name == 'minecraft:lava') and data.state.level ~= 0 then
        return 'air'
    end
    return data.name
end

function M.update(coordinates, hasBlock, data)
    local lastUpdate = os.epoch'utc'
    local id = getId(hasBlock, data)

    local f = fs.open('worldUpdateQueue.txt', 'a')
    f.write(textutils.serialize({coordinates, id, lastUpdate}, {compact = true}) .. '\n')
    f.close()

    worldCache:set(coordinates, {id, lastUpdate})
    updateStore:set(coordinates, {id, lastUpdate})
end

function M.get(vec)
    local res = worldCache:get(vec)
    if not res then
        error('no data for ' .. tostring(vec))
    end
    return res[1]
end

local prevTimerId
local lastUpdate

local function resetTimer()
    if prevTimerId then
        os.cancelTimer(prevTimerId)
    end
    lastUpdate = os.epoch'utc'
    prevTimerId = os.startTimer(30)
end

function M.upload()
    resetTimer()

    local updates = {}
    updateStore:forEach(function(coordinates, data)
        table.insert(updates, {
            coordinates = {x = coordinates[1], y = coordinates[2], z = coordinates[3]},
            id = data[1],
            lastUpdate = data[2]
        })
    end)

    hivemind.updateWorld(updates)
    fs.delete'worldUpdateQueue.txt'
    updateStore:clear()
end

function M.run()
    M.upload()
    while true do
        coroutine.yield'timer'
        if os.epoch'utc' - lastUpdate >= 25000 then
            M.upload()
        end
    end
end

do
    if fs.exists'worldUpdateQueue.txt' then
        local f = fs.open('worldUpdateQueue.txt', 'r')
        for line in f.readLine do
            local data = textutils.unserialize(line)
            worldCache:set(data[1], {data[2], data[3]})
            updateStore:set(data[1], {data[2], data[3]})
        end
        f.close()
    end
end

return M
