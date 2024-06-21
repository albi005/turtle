Vec = {}

local vecMemo = setmetatable({}, { __mode = 'v' })

function Vec:new(vec)
    local key = vec[1] .. ',' .. vec[2] .. ',' .. vec[3]
    if vecMemo[key] then
        return vecMemo[key]
    end
    local res = { vec[1], vec[2], vec[3] }
    setmetatable(res, self)
    vecMemo[key] = res
    return res
end

function Vec:tostring()
    return self[1] .. ',' .. self[2] .. ',' .. self[3]
end

function Vec:__add(other)
    return Vec:new{ self[1] + other[1], self[2] + other[2], self[3] + other[3] }
end

function Vec:__sub(other)
    return Vec:new{ self[1] - other[1], self[2] - other[2], self[3] - other[3] }
end

function Vec:__eq(other)
    return self[1] == other[1] and self[2] == other[2] and self[3] == other[3]
end
