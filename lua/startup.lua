--[[
wget run https://t.alb1.hu en9
]]

local function install(name)
    fs.delete(name .. '.lua')
    assert(shell.run('wget https://t.alb1.hu/' .. name .. '.lua'))
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

install'dimension'
install'file'
install'hivemind'
install'inventory'
install'lava'
install'main'
install'mine'
install'move'
install'queue'
install'rotationHelper'
install'startup'
install'task'
install'vec'
install'vecStoreXyzArr'
install'vector'
install'world'
install'worldHm'

print()

shell.run'main'