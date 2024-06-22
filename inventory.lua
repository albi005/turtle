local move = require'move'

Inventory = {}

function Inventory.pickUp()
    move.goTo{0, 0, 0}
    move.turnToRot(2)
    turtle.select(1)
    turtle.suck()
end

function Inventory.dropAll()
    move.goTo{0, 0, 0}
    move.turnToRot(2)
    for i = 1, 16 do
        turtle.select(i)
        turtle.drop()
    end
end

function Inventory.isFull()
    return turtle.getItemCount(16) > 0
end
