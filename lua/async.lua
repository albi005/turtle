local log = require'log'

local M = {}

function M.sleep(s)
    local timer = os.startTimer(s)
    coroutine.yield('timer', timer)
end

function M.websocket(url)
    http.websocketAsync(url)
    local event, eventUrl, param = coroutine.yield{'websocket_success', 'websocket_failure'}
    if event == 'websocket_success' then
        return param
    elseif event == 'websocket_failure' then
        return false, param
    end
end

function M.reboot()
    local co = coroutine.create(os.reboot)
    coroutine.resume(co)
end

function M.httpRequest(request)
    request.headers = request.headers or {}
    request.headers['Content-Type'] = 'application/json'
    http.request(request)

    local event, url, response, errorResponse = coroutine.yield('', request.url)
    if event == 'http_success' then
        return true, response
    elseif event == 'http_failure' then
        return false, response, errorResponse
    end
    
end

return M
