local function dbg(value)
  local pretty = require "cc.pretty"
  print(pretty.pretty(value))
  return value
end

local move = require "move"

local function main()
  move.up()
  move.right()
  for i = 1, 30 do
    move.fw()
  end
  print(turtle.inspect())
end

local suc, ret = pcall(main)
if not suc then
  print(ret)
end
move.home()

-- local state = false
-- local i = 0
-- while true do
--   while redstone.getAnalogInput("left") == state do
--     print(i)
--     i = i + 1
--     os.pullEvent("redstone")
--   end
--   state = redstone.getAnalogInput("left")
--   redstone.setOutput("right", true)
--   sleep(1)
--   redstone.setOutput("right", false)
-- end
