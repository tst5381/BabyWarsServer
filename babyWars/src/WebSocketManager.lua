
local server                 = require("resty.websocket.server")
local ActionTranslator       = require("babyWars.src.app.utilities.ActionTranslator")
local SerializationFunctions = require("babyWars.src.app.utilities.SerializationFunctions")

local wb, err = server:new{
    timeout = 5000,
    max_payload_len = 65535
}

if not wb then
    ngx.log(ngx.ERR, "failed to new websocket: ", err)
    return ngx.exit(444)
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
        local chunk    = loadstring("return " .. data)
        local feedback = (chunk) and
            (SerializationFunctions.serialize(ActionTranslator.translate(chunk()))) or
            ("invalid request: " .. data)

        local bytes, err = wb:send_text(feedback)
        if not bytes then
            ngx.log(ngx.ERR, "failed to send text: ", err)
            return ngx.exit(444)
        end
    end
end

wb:send_close()
