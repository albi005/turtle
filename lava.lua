require'queue'
local move = require'move'

local function assertInventoryEmpty()
    for i = 1, 16 do
        assert(turtle.getItemCount(i) == 0, 'Inventory not empty')
    end
end

local function assertOnlyLava()
    for i = 1, 16 do
        if turtle.getItemCount(i) > 0 then
            assert(turtle.getItemDetail(i).name == 'minecraft:lava_bucket', 'Not only lava buckets')
        end
    end
end

-- TODO: simplify getClosestLava
local function getClosestLava()
    local queue = Queue.new()
    queue:push(move.getPos())

    local visited = {}

    while not queue:empty() do
        local current = queue:pop()

        for _, nextMove in pairs(move.moves) do
            local next = current + nextMove
            if not visited[next] then
                visited[next] = true
                if World[next] == BlockTypes.empty then -- only check around air/flowing lava
                    queue:push(next)
                elseif World[next] == BlockTypes.lava then
                    return current, nextMove.place
                end
            end
        end
    end
end

local function getNextUnknown()
    local queue = Queue.new()
    queue:push(move.getPos())

    local visited = {}

    while not queue:empty() do
        local current = queue:pop()

        for _, nextMove in pairs(move.moves) do
            local next = current + nextMove
            if not visited[next] and next[2] < 0 then
                visited[next] = true
                if World[next] == BlockTypes.empty then -- only check around air/flowing lava
                    queue:push(next)
                elseif World[next] == nil then
                    return current, nextMove.rot
                end
            end
        end
    end
end

local function run()
    Inventory.pickUp()

    move.east()
    move.down()

    local count = 0
    while count < 16 do
        local prev, place = getClosestLava()
        if prev then
            print('Next lava at ' .. prev[1] .. ' ' .. prev[2] .. ' ' .. prev[3])
            move.goTo(prev)
            place()
            count = count + 1
        else
            local prev, rot = getNextUnknown()
            assert(prev, 'Lava lake empty')
            print('Next unknown at ' .. prev[1] .. ' ' .. prev[2] .. ' ' .. prev[3])
            move.goTo(prev)
            if rot then
                move.turnToRot(rot)
            end
        end
    end

    Inventory.dropAll()
end

return {run = run}
