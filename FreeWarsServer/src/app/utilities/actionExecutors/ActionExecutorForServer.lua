
local ActionExecutorForServer = {}

local ActionCodeFunctions        = requireFW("src.app.utilities.ActionCodeFunctions")
local ActionExecutorForWarOnline = requireFW("src.app.utilities.actionExecutors.ActionExecutorForWarOnline")
local PlayerProfileManager       = requireFW("src.app.utilities.PlayerProfileManager")
local SceneWarManager            = requireFW("src.app.utilities.SceneWarManager")

local ACTION_CODES = ActionCodeFunctions.getFullList()

local math, string                = math, string
local next, pairs, ipairs, unpack = next, pairs, ipairs, unpack

--------------------------------------------------------------------------------
-- The executors for non-war actions.
--------------------------------------------------------------------------------
local function executeExitWar(action)
    SceneWarManager.exitWar(action.playerAccount, action.warID)
end

local function executeJoinWar(action)
    SceneWarManager.joinWar(action)
end

local function executeNetworkHeartbeat(action)
    PlayerProfileManager.updateProfileWithNetworkHeartbeat(action.playerAccount)
end

local function executeNewWar(action)
    SceneWarManager.createNewWar(action)
end

local function executeRegister(action)
    PlayerProfileManager.createPlayerProfile(action.registerAccount, action.registerPassword)
end

--------------------------------------------------------------------------------
-- The public function.
--------------------------------------------------------------------------------
function ActionExecutorForServer.execute(action)
    local actionCode = action.actionCode
    assert(ActionCodeFunctions.getActionName(actionCode), "ActionExecutorForServer.execute() invalid actionCode: " .. (actionCode or ""))

    if     (actionCode == ACTION_CODES.ActionExitWar)          then executeExitWar(         action)
    elseif (actionCode == ACTION_CODES.ActionJoinWar)          then executeJoinWar(         action)
    elseif (actionCode == ACTION_CODES.ActionNetworkHeartbeat) then executeNetworkHeartbeat(action)
    elseif (actionCode == ACTION_CODES.ActionNewWar)           then executeNewWar(          action)
    elseif (actionCode == ACTION_CODES.ActionRegister)         then executeRegister(        action)
    else                                                            ActionExecutorForWarOnline.execute(action, SceneWarManager.getOngoingModelSceneWar(action.warID))
    end

    return ActionExecutorForServer
end

return ActionExecutorForServer
