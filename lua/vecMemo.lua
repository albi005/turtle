-- vecs that are equal are the same object
local VecMemo = {}
VecMemo.__index = VecMemo

local vecMemo = setmetatable({}, {__mode = 'v'})

function VecMemo.new(vec)
    if not vec[1] then
        print(debug.traceback())
    end
    local key = VecMemo.__tostring(vec)
    if vecMemo[key] then
        return vecMemo[key]
    end
    local instance = {vec[1], vec[2], vec[3]}
    setmetatable(instance, VecMemo)
    vecMemo[key] = instance
    return instance
end

function VecMemo:__tostring()
    return string.format('%d,%d,%d', self[1], self[2], self[3])
end

function VecMemo:__add(other)
    return VecMemo.new{self[1] + other[1], self[2] + other[2], self[3] + other[3]}
end

function VecMemo:__sub(other)
    return VecMemo.new{self[1] - other[1], self[2] - other[2], self[3] - other[3]}
end

function VecMemo:__eq(other)
    return self[1] == other[1] and self[2] == other[2] and self[3] == other[3]
end

return VecMemo