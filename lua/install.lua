--[[
wget run https://t.alb1.hu en9
]]

local tasks = {}

local function install(name)
    table.insert(tasks, function()
        local response, _, errResponse = http.get('https://t.alb1.hu/' .. name .. '.lua')
        if response then
            local text = response.readAll()
            response.close()
            local file = fs.open(name .. '.lua', 'w')
            file.write(text)
            file.close()
            print('Installed', name)
        else
            local code, message = errResponse.getResponseCode()
            errResponse.close()

            if code == 404 then
                print('Not found', name)
                fs.delete(name .. '.lua')
            else
                error('Failed to download ' .. name .. '.lua: ' .. tostring(code) .. ' ' .. message)
            end
        end
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

install'async'
install'config'
install'dimension'
install'eventLoop'
install'file'
install'hivemind'
install'inventory'
install'jobs'
install'lava'
install'log'
install'main'
install'mine'
install'move'
install'moveGps'
install'path'
install'queue'
install'rotationHelper'
install'status'
install'startup'
install'vec'
install'vecStoreXyzArr'
install'world'
install'worldHm'
parallel.waitForAll(table.unpack(tasks))

print()

shell.run'main'