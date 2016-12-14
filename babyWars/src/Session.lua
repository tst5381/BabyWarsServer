
-- TODO: move the code that initializes the server to somewhere else (like main()).
package.path = package.path .. ";./babyWars/?.lua"
require("src.app.utilities.GameConstantFunctions") .init(true)
require("src.app.utilities.SceneWarManager")       .init()
require("src.app.utilities.PlayerProfileManager")  .init()
require("src.app.utilities.SerializationFunctions").init()

local Session = require("src.global.functions.class")("Session")

local WebSocketServer        = require("resty.websocket.server")
local Redis                  = require("resty.redis")
local ActionTranslator       = require("src.app.utilities.ActionTranslator")
local PlayerProfileManager   = require("src.app.utilities.PlayerProfileManager")
local SceneWarManager        = require("src.app.utilities.SceneWarManager")
local SerializationFunctions = require("src.app.utilities.SerializationFunctions")

local DEFAULT_CONFIGURATION = {
    timeout         = 10000000, -- 10000s
    max_payload_len = 1048575,
}

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

    local webSocket, err = WebSocketServer:new(DEFAULT_CONFIGURATION)
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

local function initRedisForSubscribe(self, account)
    assert(self.m_RedisForSubscribe == nil, "Session-initRedisForSubscribe() the redis is initialized already.")

    local red = Redis:new()
    red:set_timeout(10000000) -- 10000s

    local ok, err = red:connect("127.0.0.1", 6379)
    if (not ok) then
        ngx.log(ngx.ERR, "Session-initRedisForSubscribe() failed to connect to redis for subscribe: ", err)
        return
    end
    red:subscribe("Session." .. account)

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
            if (not self.m_RedisForSubscribe) then
                return self:stop()
            end

            local res, err = self.m_RedisForSubscribe:read_reply()
            if (not res) then
                ngx.log(ngx.ERR, "Session-threadForSubscribe main loop: failed to read reply: ", err)
                return self:stop()
            end

            if ((res) and (res[1] == "message")) then
                if (string.find(res[3], '"Logout"')) then
                    ngx.log(ngx.CRIT, "Session-threadForSubscribe main loop: receive a Logout action.")
                    -- return self:stop()
                    self:unsubscribeFromPlayerChannel()
                end

                local bytes, err = self.m_WebSocket:send_text(res[3])
                -- ngx.log(ngx.CRIT, "Session-threadForSubscribe() receive published message: ", res[3])
                if (not bytes) then
                    ngx.log(ngx.ERR, "Session-threadForSubscribe main loop: failed to send the published message to the webSocket: ", err)
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

local function publishTranslatedActions(actions)
    -- It seems that if we use self.m_RedisForSubscribe to publish the actions, it may fail mysteriously.
    -- So it's safer to use a temporary redis for publishing.
    local red = Redis:new()
    red:set_timeout(10000000) -- 10000s
    red:connect("127.0.0.1", 6379)

    local toString = SerializationFunctions.toString
    for account, action in pairs(actions) do
        red:publish("Session." .. account, toString(action))
    end

    red:close()
end

local function doAction(self, rawAction, actionForRequester, actionsForPublish, actionForServer)
    if (actionForServer) then
        SceneWarManager.updateModelSceneWarWithAction(actionForServer)
    end
    if (actionsForPublish) then
        publishTranslatedActions(actionsForPublish)
    end

    local account, password    = rawAction.playerAccount, rawAction.playerPassword
    local translatedActionName = actionForRequester.actionName
    if ((translatedActionName == "Logout")                                       or
        (not PlayerProfileManager.isAccountAndPasswordValid(account, password))) then
        self:unsubscribeFromPlayerChannel()
    else
        local rawActionName = rawAction.actionName
        if ((rawActionName ~= "Register")                                                or
            ((rawActionName == "Register") and (translatedActionName == rawActionName))) then
            self:subscribeToPlayerChannel(account, password)
        end
    end

    local bytes, err = self.m_WebSocket:send_text(SerializationFunctions.toString(actionForRequester))
    if (not bytes) then
        ngx.log(ngx.ERR, "Session-doAction() failed to send text: ", err)
        return self:stop()
    end
end

--------------------------------------------------------------------------------
-- The constructor.
--------------------------------------------------------------------------------
function Session:ctor()
    return self
end

--------------------------------------------------------------------------------
-- The public functions.
--------------------------------------------------------------------------------
-- WARNING: You can't call this method outside the context of the request.
function Session:subscribeToPlayerChannel(account, password)
    assert(type(account) == "string", "Session:subscribeToPlayerChannel() the param account is invalid.")
    if (self.m_PlayerAccount == account) then
        return self
    end

    self:unsubscribeFromPlayerChannel()

    initRedisForSubscribe(self, account)
    initThreadForSubscribe(self)
    self.m_PlayerAccount, self.m_PlayerPassword = account, password

    return self
end

-- WARNING: You can't call this method outside the context of the request.
function Session:unsubscribeFromPlayerChannel()
    destroyThreadForSubscribe(self)
    destroyRedisForSubscribe(self)

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
                local rawAction = chunk()
                doAction(self, rawAction, ActionTranslator.translate(rawAction))
            else
                local bytes, err = webSocket:send_text("Server: Failed to parse the data came from the client.")
                if (not bytes) then
                    ngx.log(ngx.ERR, "Session:start() failed to send text: ", err)
                    return self:stop()
                end
            end
        end
    end

    return self:stop()
end

-- WARNING: You can't call this method outside the context of the request.
function Session:stop()
    self:unsubscribeFromPlayerChannel()
    destroyWebSocket(self)

    return ngx.exit(ngx.HTTP_CLOSE)
end

return Session
