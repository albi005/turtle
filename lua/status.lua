local events = require'eventLoop'.events
local log = require'log'

local M = {
    currentJob = nil,
    nextJob = nil,
    fuelLevel = nil,
    fuelLimit = nil,
    position = nil,
}

---@type function
local _hmSend

local lastUpdate = 0.0
local timerId
local timerLen
local eventLoopRunning = false

local function getTimeSeconds()
    local gameMillis = os.epoch'ingame'
    local realSeconds = gameMillis / 72000
    return realSeconds
end

local function send()
    M.fuelLevel = turtle.getFuelLevel()
    M.fuelLimit = turtle.getFuelLimit()

    local msg = {
        currentJob = M.currentJob,
        nextJob = M.nextJob,
        fuelLevel = M.fuelLevel,
        fuelLimit = M.fuelLimit,
        position = M.position,
    }

    _hmSend('status', msg)
end

function M.update(cooldown)
    -- stuff in main before the event loop can eat our timer
    if not eventLoopRunning then return end

    if timerId and timerLen <= cooldown then
        return
    end

    local secondsSinceLastUpdate = getTimeSeconds() - lastUpdate
    local len = math.max(cooldown - secondsSinceLastUpdate, 0.5)

    if timerId then
        os.cancelTimer(timerId)
    end

    timerId = os.startTimer(len)
    timerLen = len
end

---@param hmSend function
function M.init(hmSend)
    _hmSend = hmSend
end

function M.run()
    M.update(0)
    eventLoopRunning = true
    while true do
        repeat
            local _, id = coroutine.yield(events.timer)
        until id == timerId

        timerId = nil
        lastUpdate = getTimeSeconds()

        send()
    end
end

function M.updateJobs(current, next)
    M.currentJob = current
    M.nextJob = next
    M.update(.6)
end

---@param position {x: integer, y: integer, z: integer}
function M.updatePosition(position)
    M.position = position
    M.update(7)
end

return M
