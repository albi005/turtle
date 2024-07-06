--[[
wget run https://t.alb1.hu en9
]]

local tasks = {}

local function install(name)
    fs.delete(name .. '.lua')
    table.insert(tasks, function()
        shell.run('wget https://t.alb1.hu/' .. name .. '.lua')
    end)
end

local function writeAll(fileName, text)
    local file = fs.open(fileName, 'w')
    file.write(text)
    file.close()
end

local tArgs = {...}

local worldId = tArgs[1]
if not fs.exists'worldId.txt' then
    if not worldId then
        error('worldId not set')
    end
    writeAll('worldId.txt', worldId)
end

install'startup'

install'async'
install'config'
install'dimension'
install'eventLoop'
install'file'
install'hivemind'
install'inventory'
install'jobs'
install'lava'
install'main'
install'mine'
install'move'
install'moveGps'
install'path'
install'queue'
install'rotationHelper'
install'vec'
install'vecStoreXyzArr'
install'world'
install'worldHm'
parallel.waitForAll(table.unpack(tasks))

print()

shell.run'main'