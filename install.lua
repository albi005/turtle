local function install(name)
    fs.delete(name .. '.lua')
    shell.run('wget https://turtle.alb1.hu/' .. name .. '.lua')
end

install'inventory'
install'lava'
install'main'
install'mine'
install'move'
install'queue'
install'vector'
install'world'

print()

shell.run'main'
