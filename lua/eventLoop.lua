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

function M.run(...)
    local tasks = {}

    for _, f in ipairs{...} do
        table.insert(tasks, {
            coroutine = coroutine.create(f),
            wait = nil,
        })
    end

    local waitCount = 0
    local timers = {}

    while true do
        -- run ready tasks
        for _, task in ipairs(tasks) do
            if not task.wait then
                local ok, res, timerId = coroutine.resume(task.coroutine, table.unpack(task.event or {}))
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
                        if event == 'timer' and timerId then
                            timers[timerId] = task
                        else
                            task.wait[event] = true
                        end
                    else
                        error'invalid wait'
                    end
                end
            end
        end

        local events = getEvents()

        for _, event in ipairs(events) do
            local eventName = event[1]
            print('event', eventName)
            if eventName == 'timer' then
                local timerId = event[2]
                local task = timers[timerId]
                if task then
                    task.wait = nil
                    task.event = event
                    waitCount = waitCount - 1
                    timers[timerId] = nil
                end
            end
            for _, task in ipairs(tasks) do
                if task.wait and task.wait[eventName] then
                    task.wait = nil
                    task.event = event
                    waitCount = waitCount - 1
                end
            end
        end
    end
end

return M
