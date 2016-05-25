
local Session = require("babyWars.src.global.functions.class")("Session")

local WebSocketServer        = require("resty.websocket.server")
local Redis                  = require("resty.redis")
local ActionTranslator       = require("babyWars.src.app.utilities.ActionTranslator")
local SerializationFunctions = require("babyWars.src.app.utilities.SerializationFunctions")
local SessionManager         = require("babyWars.src.app.utilities.SessionManager")

-- TODO: move the code that initializes the server to somewhere else (like main()).
require("babyWars.src.app.utilities.GameConstantFunctions").init()

--------------------------------------------------------------------------------
-- The util functions.
--------------------------------------------------------------------------------
local function initCallbackOnAbort(self)
    local ok, err = ngx.on_abort(function()
        return self:stop()
    end)
    if (not ok) then
        ngx.log(ngx.ERR, "Session-initCallbackOnAbort() failed to register the callback for on_abort: ", err)
    end

    return ok
end

local function initWebSocket(self)
    assert(self.m_WebSocket == nil, "Session-initWebSocket() the webSocket is initialized already.")

    local webSocket, err = WebSocketServer:new({
        timeout = 5000,
        max_payload_len = 65535
    })
    if (not webSocket) then
        ngx.log(ngx.ERR, "Session-initWebSocket() failed to create a websocket: ", err)
        return
    end

    self.m_WebSocket = webSocket
    return webSocket
end

local function destroyWebSocket(self)
    if (self.m_WebSocket) then
        self.m_WebSocket:send_close()
        self.m_WebSocket = nil
    end
end

local function initRedisForSubscribe(self)
    assert(self.m_RedisForSubscribe == nil, "Session-initRedisForSubscribe() the redis is initialized already.")

    local red = Redis:new()
    red:set_timeout(10000000) -- 10000s

    local ok, err = red:connect("127.0.0.1", 6379)
    if (not ok) then
        ngx.log(ngx.ERR, "Session-initRedisForSubscribe() failed to connect to redis for subscribe: ", err)
        return
    end

    red:set("kkey", "vvalue")
    ngx.log(ngx.CRIT, "get kkey from redis: ", red:get("kkey"))

    self.m_RedisForSubscribe = red
    return red
end

local function destroyRedisForSubscribe(self)
    if (self.m_RedisForSubscribe) then
        self.m_RedisForSubscribe:close()
        self.m_RedisForSubscribe = nil
    end
end

local function initThreadForSubscribe(self)
    assert(self.m_ThreadForSubscribe == nil, "Session-initThreadForSubscribe() the thread is initialized already.")
    assert(self.m_WebSocket,                 "Session-initThreadForSubscribe() no webSocket available for the thread.")
    assert(self.m_RedisForSubscribe,         "Session-initThreadForSubscribe() no redis available for the thread.")

    local thread = ngx.thread.spawn(function()
        while (true) do
            local res, err = self.m_RedisForSubscribe:read_reply()
            if (not res) then
                ngx.log(ngx.ERR, "Session-threadForSubscribe main loop: failed to read reply: ", err)
                return self:stop()
            end

            if ((res) and (res[1] == "message")) then
                local bytes, err = self.m_WebSocket:send_text(res[3])
                if (not bytes) then
                    ngx.log(ngx.ERR, "Session-threadForSubscribe main loop: failed to send the reply to the webSocket: ", err)
                    return self:stop()
                end

                if (string.find(res[3], "Logout")) then
                    ngx.log(ngx.ERR, "Session-threadForSubscribe main loop: logout.")
                    return self:stop()
                end
            end
        end
    end)

    self.m_ThreadForSubscribe = thread
    return thread
end

local function destroyThreadForSubscribe(self)
    if (self.m_ThreadForSubscribe) then
        ngx.thread.kill(self.m_ThreadForSubscribe)
        self.m_ThreadForSubscribe = nil
    end
end

local function publishTranslatedActions(self, actions)
    local red = self.m_RedisForSubscribe
    local serialize = SerializationFunctions.serialize
    for account, action in pairs(actions or {}) do
        red:publish("Session." .. account, serialize(action))
    end
end

local function doAction(self, actionForSelf, actionsForPublish)
    if (actionForSelf.actionName == "Login") then
        publishTranslatedActions(self, actionsForPublish)
        ngx.log(ngx.CRIT, "Session-doAction() before subscribe")
        self:subscribeToPlayerChannel(actionForSelf.account, actionForSelf.password)
        ngx.log(ngx.CRIT, "Session-doAction() after subscribe")
    end

    local bytes, err = self.m_WebSocket:send_text(SerializationFunctions.serialize(actionForSelf))
    if (not bytes) then
        ngx.log(ngx.ERR, "Session-doAction() failed to send text: ", err)
        return self:stop()
    end
end

--------------------------------------------------------------------------------
-- The constructor.
--------------------------------------------------------------------------------
function Session:ctor()
    self.m_ID = SessionManager.getAvailableSessionId()
    SessionManager.tickAvailableSessionId()

    return self
end

--------------------------------------------------------------------------------
-- The public functions.
--------------------------------------------------------------------------------
function Session:getID()
    return self.m_ID
end

function Session:isSubscribingToPlayerChannel(account)
    if (account == nil) then
        return self.m_PlayerAccount ~= nil
    else
        return self.m_PlayerAccount == account
    end
