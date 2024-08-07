-- cc.vector stored in tables per dimension

local Store = {}

function Store:new()
    local store = {d = {}}
    setmetatable(store, self)
    self.__index = self
    return store
end

function Store:set(vec, value)
    local x, y, z = vec.x, vec.y, vec.z
    local d = self.d
    d[x] = d[x] or {}
    d[x][y] = d[x][y] or {}
    d[x][y][z] = value
end

function Store:get(vec)
    local x, y, z = vec.x, vec.y, vec.z
    local d = self.d
    if d[x] and d[x][y] and d[x][y][z] then
        return d[x][y][z]
    end
    return nil
end

function Store:forEach(f)
    for x, yz in pairs(self.d) do
        for y, zv in pairs(yz) do
            for z, v in pairs(zv) do
                f(vector.new(x, y, z), v)
            end
        end
    end
end

return Store
