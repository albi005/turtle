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

return M
