World = {}

function World.load()
    if not fs.exists'world.dat' then
        return
    end
    for line in io.lines'world.dat' do
        local key = {}
        local start = 1
        for i = 1, 3 do
            local sep = line:find(',', start)
            key[i] = tonumber(line:sub(start, sep - 1))
            start = sep + 1
        end
        key = Vec.new(key)

        local value = line:sub(start)
        World[key] = value
    end
end

function World.save()
    local f = fs.open('world.dat', 'w')
    for key, value in pairs(World) do
        if type(key) == 'table' then
            f.write(tostring(key) .. ',' .. value .. '\n')
        end
    end
    f.close()
end

BlockTypes = {
    empty = 'empty',
    barrier = 'barrier',
    lava = 'lava',
    solid = 'solid',
}
