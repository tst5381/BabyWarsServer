
local ServerSchedulers = {}

local ActionCodeFunctions        = requireFW("src.app.utilities.ActionCodeFunctions")
local ActionExecutorForWarOnline = requireFW("src.app.utilities.actionExecutors.ActionExecutorForWarOnline")
local ActionTranslator           = requireFW("src.app.utilities.ActionTranslator")
local PlayerProfileManager       = requireFW("src.app.utilities.PlayerProfileManager")
local OnlineWarManager           = requireFW("src.app.utilities.OnlineWarManager")

local ngx      = ngx
local newTimer = ngx.timer.at
local log, ERR = ngx.log, ngx.ERR

local ACTION_CODE_BEGIN_TURN      = ActionCodeFunctions.getActionCode("ActionBeginTurn")
local ACTION_CODE_SURRENDER       = ActionCodeFunctions.getActionCode("ActionSurrender")
local SCHEDULER_INTERVAL_FOR_BOOT = 300 -- 5 minutes

local function startSchedulerForBoot()
    local check
    check = function(premature)
        if (not premature) then
            local currentTime = ngx.time()
            OnlineWarManager.forEachOngoingModelSceneWar(function(modelSceneWar)
                local intervalUntilBoot = modelSceneWar:getIntervalUntilBoot()
                if (currentTime - modelSceneWar:getEnterTurnTime() > intervalUntilBoot) then
                    local warID            = modelSceneWar:getWarId()
                    local modelTurnManager = modelSceneWar:getModelTurnManager()
                    local playerAccount    = modelSceneWar:getModelPlayerManager():getModelPlayer(modelTurnManager:getPlayerIndex()):getAccount()
                    local playerPassword   = PlayerProfileManager.getPlayerProfile(playerAccount).password

                    if (modelTurnManager:isTurnPhaseRequestToBegin()) then
                        local _1, _2, actionBeginTurn = ActionTranslator.translate({
                            actionCode     = ACTION_CODE_BEGIN_TURN,
                            actionID       = modelSceneWar:getActionId() + 1,
                            warID          = warID,
                            playerAccount  = playerAccount,
                            playerPassword = playerPassword,
                        })
                        ActionExecutorForWarOnline.execute(actionBeginTurn, modelSceneWar)

                        if ((modelSceneWar:isEnded()) or (currentTime - modelSceneWar:getEnterTurnTime() <= intervalUntilBoot)) then
                            return
                        end
                    end

                    local _1, _2, actionSurrender = ActionTranslator.translate({
                        actionCode     = ACTION_CODE_SURRENDER,
                        actionID       = modelSceneWar:getActionId() + 1,
                        warID          = warID,
                        playerAccount  = playerAccount,
                        playerPassword = playerPassword,
                    })
                    ActionExecutorForWarOnline.execute(actionSurrender, modelSceneWar)
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
    startSchedulerForBoot()

    return ServerSchedulers
end

return ServerSchedulers
