
local ServerInitializer = {}

local ngx = ngx

local s_IsInitialized = false

function ServerInitializer.init()
    if (not s_IsInitialized) then
        s_IsInitialized = true

        math.randomseed(ngx.time())

        package.path = package.path .. ";./babyWars/?.lua"
        require("src.app.utilities.GameConstantFunctions") .init(true)
        require("src.app.utilities.SerializationFunctions").init()
        require("src.app.utilities.SceneWarManager")       .init()
        require("src.app.utilities.PlayerProfileManager")  .init()
        require("src.app.utilities.WarFieldManager")       .init()
        require("src.Session")

        ngx.log(ngx.CRIT, "ServerInitializer.init() completed.")
    end

    return ServerInitializer
end

return ServerInitializer
