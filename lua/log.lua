local M = {}

local opts = {
    compact = true,
    allow_repetitions = true
}

fs.delete'log.txt'

function M.log(...)
    local args = {...}
    for i = 1, #args do
        if type(args[i]) == 'table' then
            if args[i].inv then
                args[i] = tostring(args[i])
            else
                args[i] = textutils.serialize(args[i], opts)
            end
        end
    end
    local str = table.concat(args)
    print(str)
    local file = fs.open('log.txt', 'a')
    file.writeLine(str)
    file.close()
end

return M.log
