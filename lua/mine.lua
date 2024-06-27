require'inventory'
local move = require'move'

local function check(inspect, dig)
    local has_block, data = inspect()
    if has_block then
        if string.find(data.name, 'iron') or string.find(data.name, 'diamond') then
            dig()
        end
    end
end

local function execute(moveExecute)
    moveExecute()
    check(turtle.inspect, turtle.dig)
    check(turtle.inspectUp, turtle.digUp)
    check(turtle.inspectDown, turtle.digDown)
    return Inventory.isFull() or turtle.getFuelLevel() < 1000
end

local length = 100

local function getNextMove(x, z)
    local evenRow = z % 2 == 0
    if (evenRow and x == length) or (not evenRow and x == 1) then
        return move.moves.south
    end
    if evenRow then
        return move.moves.east
    end
    return move.moves.west
end

local function mine()
    repeat
        local pos = move.getPos()
        local nextMove = getNextMove(pos[1], pos[3])
        move.turnToRot(nextMove.rot)
        check(turtle.inspect, turtle.dig)
    until execute(nextMove.execute)
end

local function loadStart()
    if not fs.exists'mine.dat' then
        return {3, -3, 0}
    end

    local f = fs.open('mine.dat', 'r')
    local start = textutils.unserialize(f.readAll())
    f.close()
    return {start.x, -3, start.z}
end

local function saveStart()
    local f = fs.open('mine.dat', 'w')
    local pos = move.getPos()
    local start = {x = pos[1], z = pos[3]}
    f.write(textutils.serialize(start))
    f.close()
end

local function main()
    turtle.select(1)

    for i = 1, 3 do move.east() end
    for i = 1, 3 do move.down() end
    move.goTo(loadStart())
    Try(mine)
    saveStart()

    Inventory.dropAll()
end

local function main2()
    for i = 1, 1 do
        main()
    end
end

return {run = main2}
