--[[
wget run http://t.alb1.hu/test.lua
]]

-- local f = fs.open("test.txt", "w")
-- f.write(textutils.serialize({turtle.inspect()}))
-- f.close()

-- local start = os.time('utc')

-- local f = fs.open('test.txt', 'w')
-- for _, value in ipairs{turtle.inspect, turtle.inspectDown, turtle.inspectUp} do
--     local co = coroutine.create(value)
--     coroutine.resume(co)
-- end
-- for i = 1, 3 do
--     f.write(textutils.serialize{os.pullEvent'turtle_response'})
-- end
-- f.close()

-- local stop = os.time('utc')
-- print('Time elapsed: '..(stop - start)..'s')

-- for i = 1, 50 do
--     -- coroutine.resume(coroutine.create(turtle.attack))
--     turtle.attack()
-- end

local function time(func)
    local start = os.epoch'utc'
    func()
    local stop = os.epoch'utc'
    print('Time elapsed: ' .. (stop - start) / 1000 .. 's')
end

local function inspectAsync()
    coroutine.resume(coroutine.create(turtle.forward))
    coroutine.resume(coroutine.create(turtle.inspect))
    coroutine.resume(coroutine.create(turtle.inspectDown))
    coroutine.resume(coroutine.create(turtle.inspectUp))
    local res = ''
    res = res .. (textutils.serialize{os.pullEvent'turtle_response'})
    res = res .. (textutils.serialize{os.pullEvent'turtle_response'})
    res = res .. (textutils.serialize{os.pullEvent'turtle_response'})
    res = res .. (textutils.serialize{os.pullEvent'turtle_response'})
    local f = fs.open('test.txt', 'w')
    f.write(res)
    f.close()
end

local function test1()
    for i = 1, 20 do
        inspectAsync()
    end
end

-- local function test2()
--     for i = 1, 20 do
--         turtle.forward() -- 7.6
--         turtle.inspect() -- 9
--         turtle.inspectDown() -- 10
--         turtle.inspectUp() -- 11
--     end
-- end

local function test3()
    for i = 1, 50 do
        turtle.inspect() -- 50 ms
    end
end
local function test4()
    for i = 1, 30 do
        turtle.back() -- 400 ms
    end
end
local function test5()
    for i = 1, 30 do
        turtle.forward() -- 400 ms
        turtle.inspect() -- 50 ms
    end
end
local function test6()
    for i = 1, 30 do
        turtle.dig() -- 50 ms
    end
end

local pretty = require'cc.pretty'

fs.delete'test.txt'
local function log(...)
    local text = tostring(pretty.pretty({...}, {function_args = true, function_source = true}))
    print(text)
    local f = fs.open('test.txt', 'a')
    f.write(text)
    f.write'\n'
    f.close()
end

local function extractEvent(f)
    local co = coroutine.create(f)
    log{coroutine.resume(co)}
    log{coroutine.resume(co)}
    log{coroutine.resume(co)}
end

-- extractEvent(turtle.back)
-- extractEvent(function() http.websocket'wss://t.alb1.hu/ws' end)
-- extractEvent(function() os.sleep(1) end)
-- extractEvent(function() os.startTimer(1) end)

-- coroutine.resume(coroutine.create(function()
--     http.websocket'wss://t.alb1.hu/ws'
-- end))

-- coroutine.resume(coroutine.create(function()
--     turtle.forward()
-- end))

-- coroutine.resume(coroutine.create(function()
--     os.startTimer(1)
-- end))

-- local ws = assert(http.websocket('wss://t.alb1.hu/ws?turtleId=' .. '1' .. '&worldId=' .. 'crea' .. '&dimendionId=' .. 'overworld'))
-- coroutine.resume(coroutine.create(function()
--     ws.send("hello")
-- end))
-- extractEvent(function() ws.send("hello") end)

-- while true do
--     log(os.pullEvent())
-- end

-- extractEvent(function()
--     os.pullEvent()
-- end)

-- local function tryGetEvent()
--     local co = coroutine.create(function()
--         local event = {os.pullEvent()}
--         return event
--     end)
--     extractEvent(function()
--         local event = {os.pullEvent()}
--         return event
--     end)
-- end

-- local co = coroutine.create(function()
--     return "hello"
-- end)


-- for i = 1, 10, 1 do
--     local co = coroutine.create(function()
--         local event = {os.pullEvent()}
--         log(event)
--     end)
--     while coroutine.status(co) ~= "dead" do
--         coroutine.resume(co)
--     end
-- end

-- local eventQueueState


-- coroutine.resume(coroutine.create(function()
--     turtle.forward()
-- end))
-- coroutine.resume(coroutine.create(function()
--     turtle.forward()
-- end))
-- coroutine.resume(coroutine.create(function()
--     turtle.forward()
-- end))

-- log(getEvents())

-- coroutine.resume(coroutine.create(function()
--     turtle.forward()
-- end))
-- coroutine.resume(coroutine.create(function()
--     turtle.forward()
-- end))
-- coroutine.resume(coroutine.create(function()
--     turtle.forward()
-- end))

-- local function getEvents()
--     local events = {}
--     os.queueEvent('HELLO')
--     while true do
--         local event = {os.pullEvent()}
--         local eventName = event[1]
--         if eventName == 'HELLO' then return events end
--         table.insert(events, event)
--     end
-- end

local ws = http.websocket 'wss://t.alb1.hu/ws?turtleId=1&worldId=crea&dimensionId=overworld'
ws.close()
local ok, res = pcall(function() ws.receive() end, debug.traceback)
log(res)