-- dimension server and client, like gps

local dim = {}

CHANNEL_DIMENSION = 55551

local modem = peripheral.find'modem'

local function readAllText(fileName)
    local file = fs.open(fileName, 'r')
    local text = file.readAll()
    file.close()
    return text
end

function dim.host()
    local dimension = readAllText'dimension.txt'

    print()
    print('Serving dimension ' .. dimension)
    modem.open(CHANNEL_DIMENSION)
    local requestCount = 0
    while true do
        local event, side, senderChannel, replyChannel, message, senderDistance = os.pullEvent'modem_message'
        if senderChannel == CHANNEL_DIMENSION and message == 'locate' then
            requestCount = requestCount + 1
            print('request ' .. requestCount)
            modem.transmit(replyChannel, CHANNEL_DIMENSION, dimension)
        end
    end
end

local dimensions = {
    overworld = 0,
    nether = 1,
    ['end'] = 2
}

local function locate()
    modem.transmit(CHANNEL_DIMENSION, CHANNEL_DIMENSION, 'locate')
    modem.open(CHANNEL_DIMENSION)

    while true do
        local event, side, senderChannel, replyChannel, message, senderDistance = os.pullEvent'modem_message'
        if senderChannel == CHANNEL_DIMENSION and senderDistance and dimensions[message] then
            print('dimension is ' .. message)
            return message
        end
    end
end

local dimensionId

function dim.getId()
    if not dimensionId then
        dimensionId = dimensions[locate()]
    end
    return dimensionId
end

return dim
