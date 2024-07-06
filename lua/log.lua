local M = {}

function M.log(...)
    local args = {...}
    for i = 1, #args do
        args[i] = tostring(args[i])
    end
    local str = table.concat(args, ' ')
    print(str)
    local file = fs.open('log.txt', 'a')
    file.writeLine(str)
    file.close()
end

return M