local log = require'log'

-- array stored in tables per dimension

---@class VecStore
local VecStore = {}

---@return VecStore
function VecStore:new()
    local store = {d = {}}
    setmetatable(store, self)
    self.__index = self
    return store
end

---@param vec Vec
---@param value any
function VecStore:set(vec, value)
    local x, y, z = vec[1], vec[2], vec[3]
    local d = self.d
    d[x] = d[x] or {}
    d[x][y] = d[x][y] or {}
    d[x][y][z] = value
end

---@param vec Vec
---@return any
function VecStore:get(vec)
    local x, y, z = vec[1], vec[2], vec[3]
    local d = self.d
    if d[x] and d[x][y] and d[x][y][z] then
        return d[x][y][z]
    end
    return nil
end

function VecStore:clear()
    self.d = {}
end

function VecStore:forEach(f)
    for x, yz in pairs(self.d) do
        for y, zv in pairs(yz) do
            for z, v in pairs(zv) do
                f({x, y, z}, v)
            end
        end
    end
end

return VecStore
