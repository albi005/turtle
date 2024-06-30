local file = require'file'

local task = {}

local tasks = {
    lava = require'lava',
    mine = require'mine',
    standBy = {
        run = function() coroutine.yield(task.events.websocket_message) end,
        stop = function() end
    },
    left = {run = function() coroutine.wrap(turtle.turnLeft)() end},
    up = {run = function() coroutine.wrap(turtle.up)() end},
    down = {run = function() coroutine.wrap(turtle.down)() end},
    right = {run = function() coroutine.wrap(turtle.turnRight)() end},
}

local storedState = textutils.unserialise(file.read'task.txt' or '{}')
local currentTaskId = storedState.currentTask
local nextTaskId = storedState.nextTask

local function saveTaskState()
    file.write('task.txt', textutils.serialise{
        currentTask = currentTaskId,
        nextTask = nextTaskId
    })
end

function task.run()
    while true do
        local currentTask = tasks[currentTaskId] or tasks.standBy

        local currentTaskCoroutine = coroutine.create(currentTask.run)

        repeat
            print('running task', currentTaskId or 'nil')
            local _, waitFor = coroutine.resume(currentTaskCoroutine) -- progress current task
            print('waiting for', waitFor or 'nil')
            coroutine.yield(waitFor)
        until nextTaskId or coroutine.status(currentTaskCoroutine) == 'dead'

        if currentTask.stop then
            currentTask.stop()
        end

        -- the next task might have changed
        coroutine.yield()

        print('switching task from', currentTaskId or 'nil', 'to', nextTaskId or 'nil')
        currentTaskId = nextTaskId
        nextTaskId = nil
        saveTaskState()
    end
end

function task.update(taskId)
    nextTaskId = taskId
    if nextTaskId == currentTaskId then
        nextTaskId = nil
    end
    saveTaskState()
end

task.events = {
    disk = 'disk',
    disk_eject = 'disk_eject',
    file_transfer = 'file_transfer',
    http_check = 'http_check',
    http_failure = 'http_failure',
    http_success = 'http_success',
    rednet_message = 'rednet_message',
    redstone = 'redstone',
    timer = 'timer',
    turtle_inventory = 'turtle_inventory',
    websocket_closed = 'websocket_closed',
    websocket_failure = 'websocket_failure',
    websocket_message = 'websocket_message',
    websocket_success = 'websocket_success',
}

return task
