local hivemind = require'hivemind'
local move = require'moveGps'
local Vec = require'vec'
local world = require'worldHm'
local log = require'log'

local M = {}

---@param target integer[]
function M.goTo(target)
    world.upload()
    local moves = hivemind.getPath(move.position:toVector(), target:toVector())
    log('moves:', moves)
    if not moves then
        error('no path found to ' .. textutils.serialise(target))
    end
    for _, moveId in ipairs(moves) do
        move[moveId].move()
    end
end

return M