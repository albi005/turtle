local dimension = require'dimension'
local hivemind = require'hivemind'
local file = require'file'
local rotationHelper = require'rotationHelper'
local task = require'task'
local world = require'worldHm'

local worldId = file.read'worldId.txt'
local dimensionId = dimension.getId()
local turtleId = os.getComputerID()
os.setComputerLabel(tostring(turtleId))
local position = vector.new(gps.locate())
local rotation = rotationHelper.getRotation(position)

hivemind.init(turtleId, worldId, dimensionId)

print('worldId', worldId)
print('dimensionId', dimensionId)
print('turtleId', turtleId)
print('position', position)
print('rotation', rotation)

world.upload()

local taskRunCoroutine = coroutine.create(task.run)
while true do
    local nextTaskId = hivemind.getTask(0)
    if nextTaskId then task.update(nextTaskId) end
    local _, waitFor = coroutine.resume(taskRunCoroutine)

    if waitFor then
        local events = {}
        if type(waitFor) == 'string' then
            events[waitFor] = true
        else
            for _, eventName in ipairs(waitFor) do
                events[eventName] = true
            end
        end
        events[task.events.websocket_message] = true
        while true do
            local event = {os.pullEvent()}
            local eventName = event[1]
            if events[eventName] then
                if event[1] == task.events.websocket_message then
                    nextTaskId = event[3]
                    if nextTaskId then task.update(nextTaskId) end
                end
                break
            end
        end
    end
end
