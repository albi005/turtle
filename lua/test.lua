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

