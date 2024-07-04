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
    print('Time elapsed: '..(stop - start) / 1000 .. 's')
end

local function inspectAsync()
    coroutine.resume(coroutine.create(turtle.forward))
    coroutine.resume(coroutine.create(turtle.inspect))
    coroutine.resume(coroutine.create(turtle.inspectDown))
    coroutine.resume(coroutine.create(turtle.inspectUp))
    local res = ''
    res = res .. (textutils.serialize({os.pullEvent'turtle_response'}))
    res = res .. (textutils.serialize({os.pullEvent'turtle_response'}))
    res = res .. (textutils.serialize({os.pullEvent'turtle_response'}))
    res = res .. (textutils.serialize({os.pullEvent'turtle_response'}))
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

time(test6)