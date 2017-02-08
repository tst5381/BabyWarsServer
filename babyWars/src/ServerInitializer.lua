
local ServerInitializer = {}

local ngx = ngx

local s_IsInitialized = false

function ServerInitializer.init()
    if (not s_IsInitialized) then
        s_IsInitialized = true

        math.randomseed(ngx.time())

        requireBW = function(modName)
            return require("BabyWars." .. modName)
        end

        requireBW("src.app.utilities.GameConstantFunctions") .init(true)
        requireBW("src.app.utilities.SerializationFunctions").init()
        requireBW("src.app.utilities.SceneWarManager")       .init()
        requireBW("src.app.utilities.PlayerProfileManager")  .init()
        requireBW("src.app.utilities.WarFieldManager")       .init()
        requireBW("src.Session")

        ngx.log(ngx.CRIT, "BabyWars-ServerInitializer.init() completed.")
    end

    return ServerInitializer
end

return ServerInitializer
