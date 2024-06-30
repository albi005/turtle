local file = {}

function file.read(path)
    if not fs.exists(path) then return nil end
    local f = fs.open(path, 'r')
    local content = f.readAll()
    f.close()
    return content
end

function file.write(path, content)
    local f = fs.open(path, 'w')
    f.write(content)
    f.close()
end

return file