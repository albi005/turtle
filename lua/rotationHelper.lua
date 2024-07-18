local Vec = require'vec'

local rotationHelper = {}

local deltaToRotation = {
    [Vec:new{1, 0, 0}] = 0,
    [Vec:new{0, 0, 1}] = 1,
    [Vec:new{-1, 0, 0}] = 2,
    [Vec:new{0, 0, -1}] = 3
}

function rotationHelper.getRotation(startPosition)
    if turtle.getFuelLevel() < 100 then error'No fuel' end
    for tries = 0, 3 do
        if turtle.forward() then
            local pos = Vec:new{gps.locate()}
            local delta = pos - startPosition
            local rotation
            for k, v in pairs(deltaToRotation) do
                if k == delta then
                    rotation = v
                    break
                end
            end
            turtle.back()
            for _ = 1, tries do
                turtle.turnLeft()
                rotation = rotation - 1
            end
            return rotation % 4
        end
        turtle.turnRight()
    end

    -- blocked on all sides
    turtle.dig()
    if not turtle.forward() then
        error"couldn't determine position"
    end
    local pos = Vec:new{gps.locate()}
    local delta = pos - startPosition
    for k, r in pairs(deltaToRotation) do
        if k == delta then
            turtle.back()
            return r
        end
    end
end

return rotationHelper
