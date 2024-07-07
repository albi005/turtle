local file = require'file'
local move = require'moveGps'
local events = require'eventLoop'.events
local log = require'log'
local config = require'config'
local async = require'async'

local M = {}

local jobs = {
    -- lava = require'lava',
    mine = require'mine',
    standBy = {
        run = function() coroutine.yield(events.new_job) end,
        stop = function() end
    },
    north = {run = function() move.north.move() end},
    east = {run = function() move.east.move() end},
    west = {run = function() move.west.move() end},
    south = {run = function() move.south.move() end},
    up = {run = function() move.up.move() end},
    down = {run = function() move.down.move() end},
    reboot = {run = function() async.reboot() end},
}

local storedState = config.load'jobs' or {}
local currentJobId = storedState.currentTask
local nextTaskId = storedState.nextTask

local function saveTaskState()
    local current = currentJobId
    if current == 'reboot' then
        current = nil
    end
    config.save('jobs', {
        currentTask = current,
        nextTask = nextTaskId
    })
end

function M.run()
    while true do
        local currentTask = jobs[currentJobId] or jobs.standBy

        local currentTaskCoroutine = coroutine.create(currentTask.run)

        local event = {}

        repeat
            log('jobs: resuming task ', currentJobId or 'nil')
            local ok, waitFor, timerId = coroutine.resume(currentTaskCoroutine, table.unpack(event)) -- progress current task
            if not ok then
                error(waitFor .. debug.traceback(currentTaskCoroutine))
            end
            log('jobs: waiting for ', waitFor or 'nil')
            event = {coroutine.yield(waitFor, timerId)}
            -- couroutine.yield without arguments means the task can be stopped so we can switch to the next task
        until (nextTaskId and not waitFor) or coroutine.status(currentTaskCoroutine) == 'dead'

        if currentTask.stop then
            currentTask.stop()
        end

        -- the next task might have changed
        coroutine.yield()

        log('switching task from ', currentJobId or 'nil', ' to ', nextTaskId or 'nil')
        currentJobId = nextTaskId
        nextTaskId = nil
        saveTaskState()
    end
end

function M.update(taskId)
    nextTaskId = taskId
    if nextTaskId == currentJobId then
        nextTaskId = nil
    end
    saveTaskState()
    os.queueEvent(events.new_job)
end

return M
