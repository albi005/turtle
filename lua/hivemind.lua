local hivemind = {}

local ws

function hivemind.init(turtleId, worldId, dimensionId)
    ws = assert(http.websocket('wss://t.alb1.hu/ws?turtleId=' .. turtleId .. '&worldId=' .. worldId .. '&dimendionId=' .. dimensionId))
end

function hivemind.getTask()
    local message = ws.receive(0)
    return message
end

local function send(message)
    ws.send(textutils.serializeJSON(message))
end

local function sendStatus()
    local fuel = turtle.getFuelLevel()
    local x, y, z = gps.locate()
end

return hivemind