
local ServerSchedulers = {}

local ActionTranslator = require("src.app.utilities.ActionTranslator")
local SceneWarManager  = require("src.app.utilities.SceneWarManager")

local newTimer = ngx.timer.at
local log, ERR = ngx.log, ngx.ERR

local SCHEDULER_INTERVAL_FOR_BOOT = 30 -- 1 hour

local function startSchedulerForBoot()
    local check
    check = function(premature)
        if (not premature) then
            -- TODO: enable to boot.

            local ok, err = newTimer(SCHEDULER_INTERVAL_FOR_BOOT, check)
            if (not ok) then
                log(ERR, "ServerSchedulers-startSchedulerForBoot() failed to create timer: ", err)
                return
            end
        end
    end

    local ok, err = newTimer(SCHEDULER_INTERVAL_FOR_BOOT - (ngx.time() % SCHEDULER_INTERVAL_FOR_BOOT), check)
    if (not ok) then
        log(ERR, "ServerSchedulers-startSchedulerForBoot() failed to create timer: ", err)
        return
    end
end

function ServerSchedulers.start()
    startSchedulerForBoot()

    return ServerSchedulers
end

return ServerSchedulers
