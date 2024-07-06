local M = {}

fs.makeDir('config')

local function getPath(name)
    return 'config/' .. name
end

function M.load(name)
    if not fs.exists(getPath(name)) then
        return nil
    end
    local file = fs.open(getPath(name), 'r')
    local data = textutils.unserialize(file.readAll())
    file.close()
    return data
end

function M.save(name, data)
    if not data then
        fs.delete(getPath(name))
        return
    end

    local file = fs.open(getPath(name), 'w')
    file.write(textutils.serialize(data))
    file.close()
end

return M