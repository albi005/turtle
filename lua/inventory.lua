local async = require'async'

local M = {}

function M.ensureBuckets()
    M.dropAllExcept()
    turtle.select(1)
    repeat
        local gotAny = turtle.suck(16 - turtle.getItemCount(1))
        async.sleep(1)
    until not gotAny or turtle.getItemCount(1) == 16
end

function M.containsBuckets()
    return M.getItemCount'minecraft:bucket' > 0
end

function M.dropAllExcept(except)
    for i = 1, 16 do
        local slot = turtle.getItemDetail(i)
        if slot and slot.name ~= except then
            turtle.select(i)
            turtle.drop()
        end
    end
end

function M.unsafeIsFull()
    return turtle.getItemCount(16) > 0
end

function M.isFull()
    for i = 1, 16 do
        if turtle.getItemCount(i) == 0 then
            return false
        end
    end
    return true
end

function M.isEmpty()
    for i = 1, 16 do
        if turtle.getItemCount(i) > 0 then
            return false
        end
    end
    return true
end

function M.getItemCount(name)
    local sum = 0
    for i = 1, 16 do
        local slot = turtle.getItemDetail(i)
        if slot and slot.name == name then
            sum = sum + slot.count
        end
    end
    return sum
end

-- local function getItemCount(list, name)
--     local sum = 0
--     local slots = {}
--     for slot, item in pairs(list) do
--         if item.name == name then
--             sum = sum + item.count
--             slots[slot] = item.count
--         end
--     end
--     return sum, slots
-- end

-- function M.getItemCount(chest, name)
--     return getItemCount(chest.list(), name)
-- end

-- function M.dropAllIntoExcept(chest, except)

-- end

-- function M.pickUpBuckets(chest)
--     assert(M.isEmpty(), 'inventory must be empty when picking up buckets')

--     local list = chest.list()
--     local sum, slots = getItemCount(list, 'minecraft:bucket')
--     if sum == 0 then
--         return 0
--     end

--     local remaining = 16
--     for slot, count in pairs(slots) do
--         local toPickUp = math.min(count, remaining)
--         chest.pullItems(slot, toPickUp, 1)
--         remaining = remaining - toPickUp
--         if remaining == 0 then
--             return 16
--         end
--     end
--     return 16 - remaining
-- end

return M
