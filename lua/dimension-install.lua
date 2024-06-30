--[[
wget run https://t.alb1.hu/dimension-install.lua overworld
wget run https://t.alb1.hu/dimendsion-install.lua nether
wget run https://t.alb1.hu/dimension-install.lua end
]]

local function install(name)
    fs.delete(name .. '.lua')
    shell.run('wget https://t.alb1.hu/' .. name .. '.lua')
end

local function writeAll(fileName, text)
    local file = fs.open(fileName, 'w')
    file.write(text)
    file.close()
end

local tArgs = {...}

local dimension = tArgs[1]
writeAll('dimension.txt', dimension)

install'dimension'

writeAll('startup.lua', 'require"dimension".host()')

shell.run'reboot'
