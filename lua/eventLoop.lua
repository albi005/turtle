require'queue'
local log = require'log'

local M = {}

M.events = {
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
    hivemind_connected = 'hivemind_connected',
    new_job = 'new_job',
}

-- returns a list of all events currently in the event queue and clears the event queue
local function getEvents()
    local events = {}
    os.queueEvent'AAAAAAAAAA'
    while true do
        local event = {os.pullEvent()}
        local eventName = event[1]
        if eventName == 'AAAAAAAAAA' then return events end
        table.insert(events, event)
    end
end

local queue = Queue:new()
--Dequeues an item from the event queue. Returns nil if the queue is empty and shouldWait is false
local function tryDequeueEvent(shouldWait)
    for _, value in ipairs(getEvents()) do
        queue:push(value)
    end

    if not queue:empty() then
        return queue:pop()
    end

    if shouldWait then
        return {os.pullEvent()}
    end

    return nil
end

function M.run(...)
    local tasks = {}
    local taskToIndex = {}

    for i, f in ipairs{...} do
        local task = {
            coroutine = coroutine.create(f),
            wait = nil,
        }
        table.insert(tasks, task)
        taskToIndex[task] = i
    end

    local waitIds = {}

    while true do
        local waitCount = 0

        -- run ready tasks
        for _, task in ipairs(tasks) do
            if not task.wait then
                local ok, res, waitId = coroutine.resume(task.coroutine, table.unpack(task.event or {}))
                task.event = nil

                if not ok then
                    error(res .. '\n' .. debug.traceback(task.coroutine))
                end

                local wait = res --  ["event"] | "event"
                if wait then
                    waitCount = waitCount + 1

                    task.wait = {}
                    if type(wait) == 'table' then
                        for _, event in ipairs(wait) do
                            task.wait[event] = true
                        end
                    elseif type(wait) == 'string' then
                        local event = wait
                        if waitId then
                            waitIds[waitId] = task
                        else
                            task.wait[event] = true
                        end
                    else
                        error'invalid wait'
                    end
                end
            else
                waitCount = waitCount + 1
            end
        end

        local event = tryDequeueEvent(waitCount == #tasks)
        if event then
            local eventName = event[1]

            local waitId = event[2]
            if waitId then
                local task = waitIds[waitId]
                if task then
                    task.wait = nil
                    task.event = event
                    waitIds[waitId] = nil
                end
            end

            for _, task in ipairs(tasks) do
                if task.wait and task.wait[eventName] then
                    task.wait = nil
                    task.event = event
                end
            end
        end
    end
end

return M
