
local SessionManager = {}

local s_AvailableSessionID = 1
local s_SessionIdList = {}

function SessionManager.getAvailableSessionId()
    return s_AvailableSessionID
end

function SessionManager.tickAvailableSessionId()
    s_AvailableSessionID = s_AvailableSessionID + 1

    return SessionManager
end

function SessionManager.getSessionIdWithPlayerAccount(account)
    return s_SessionIdList[account]
end

function SessionManager.setSessionIdWithPlayerAccount(account, id)
    s_SessionIdList[account] = id

    return SessionManager
end

function SessionManager.deleteSessionIdWithPlayerAccount(account)
    s_SessionIdList[account] = nil

    return SessionManager
end

return SessionManager
