
local ServerInitializer = {}

local ngx = ngx

local s_IsInitialized = false

function ServerInitializer.init()
    if (not s_IsInitialized) then
        s_IsInitialized = true

        math.randomseed(ngx.time())

        requireFW = function(modName)
            return require("FreeWars." .. modName)
        end

        requireFW("src.app.utilities.GameConstantFunctions") .init(true)
        requireFW("src.app.utilities.SerializationFunctions").init()
        requireFW("src.app.utilities.SceneWarManager")       .init()
        requireFW("src.app.utilities.PlayerProfileManager")  .init()
        requireFW("src.app.utilities.WarFieldManager")       .init()
        requireFW("src.Session")

        ngx.log(ngx.CRIT, "FreeWars-ServerInitializer.init() completed.")
    end

    return ServerInitializer
end

return ServerInitializer