end

-- WARNING: You can't call this method outside the context of the request.
function Session:subscribeToPlayerChannel(account, password)
    assert(type(account) == "string", "Session:subscribeToPlayerChannel() the param account is invalid.")
    if (self:isSubscribingToPlayerChannel(account)) then
        return self
    end

    ngx.log(ngx.CRIT, "Session:subscribeToPlayerChannel() before unsubscribe.")
    self:unsubscribeFromPlayerChannel()
    ngx.log(ngx.CRIT, "Session:subscribeToPlayerChannel() after unsubscribe.")

    initRedisForSubscribe(self)
    self.m_RedisForSubscribe:subscribe("Session." .. account)
    initThreadForSubscribe(self)
    self.m_PlayerAccount, self.m_PlayerPassword = account, password
    SessionManager.setSessionIdWithPlayerAccount(account, self.m_ID)

    return self
end

-- WARNING: You can't call this method outside the context of the request.
function Session:unsubscribeFromPlayerChannel()
    ngx.log(ngx.CRIT, "Session:unsubscribeFromPlayerChannel() before destroying thread.")
    destroyThreadForSubscribe(self)
    ngx.log(ngx.CRIT, "Session:unsubscribeFromPlayerChannel() after destroying thread.")
    ngx.log(ngx.CRIT, "Session:unsubscribeFromPlayerChannel() before destroying redis.")
    destroyRedisForSubscribe(self)
    ngx.log(ngx.CRIT, "Session:unsubscribeFromPlayerChannel() after destroying redis")

    if (self.m_PlayerAccount) then
        SessionManager.deleteSessionIdWithPlayerAccount(self.m_PlayerAccount)
    end
    self.m_PlayerAccount, self.m_PlayerPassword = nil, nil

    return self
end

-- WARNING: You can't call this method outside the context of the request.
function Session:start()
    local webSocket = initWebSocket(self)
    if (not webSocket) then
        return self:stop()
    end

    if (not initCallbackOnAbort(self)) then
        return self:stop()
    end

    if (not initRedisForSubscribe(self)) then
        return self:stop()
    end

    --[[
    local red = redis:new()
    red:set_timeout(1000)
    local ok, err = red:connect("127.0.0.1", 6379)
    if not ok then
        ngx.log(ngx.ERR, "failed to connect to redis: ", err)
        return
    else
        ngx.log(ngx.ERR, "succeed connecting to redis")
    end

    ok, err = red:set("dog", "an animal")
    if not ok then
        ngx.log(ngx.ERR, "failed to set key and value to redis: ", err)
        return
    end

    local res, err = red:get("dog")
    if not res then
        ngx.log(ngx.ERR, "failed to get dog: ", err)
        return
    end
    if res == ngx.null then
        ngx.log(ngx.ERR, "dog not found.")
        return
    end
    ngx.log(ngx.ERR, "get dog: ", res)
    ]]

    while (true) do
        local data, typ, err = webSocket:recv_frame()

        if (webSocket.fatal) then
            ngx.log(ngx.ERR, "Session:start() failed to receive frame: ", err)
            return self:stop()
        end

        if (typ) == "close" then
            break
        elseif (typ == "text") then
            -- TODO: validate the data before loadstring().
            local chunk = loadstring("return " .. data)
            if (chunk) then
                doAction(self, ActionTranslator.translate(chunk(), self))
            else
                local bytes, err = webSocket:send_text("Server: Failed to parse the data came from the client.")
                if (not bytes) then
                    ngx.log(ngx.ERR, "Session:start() failed to send text: ", err)
                    return self:stop()
                end
            end
        end
    end

    --[[
    local wb, err = server:new{
        timeout = 5000,
        max_payload_len = 65535
    }

    if not wb then
        ngx.log(ngx.ERR, "failed to new websocket: ", err)
        return ngx.exit(444)
    end

    wb.setPlayerAccountAndPassword = function(self, account, password)
        self.m_PlayerAccount, self.m_PlayerPassword = account, password
    end

    wb.getPlayerAccountAndPassword = function(self)
        return self.m_PlayerAccount, self.m_PlayerPassword
    end

    while true do
        local data, typ, err = wb:recv_frame()

        if wb.fatal then
            ngx.log(ngx.ERR, "failed to receive frame: ", err)
            return ngx.exit(444)
        end

        if typ == "close" then
            break
        elseif typ == "text" then
            -- TODO: validate the data before loadstring().
            local chunk = loadstring("return " .. data)
            if (chunk) then
                ActionTranslator.translate(chunk(), wb)
            else
                local bytes, err = wb:send_text("Server: Failed to parse the data came from the client.")
                if not bytes then
                    ngx.log(ngx.ERR, "failed to send text: ", err)
                    return ngx.exit(444)
                end
            end
        end
    end

    if (wb.m_PlayerAccount) then
        WebSocketManager.removeSocketWithPlayerAccount(wb.m_PlayerAccount)
    end
    wb:send_close()
    --]]

    return self:stop()
end

-- WARNING: You can't call this method outside the context of the request.
function Session:stop()
    self:unsubscribeFromPlayerChannel()
    -- destroyThreadForSubscribe(self)
    -- destroyRedisForSubscribe(self)
    destroyWebSocket(self)

    return ngx.exit(ngx.HTTP_CLOSE)
end

return Session
