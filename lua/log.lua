local pretty = require'cc.pretty'

local M = {}

local opts = {
    compact = true,
    allow_repetitions = true
}

fs.delete'log.txt'
fs.delete'_log'

local function asd(val)
    local t = type(val)
    if t == 'string' then
        return val
    elseif t == 'function' then
        return '*function*'
    elseif t == 'thread' then
        return '*thread*'
    elseif t == 'userdata' then
        return '*userdata*'
    elseif t == 'table' and val.inv then
        local vec = val
        val = {vec[1], vec[2], vec[3], rot = vec.rot}
    end
    print(t)
    return tostring(pretty.pretty(val, nil))
end

function M.log(...)
    local args = {...}
    for i = 1, #args do
        args[i] = asd(args[i])
    end
    local str = table.concat(args, ' ')
    print(str)

    if fs.getFreeSpace'/' < (fs.getCapacity'/' / 2) then
        fs.delete'_log'
    end
    local file = fs.open('_log', 'a')
    file.writeLine(str)
    file.close()
end

return M.log
