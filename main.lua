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

local function dbg(value)
  local pretty = require "cc.pretty"
  print(pretty.pretty(value))
  return value
end

local function panic(message)
  print(message)
  error(message)
end

local Vec = {}
local vecMemo = setmetatable({}, { __mode = "v" })
function Vec:new(vec)
  local key = vec[1] .. "," .. vec[2] .. "," .. vec[3]
  if vecMemo[key] then
    return vecMemo[key]
  end
  local res = { vec[1], vec[2], vec[3] }
  setmetatable(res, self)
  vecMemo[key] = res
  return res
end

function Vec:tostring()
  return self[1] .. "," .. self[2] .. "," .. self[3]
end

function Vec:__add(other)
  return Vec:new({ self[1] + other[1], self[2] + other[2], self[3] + other[3] })
end

function Vec:__sub(other)
  return Vec:new({ self[1] - other[1], self[2] - other[2], self[3] - other[3] })
end

function Vec:__eq(other)
  return self[1] == other[1] and self[2] == other[2] and self[3] == other[3]
end

local Queue = {}
function Queue:new()
  local res = { first = 0, last = -1 }
  setmetatable(res, self)
  self.__index = self
  return res
end

function Queue:push(value)
  local last = self.last + 1
  self.last = last
  self[last] = value
end

function Queue:pop()
  local first = self.first
  if first > self.last then
    return nil
  end
  local value = self[first]
  self[first] = nil
  self.first = first + 1
  return value
end

function Queue:empty()
  return self.first > self.last
end

local t = {}
t.pos = Vec:new { 0, 0, 0 }
t.rot = 0
t.air = {}

local moves = {
  fw = { 1, 0, 0, rot = 0 },
  right = { 0, 0, 1, rot = 1 },
  bw = { -1, 0, 0, rot = 2 },
  left = { 0, 0, -1, rot = 3 },
  up = { 0, 1, 0 },
  down = { 0, -1, 0 },
}

local function turnToRot(rot)
  local diff = rot - t.rot
  if diff == 0 then
    return
  end
  if diff == 1 or diff == -3 then
    turtle.turnRight()
    t.rot = t.rot + 1
  elseif diff == -1 or diff == 3 then
    turtle.turnLeft()
    t.rot = t.rot - 1
  elseif diff == 2 or diff == -2 then
    turtle.turnRight()
    turtle.turnRight()
    t.rot = t.rot + 2
  else
    error("invalid rotation")
  end
  t.rot = t.rot % 4
end

local function executeHorizontalMove(move)
  return function()
    turnToRot(move.rot)
    turtle.dig()
    if not turtle.forward() then
      t.air[t.pos + move] = nil
      return false
    end
    t.pos = t.pos + move
    t.air[t.pos] = true
    return true
  end
end

moves.fw.execute = executeHorizontalMove(moves.fw)
moves.fw.inv = moves.bw
moves.right.execute = executeHorizontalMove(moves.right)
moves.right.inv = moves.left
moves.bw.execute = executeHorizontalMove(moves.bw)
moves.bw.inv = moves.fw
moves.left.execute = executeHorizontalMove(moves.left)
moves.left.inv = moves.right
moves.up.execute = function()
  turtle.digUp()
  if not turtle.up() then
    t.air[t.pos + moves.up] = nil
    return false
  end
  t.pos = t.pos + moves.up
  t.air[t.pos] = true
  return true
end
moves.up.inv = moves.down
moves.down.execute = function()
  turtle.digDown()
  if not turtle.down() then
    t.air[t.pos + moves.down] = nil
    return false
  end
  t.pos = t.pos + moves.down
  t.air[t.pos] = true
  return true
end
moves.down.inv = moves.up

local function goTo(target)
  target = Vec:new(target)
  local nextMove = {}
  local queue = Queue:new()
  queue:push(target)
  while not queue:empty() do
    local current = queue:pop()

    for _, move in pairs(moves) do
      local next = current + move
      if t.air[next] and not nextMove[next] then
        queue:push(next)
        nextMove[next] = move.inv
        if next == t.pos then
          break
        end
      end
    end
  end

  local current = t.pos
  while current ~= target do
    local move = nextMove[current]
    if not move.execute() then
      print("failed to move")
      return
    end
    current = current + move
  end
end

local function home()
  goTo({ 0, 0, 0 })
  turnToRot(0)
end

t.air[t.pos] = true

local function main()
  moves.fw.execute()
  moves.right.execute()
  moves.fw.execute()
  moves.fw.execute()
  assert(1 == 2)
  moves.fw.execute()
  moves.fw.execute()
  turtle.placeDown()
  moves.fw.execute()
  turtle.placeDown()
  moves.fw.execute()
  turtle.placeDown()
  moves.fw.execute()
  turtle.placeDown()
end

local suc, ret = pcall(main)
if not suc then
  print(ret)
end
home()