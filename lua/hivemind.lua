local hivemind = {}

local ws

function hivemind.init(turtleId, worldId, dimensionId)
    ws = assert(http.websocket('wss://t.alb1.hu/ws?turtleId=' .. turtleId .. '&worldId=' .. worldId .. '&dimendionId=' .. dimensionId))
end

function hivemind.getTask(timeout)
    local message = ws.receive(timeout)
    if message then print('received message:', message) end
    return message
end

local function send(type, data)
    local message = {
        type = type,
        data = data
    }
    message = textutils.serializeJSON(message)
    print('sending message:', message)
    ws.send(message)
end

local function sendStatus()
    local fuel = turtle.getFuelLevel()
    local x, y, z = gps.locate()
end

hivemind.getWs = function()
    return ws
end

---@param updates {coordinates: {x: integer, y: integer, z: integer}, id: string, lastUpdate: integer}[]
function hivemind.updateWorld(updates)
    if #updates == 0 then
        updates = textutils.empty_json_array
    end
    send('updateWorld', updates)
end

return hivemind