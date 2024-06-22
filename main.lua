function Dbg(value)
    local pretty = require'cc.pretty'
    print(pretty.pretty(value))
    return value
end

function Try(f)
    local ok, err = xpcall(f, debug.traceback)
    if not ok then
        print(err)
    end
end

require'world'
local move = require'move'
local lava = require'lava'
local mine = require'mine'

World.load()
-- wget run https://turtle.alb1.hu
local function main()
    mine.run()
end

Try(main)

move.home()
World.save()
