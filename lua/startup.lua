for i = 1, 10 do
    local response, _, errResponse = http.get'https://t.alb1.hu'
    if response then
        local text = response.readAll()
        response.close()
        local file = fs.open('install.lua', 'w')
        file.write(text)
        file.close()
        shell.run'install'
        return
    else
        local code, message = errResponse.getResponseCode()
        errResponse.close()

        print('Failed to download install.lua:')
        print(code, message, '- Retrying in', 3 ^ i, 's')
    end
    sleep(3 ^ i)
end
