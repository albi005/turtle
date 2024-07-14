local pretty = require'cc.pretty'

local M = {}

local opts = {
    compact = true,
    allow_repetitions = true,
    function_args = true,
    function_source = true
}

fs.delete'log.txt'
fs.delete'_log'

local function serialize(val)
    local t = type(val)
    if val == nil then
        return 'nil'
    elseif t == 'string' then
        return val
    elseif t == 'nil' then
        return 'nil'
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
    return tostring(pretty.pretty(val, opts))
end

function M.log(...)
    local args = table.pack(...) -- {...} stops at nils
    for i = 1, args.n do
        args[i] = serialize(args[i])
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
