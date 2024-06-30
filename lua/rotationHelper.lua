local rotationHelper = {}

local deltaToRotation = {
    [vector.new(1, 0, 0)] = 0,
    [vector.new(0, 0, 1)] = 1,
    [vector.new(-1, 0, 0)] = 2,
    [vector.new(0, 0, -1)] = 3
}

function rotationHelper.getRotation(startPosition)
    for _ = 1, 4 do
        if turtle.forward() then
            local pos = vector.new(gps.locate())
            local delta = pos - startPosition
            local rotation
            for k, v in pairs(deltaToRotation) do
                if k == delta then
                    rotation = v
                    break
                end
            end
            turtle.back()
            return rotation
        end
        turtle.turnRight()
    end
end

return rotationHelper