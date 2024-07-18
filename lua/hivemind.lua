local events = require'eventLoop'.events
local async = require'async'
local log = require'log'
local status = require'status'

local M = {}

local ws

local _turtleId
local _worldId
local _dimensionId
local _jobsUpdate

local function retryBackoff(func)
    for i = 1, 8 do
        local res, err = func()
        if res then
            return res
        end
        log('hm: failed to connect, retrying in', 3 ^ i, 's, err:', err)
        async.sleep(3 ^ i)
    end
end

local function connect()
    ws = assert(retryBackoff(function()
        return async.websocket(
            'wss://t.alb1.hu/ws?turtleId=' .. _turtleId .. '&worldId=' .. _worldId .. '&dimensionId=' .. _dimensionId
        )
    end))
    os.queueEvent(events.hivemind_connected)
    status.update(1)
end

function M.init(turtleId, worldId, dimensionId, jobsUpdate)
    _turtleId = assert(turtleId)
    _worldId = assert(worldId)
    _dimensionId = assert(dimensionId)
    _jobsUpdate = assert(jobsUpdate)
end

-- listen for job update or websocket closed messages
function M.run()
    connect()
    while true do
        local eventName, url, contentOrCloseReason, isBinaryOrCloseCode = coroutine.yield{events.websocket_closed, events.websocket_message}
        if eventName == events.websocket_closed then
            ws = nil
            local closeReason = contentOrCloseReason
            local closeCode = isBinaryOrCloseCode
            log('WS closed:', closeReason, closeCode)
            connect()
        else
            local content = contentOrCloseReason
            local isBinary = isBinaryOrCloseCode
            log('received WS message:', content)
            _jobsUpdate(content)
        end
    end
end

function M.send(type, data)
    local message = {
        type = type,
        data = data
    }
    message = textutils.serializeJSON(message)
    for i = 1, 5 do
        if not ws then
            os.pullEvent(events.hivemind_connected)
        end
        local ok = pcall(function()
            ws.send(message)
        end)
        if ok then
            return
        end
        log('hm.send: retrying sending, i = ', i)
    end
end

local function httpRequest(method, path, data)
    local url = 'https://t.alb1.hu' .. path
    local body
    if data ~= nil then
        body = textutils.serialiseJSON(data)
    end

    for i = 1, 5 do
        -- ensure the server is up and knows about the turtle
        if not ws then
            os.pullEvent(events.hivemind_connected)
        end

        local ok, responseOrError, errResponse = async.httpRequest{
            method = method,
            url = url,
            body = body,
            headers = {
                worldId = _worldId,
                turtleId = tostring(_turtleId),
                dimensionId = tostring(_dimensionId),
            }
        }
        if ok then
            local readOk, jsonOrErr = pcall(function()
                local json = responseOrError.readAll()
                return json
            end)
            if not readOk then
                log('failed to read response: ' .. jsonOrErr)
                return
            end
            local res = textutils.unserialiseJSON(jsonOrErr)
            responseOrError.close()
            return res
        end

        log('http request failed:', responseOrError, '\n response:', errResponse)
        log('retrying in', i ^ 2, 's')
        async.sleep(i ^ 2)
    end
    error'http request failed after 5 retries'
end

---@param start {x: integer, y: integer, z: integer}
---@param target {x: integer, y: integer, z: integer}
---@return string[]|nil
function M.getPath(start, target)
    assert(start.x and start.y and start.z, 'invalid start: ' .. textutils.serialise(start))
    assert(target.x and target.y and target.z, 'invalid target: ' .. textutils.serialise(target))
    local moves = httpRequest('POST', '/path', {start = start, ['end'] = target}) -- (list of string) or nil
    return moves
end

function M.getLavaPool(x, y, z)
    local path = ('/lavaPool?x=%d&y=%d&z=%d'):format(x, y, z)
    log('path', path)
    local blocks = httpRequest('GET', path)
    ---@cast blocks {coordinates: Vec, id: string}[]
    return blocks
end

---@param updates {coordinates: {x: integer, y: integer, z: integer}, id: string, lastUpdate: integer}[]
function M.updateWorld(updates)
    if #updates == 0 then return end
    httpRequest('POST', '/updateWorld', updates)
end

return M
