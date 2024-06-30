local hivemind = {}

local ws

function hivemind.init(turtleId, worldId, dimensionId)
    ws = assert(http.websocket('wss://t.alb1.hu/ws?turtleId=' .. turtleId .. '&worldId=' .. worldId .. '&dimendionId=' .. dimensionId))
end

function hivemind.getTask(timeout)
    print('ws.receive', timeout or 'nil')
    local message = ws.receive(timeout)
    print('message', message or 'nil')
    return message
end

local function send(message)
    ws.send(textutils.serializeJSON(message))
end

local function sendStatus()
    local fuel = turtle.getFuelLevel()
    local x, y, z = gps.locate()
end

hivemind.getWs = function()
    return ws
end

return hivemind