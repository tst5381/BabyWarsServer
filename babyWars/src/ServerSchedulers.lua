
local ServerSchedulers = {}

local ActionCodeFunctions  = require("src.app.utilities.ActionCodeFunctions")
local ActionTranslator     = require("src.app.utilities.ActionTranslator")
local PlayerProfileManager = require("src.app.utilities.PlayerProfileManager")
local SceneWarManager      = require("src.app.utilities.SceneWarManager")

local ngx      = ngx
local newTimer = ngx.timer.at
local log, ERR = ngx.log, ngx.ERR

local ACTION_CODE_BEGIN_TURN      = ActionCodeFunctions.getActionCode("ActionBeginTurn")
local ACTION_CODE_SURRENDER       = ActionCodeFunctions.getActionCode("ActionSurrender")
local SCHEDULER_INTERVAL_FOR_BOOT = 30 --3600 -- 1 hour

local function startSchedulerForBoot()
    local check
    check = function(premature)
        if (not premature) then
            local currentTime = ngx.time()
            SceneWarManager.forEachOngoingModelSceneWar(function(modelSceneWar)
                local intervalUntilBoot = modelSceneWar:getIntervalUntilBoot()
                if (currentTime - modelSceneWar:getEnterTurnTime() > intervalUntilBoot) then
                    local warID            = modelSceneWar:getWarId()
                    local modelTurnManager = modelSceneWar:getModelTurnManager()
                    local playerAccount    = modelSceneWar:getModelPlayerManager():getModelPlayer(modelTurnManager:getPlayerIndex()):getAccount()
                    local playerPassword   = PlayerProfileManager.getPlayerProfile(playerAccount).password

                    if (modelTurnManager:isTurnPhaseRequestToBegin()) then
                        local _1, _2, actionBeginTurn = ActionTranslator.translate({
                            actionCode       = ACTION_CODE_BEGIN_TURN,
                            actionID         = modelSceneWar:getActionId() + 1,
                            warID            = warID,
                            playerAccount    = playerAccount,
                            playerPassword   = playerPassword,
                        })
                        SceneWarManager.updateModelSceneWarWithAction(actionBeginTurn)

                        if ((modelSceneWar:isEnded()) or (currentTime - modelSceneWar:getEnterTurnTime() <= intervalUntilBoot)) then
                            return
                        end
                    end

                    local _1, _2, actionSurrender = ActionTranslator.translate({
                        actionCode       = ACTION_CODE_SURRENDER,
                        actionID         = modelSceneWar:getActionId() + 1,
                        warID            = warID,
                        playerAccount    = playerAccount,
                        playerPassword   = playerPassword,
                    })
                    SceneWarManager.updateModelSceneWarWithAction(actionSurrender)
                end
            end)

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
    --startSchedulerForBoot()

    return ServerSchedulers
end

return ServerSchedulers
