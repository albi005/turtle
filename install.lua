local function install(name)
    fs.delete(name .. '.lua')
    shell.run('wget https://turtle.alb1.hu/' .. name .. '.lua')
end

install'main'
install'move'
install'queue'
install'vector'

shell.run'main'
