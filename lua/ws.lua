local label = os.getComputerLabel()

local ws = assert(http.websocket('wss://t.alb1.hu/ws?label=' .. label))
while true do
    local msg, isBinary = ws.receive()
    print(msg)
end
ws.close()
