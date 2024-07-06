local events = require'eventLoop'.events
local async = require'async'

local hivemind = {}

local ws

local _turtleId
local _worldId
local _dimensionId
local _jobsUpdate

local function retryBackoff(func)
    for i = 1, 5 do
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
    print('connected')
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
    print('HELLO')
    connect()
    while true do
        local eventName, url, contentOrCloseReason, isBinaryOrCloseCode = coroutine.yield{events.websocket_closed, events.websocket_message}
        if eventName == events.websocket_closed then
            local closeReason = contentOrCloseReason
            local closeCode = isBinaryOrCloseCode
            print('websocket closed:', closeReason, closeCode)
            connect()
        else
            local content = contentOrCloseReason
            local isBinary = isBinaryOrCloseCode
            print('received message:', content)
            _jobsUpdate(content)
        end
    end
end

local function retrySend(func)
    for i = 1, 5 do
        local ok, res = pcall(func)
        if ok then
            return res
        end
        print('retrying sending, i =', i)
        os.pullEvent(events.hivemind_connected)
    end
end

local function send(type, data)
    local message = {
        type = type,
        data = data
    }
    message = textutils.serializeJSON(message)
    --print('sending message:', message)
    retrySend(function()
        ws.send(message)
    end)
end

---@param updates {coordinates: {x: integer, y: integer, z: integer}, id: string, lastUpdate: integer}[]
function hivemind.updateWorld(updates)
    if #updates == 0 then
        updates = textutils.empty_json_array
    end
    send('updateWorld', updates)
end

local function httpRequest(path, data)
    local url = 'https://t.alb1.hu' .. path
    local response = http.post(url, textutils.serializeJSON(data))
    if response then
        local res = textutils.unserialiseJSON(response.readAll())
        response.close()
        return res
    else
        return nil, 'http request failed'
    end
    
end

---@param start {x: integer, y: integer, z: integer}
---@param target {x: integer, y: integer, z: integer}
---@return string[]|nil
function hivemind.getPath(start, target)
    local moves = httpRequest('/path', {start = start, ['end'] = target}) -- (list of string) or nil
    return moves
end

return hivemind
