local events = require'eventLoop'.events
local async = require'async'
local log = require'log'

local hivemind = {}

local ws

local _turtleId
local _worldId
local _dimensionId
local _jobsUpdate

local function retryBackoff(func)
    for i = 1, 8 do
        print('connecting, i =', i)
        local res, err = func()
        if res then
            return res
        end
        print('failed to connect, retrying in', 3 ^ i, 's, err:', err)
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
end

function hivemind.init(turtleId, worldId, dimensionId, jobsUpdate)
    _turtleId = assert(turtleId)
    _worldId = assert(worldId)
    _dimensionId = assert(dimensionId)
    _jobsUpdate = assert(jobsUpdate)
end

-- listen for job update or websocket closed messages
function hivemind.run()
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

local function send(type, data)
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
        log('hivemind.send: retrying sending, i = ', i)
    end
end

---@param updates {coordinates: {x: integer, y: integer, z: integer}, id: string, lastUpdate: integer}[]
function hivemind.updateWorld(updates)
    if #updates == 0 then
        return
    end
    send('updateWorld', updates)
end

local function httpRequest(path, data)
    local url = 'https://t.alb1.hu' .. path
    data.turtleId = _turtleId
    data.worldId = _worldId
    local body = textutils.serialiseJSON(data)
    print('http request:', url, body)
    local ok, responseOrError, errResponse = async.httpRequest{
        method = 'POST',
        url = url,
        body = body,
    }
    if ok then
        local res = textutils.unserialiseJSON(responseOrError.readAll())
        print('http response:', textutils.serialise(res))
        responseOrError.close()
        return res
    else
        error('http request failed: ' .. responseOrError .. ', response: ' .. textutils.serialise(errResponse))
    end
end

---@param start {x: integer, y: integer, z: integer}
---@param target {x: integer, y: integer, z: integer}
---@return string[]|nil
function hivemind.getPath(start, target)
    assert(start.x and start.y and start.z, 'invalid start: ' .. textutils.serialise(start))
    assert(target.x and target.y and target.z, 'invalid target: ' .. textutils.serialise(target))
    local moves = httpRequest('/path', {start = start, ['end'] = target}) -- (list of string) or nil
    print('path:', textutils.serialise(moves))
    return moves
end

return hivemind
