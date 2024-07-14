fs.delete'error.log'

local ok, err = xpcall(function()
    local Vec = require'vec'
    local dimension = require'dimension'
    local eventLoop = require'eventLoop'
    local file = require'file'
    local hivemind = require'hivemind'
    local jobs = require'jobs'
    local log = require'log'
    local move = require'moveGps'
    local rotationHelper = require'rotationHelper'
    local status = require'status'
    local world = require'worldHm'

    local worldId = file.read'worldId.txt'
    local dimensionId = dimension.getId()
    local turtleId = os.getComputerID()
    os.setComputerLabel(tostring(turtleId))
    local x, y, z = gps.locate()
    if not x then error'No gps' end
    local position = Vec.new{x, y, z}
    local rotation = rotationHelper.getRotation(position)

    log('worldId', worldId)
    log('dimensionId', dimensionId)
    log('turtleId', turtleId)
    log('position', position)
    log('rotation', rotation)

    hivemind.init(turtleId, worldId, dimensionId, jobs.update)
    status.init(hivemind.send)
    move.init(position, rotation)

    eventLoop.run(hivemind.run, world.run, jobs.run, status.run)
end, debug.traceback)

if not ok then
    print'ERROR: written to error.log'
    local file = fs.open('error.log', 'w')
    file.write(err)
    file.close()
end
