local world = {}

local store = require'vecStoreXyzArr':new()
local hivemind = require'hivemind'

local function getId(hasBlock, data)
    if not hasBlock then
        return 'air'
    end
    if (data.name == 'minecraft:water' or data.name == 'minecraft:lava') and data.state.level ~= 0 then
        return 'air'
    end
    return data.name
end

function world.update(coordinates, hasBlock, data)
    local lastUpdate = os.epoch'utc'
    local id = getId(hasBlock, data)

    local f = fs.open('worldUpdateQueue.txt', 'a')
    f.write(textutils.serialize({coordinates, id, lastUpdate}, {compact = true}) .. '\n')
    f.close()

    store:set(coordinates, {id, lastUpdate})
end

function world.upload()
    local updates = {}
    store:forEach(function(coordinates, data)
        table.insert(updates, {coordinates = {x = coordinates[1], y = coordinates[2], z = coordinates[3]}, id = data[1], lastUpdate = data[2]})
    end)

    hivemind.updateWorld(updates)
    store:clear()
end

do
    if fs.exists'worldUpdateQueue.txt' then
        local f = fs.open('worldUpdateQueue.txt', 'r')
        for line in f.readLine do
            local data = textutils.unserialize(line)
            store:set(data[1], {data[2], data[3]})
        end
        f.close()
    end
end

return world
