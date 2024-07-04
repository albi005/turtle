-- 
local Store = {}

function Store:new()
    local store = {}
    setmetatable(store, self)
    self.__index = self
    return store
end

function Store:set(vec, value)
    self[tostring(vec)] = value
end

function Store:get(vec)
    return self[tostring(vec)]
end

return Store