local hivemind = require'hivemind'
local move = require'moveGps'
local Vec = require'vec'

local M = {}

---@param target integer[]
function M.goTo(target)
    local moves = hivemind.getPath(move.position, target:toVector())
    if not moves then
        error('no path found to target ' .. textutils.serialise(target))
    end
    for _, moveId in ipairs(moves) do
        move[moveId].move()
    end
end

return M