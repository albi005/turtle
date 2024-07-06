local Vec = {}
Vec.__index = Vec

function Vec.new(vec)
    if not vec[3] then
        error('Vec.new: invalid argument: ' .. textutils.serialise(vec))
    end
    local instance = {vec[1], vec[2], vec[3]}
    setmetatable(instance, Vec)
    return instance
end

function Vec:__tostring()
    return string.format('%d,%d,%d', self[1], self[2], self[3])
end

function Vec:__add(other)
    return Vec.new{self[1] + other[1], self[2] + other[2], self[3] + other[3]}
end

function Vec:__sub(other)
    return Vec.new{self[1] - other[1], self[2] - other[2], self[3] - other[3]}
end

function Vec:__eq(other)
    return self[1] == other[1] and self[2] == other[2] and self[3] == other[3]
end

function Vec:toVector()
    return vector.new(self[1], self[2], self[3])
end

return Vec