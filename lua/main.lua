fs.delete'error.log'

local ok, err = xpcall(function()
    local dimension = require'dimension'
    local hivemind = require'hivemind'
    local file = require'file'
    local rotationHelper = require'rotationHelper'
    local jobs = require'jobs'
    local world = require'worldHm'
    local Vec = require'vec'
    local move = require'moveGps'
    local eventLoop = require'eventLoop'

    local worldId = file.read'worldId.txt'
    local dimensionId = dimension.getId()
    local turtleId = os.getComputerID()
    os.setComputerLabel(tostring(turtleId))
    local x, y, z = gps.locate()
    if not x then error('No gps') end
    local position = Vec.new{x, y, z}
    local rotation = rotationHelper.getRotation(position)

    hivemind.init(turtleId, worldId, dimensionId, jobs.update)
    move.init(position, rotation)

    print('worldId', worldId)
    print('dimensionId', dimensionId)
    print('turtleId', turtleId)
    print('position', position)
    print('rotation', rotation)

    eventLoop.run(hivemind.run, world.run, jobs.run)
end, debug.traceback)

if not ok then
    print(err)
    local file = fs.open('error.log', 'w')
    file.write(err)
    file.close()
end
