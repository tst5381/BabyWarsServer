
local WebSocketManager = {}

local s_AccountAndSocketList = {}

function WebSocketManager.addSocketWithPlayerAccount(account, socket)
    assert(type(account) == "string", "WebSocketManager.addSocketWithPlayerAccount() the param account is invalid.")
    assert(s_AccountAndSocketList[account] == nil, "WebSocketManager.addSocketWithPlayerAccount() the account is already in the list.")

    s_AccountAndSocketList[account] = socket

    return WebSocketManager
end

function WebSocketManager.getSocketWithPlayerAccount(account)
    assert(type(account) == "string", "WebSocketManager.getSocketWithPlayerAccount() the param account is invalid.")
    return s_AccountAndSocketList[account]
end

function WebSocketManager.removeSocketWithPlayerAccount(account)
    assert(type(account) == "string", "WebSocketManager.getSocketWithPlayerAccount() the param account is invalid.")
    s_AccountAndSocketList[account] = nil

    return WebSocketManager
end

function WebSocketManager.updateSocketWithPlayerAccountAndPassword(account, password, socket)
    assert(type(account) == "string", "WebSocketManager.updateSocketWithPlayerAccountAndPassword() the param account is invalid.")

    local previousAccount = socket:getPlayerAccountAndPassword()
    if (previousAccount) then
        s_AccountAndSocketList[previousAccount] = nil
    end

    local existingSocket = s_AccountAndSocketList[account]
    if ((existingSocket) and (existingSocket ~= socket)) then
        -- TODO: should we ask the client to reboot when its socket is closed by the server?
        existingSocket:send_close()
    end

    s_AccountAndSocketList[account] = socket
    socket:setPlayerAccountAndPassword(account, password)

    return WebSocketManager
end

return WebSocketManager
