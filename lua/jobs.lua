local file = require'file'
local move = require'moveGps'
local events = require'eventLoop'.events
local log = require'log'
local config = require'config'
local async = require'async'
local status = require'status'

local M = {}

local jobs = {
    -- lava = require'lava',
    mine = require'mine',
    standBy = {
        run = function() coroutine.yield(events.new_job) end,
        stop = function() end
    },
    north = {run = function() move.north.move() status.update(.5) end},
    east = {run = function() move.east.move() status.update(.5) end},
    west = {run = function() move.west.move() status.update(.5) end},
    south = {run = function() move.south.move() status.update(.5) end},
    up = {run = function() move.up.move() status.update(.5) end},
    down = {run = function() move.down.move() status.update(.5) end},
    reboot = {run = function() async.reboot() end},
}

local storedState = config.load'jobs' or {}
local currentJobId = storedState.currentJob
local nextJobId = storedState.nextJob

local function saveJobState()
    local current = currentJobId
    if current == 'reboot' then
        current = nil
    end
    config.save('jobs', {
        currentJob = current,
        nextJob = nextJobId
    })
end

function M.run()
    status.updateJobs(currentJobId, nextJobId)

    while true do
        local currentJob = jobs[currentJobId] or jobs.standBy

        local currentJobCoroutine = coroutine.create(currentJob.run)

        local event = {}

        repeat
            local ok, waitFor, timerId = coroutine.resume(currentJobCoroutine, table.unpack(event)) -- progress current job
            if not ok then
                error(waitFor .. debug.traceback(currentJobCoroutine))
            end
            event = {coroutine.yield(waitFor, timerId)}
            -- couroutine.yield without arguments means the job can be stopped so we can switch to the next job
        until (nextJobId and not waitFor) or coroutine.status(currentJobCoroutine) == 'dead'

        if currentJob.stop then
            currentJob.stop()
        end

        -- the next job might have changed
        coroutine.yield()

        log('switching job from', currentJobId, 'to', nextJobId)
        currentJobId = nextJobId
        nextJobId = nil
        saveJobState()
        status.updateJobs(currentJobId, nextJobId)
    end
end

function M.update(jobId)
    nextJobId = jobId
    if nextJobId == currentJobId then
        nextJobId = nil
    end
    saveJobState()
    status.updateJobs(currentJobId, nextJobId)
    os.queueEvent(events.new_job)
end

return M
