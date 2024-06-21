Queue = {}

function Queue:new()
    local res = { first = 0, last = -1 }
    setmetatable(res, self)
    self.__index = self
    return res
end

function Queue:push(value)
    local last = self.last + 1
    self.last = last
    self[last] = value
end

function Queue:pop()
    local first = self.first
    if first > self.last then
        return nil
    end
    local value = self[first]
    self[first] = nil
    self.first = first + 1
    return value
end

function Queue:empty()
    return self.first > self.last
end
