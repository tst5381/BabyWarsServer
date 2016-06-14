
--[[--------------------------------------------------------------------------------
-- ActionTranslator是用于“翻译”玩家原始操作的辅助函数集合。
-- 主要职责：
--   翻译原始操作，也就是检查操作的合法性，并返回各model可响应的操作
--   如果发现操作不合法（原因可能是不同步，或者是客户端进行了非法修改），那么返回合适的值使得客户端重新载入战局（服务端不做任何更改）
-- 使用场景举例：
--   - 移动单位：在雾战中，玩家指定的移动路线可能被视野外的敌方单位阻挡。客户端把玩家指定的原始路线上传到服务器，
--     服务器使用本文件里的函数判断是否存在阻挡情况。如果存在，则返回截断的路径，并取消掉后续的原始操作（如移动后的攻击/占领/合流等），否则就正常移动
--   - 发起攻击：由于最终伤害涉及幸运伤害，所以最终伤害值必须由服务端计算，并返回计算结果给客户端
--     不必返回单位是否被摧毁的信息，因为客户端可以通过伤害值自行获取这一隐含的战斗结果
--   - 生产单位：生产单位需要消耗金钱，因此本文件里的函数需要判断玩家金钱是否足够，如发现不够则要求客户端重新载入战局，否则就正常生产
-- 其他：
--   - 本游戏架构中，在联机模式下，战局的所有信息都存放在服务器上，一切操作的合法与否都由服务器判断。客户端仅负责从服务器上获取信息并加以呈现
--   - 目前仅做了明战的部分实现
--   - 在雾战下，为避免作弊，客户端应当只能获取其应当获取的信息（如视野内的单位信息），这就要求本文件里的函数做出合适实现（比如，
--     某些操作会使得视野变化，此时服务器就应当返回新视野内的所有单位的信息）
--]]--------------------------------------------------------------------------------

local ActionTranslator = {}

local GridIndexFunctions     = require("babyWars.src.app.utilities.GridIndexFunctions")
local SerializationFunctions = require("babyWars.src.app.utilities.SerializationFunctions")
local SceneWarManager        = require("babyWars.src.app.utilities.SceneWarManager")
local SessionManager         = require("babyWars.src.app.utilities.SessionManager")
local PlayerProfileManager   = require("babyWars.src.app.utilities.PlayerProfileManager")

--------------------------------------------------------------------------------
-- The util functions.
--------------------------------------------------------------------------------
local function getCurrentPlayerAccount(modelPlayerManager, modelTurnManager)
    return modelPlayerManager:getModelPlayer(modelTurnManager:getPlayerIndex()):getAccount()
end

local function getPlayerAccountForModelUnit(modelUnit, modelPlayerManager)
    return modelPlayerManager:getModelPlayer(modelUnit:getPlayerIndex()):getAccount()
end

local function isModelUnitVisible(modelUnit, modelWeatherManager)
    -- TODO: add code to do the real job.
    return true
end

local function generateActionsForPublish(action, modelPlayerManager, currentPlayerAccount)
    local actionsForPublish
    modelPlayerManager:forEachModelPlayer(function(modelPlayer)
        local otherPlayerAccount = modelPlayer:getAccount()
        if ((otherPlayerAccount ~= currentPlayerAccount) and
            (modelPlayer:isAlive()) and
            (SessionManager.getSessionIdWithPlayerAccount(otherPlayerAccount))) then
            actionsForPublish = actionsForPublish or {}
            actionsForPublish[otherPlayerAccount] = action
        end
    end)

    return actionsForPublish
end

--------------------------------------------------------------------------------
-- The translate functions.
--------------------------------------------------------------------------------
-- This translation ignores the existing unit of the same player at the end of the path, so that the actions of Join/Attack/Wait can reuse this function.
local function translatePath(path, modelUnitMap, modelTileMap, modelWeatherManager, modelPlayerManager, currentPlayerAccount, modelPlayer)
    local modelFocusUnit = modelUnitMap:getModelUnit(path[1].gridIndex)
    if (not modelFocusUnit) then
        return nil, "ActionTranslator-translatePath() there is no unit on the starting grid of the path."
    elseif (getPlayerAccountForModelUnit(modelFocusUnit, modelPlayerManager) ~= currentPlayerAccount) then
        return nil, "ActionTranslator-translatePath() the player account of the moving unit is not the same as the one of the in-turn player."
    elseif (modelFocusUnit:getState() ~= "idle") then
        return nil, "ActionTranslator-translatePath() the moving unit is not in idle state."
    end

    local moveType             = modelFocusUnit:getMoveType()
    local modelWeather         = modelWeatherManager:getCurrentWeather()
    local totalFuelConsumption = 0
    local translatedPath       = {GridIndexFunctions.clone(path[1].gridIndex), length = 1}

    for i = 2, #path do
        local gridIndex = GridIndexFunctions.clone(path[i].gridIndex)
        if (not GridIndexFunctions.isAdjacent(path[i - 1].gridIndex, gridIndex)) then
            return nil, "ActionTranslator-translatePath() the path is invalid because some grids are not adjacent to previous ones."
        end

        local existingModelUnit = modelUnitMap:getModelUnit(gridIndex)
        if (existingModelUnit) and (getPlayerAccountForModelUnit(existingModelUnit, modelPlayerManager) ~= currentPlayerAccount) then
            if (isModelUnitVisible(existingModelUnit, modelWeatherManager)) then
                return nil, "ActionTranslator-translatePath() the path is invalid because it is blocked by a visible enemy unit."
            else
                translatedPath.isBlocked = true
                break
            end
        end

        local fuelConsumption = modelTileMap:getModelTile(path[i].gridIndex):getMoveCost(moveType)
        if (not fuelConsumption) then
            return nil, "ActionTranslator-translatedPath() the path is invalid because some tiles on it is impassable."
        end

        totalFuelConsumption = totalFuelConsumption + fuelConsumption
        translatedPath.length = translatedPath.length + 1
        translatedPath[translatedPath.length] = gridIndex
    end

    if ((totalFuelConsumption > modelFocusUnit:getCurrentFuel()) or
        (totalFuelConsumption > modelFocusUnit:getMoveRange(modelPlayer, modelWeather))) then
        return nil, "ActionTranslator-translatedPath() the path is invalid because the fuel consumption is too high."
    else
        translatedPath.fuelConsumption = totalFuelConsumption
        return translatedPath
    end
end

local function translateBeginTurn(action, modelScene)
    local modelPlayerManager = modelScene:getModelPlayerManager()
    local modelTurnManager   = modelScene:getModelTurnManager()

    if (getCurrentPlayerAccount(modelPlayerManager, modelTurnManager) ~= action.playerAccount) then
        return {
            actionName = "Message",
            message    = "Server: translateBeginTurn() you are not the in-turn player. Please reenter the war."
        }
    elseif (modelTurnManager:getTurnPhase() ~= "beginning") then
        ngx.log(ngx.ERR, "ActionTranslator-translateBeginTurn() the current turn phase is expected to be 'beginning'.")
        return {
            actionName = "Message",
            message    = "Server: translateBeginTurn() the current turn phase is expected to be 'beginning'. Please reenter the war.",
        }
    else
        local actionBeginTurn = {
            actionName = "BeginTurn",
            fileName   = modelScene:getFileName(),
        }
        SceneWarManager.updateModelSceneWarWithAction(modelScene:getFileName(), actionBeginTurn)
        return actionBeginTurn, generateActionsForPublish(actionBeginTurn, modelPlayerManager, action.playerAccount)
    end
end

local function translateEndTurn(action, modelScene)
    local modelPlayerManager = modelScene:getModelPlayerManager()
    local modelTurnManager   = modelScene:getModelTurnManager()

    if (getCurrentPlayerAccount(modelPlayerManager, modelTurnManager) ~= action.playerAccount) then
        return {
            actionName = "Message",
            message    = "Server: translateEndTurn() you are not the in-turn player. Please reenter the war."
        }
    elseif (modelTurnManager:getTurnPhase() ~= "main") then
        ngx.log(ngx.ERR, "ActionTranslator-translateEndTurn() the current turn phase is expected to be 'main'.")
        return {
            actionName = "Error",
            error      = "Server: translateEndTurn() the current turn phase is expected to be 'main'. Something is wrong with the server."
        }
    else
        -- TODO: enable the fog of war.
        local actionEndTurn = {
            actionName  = "EndTurn",
            fileName    = modelScene:getFileName(),
            nextWeather = modelScene:getModelWeatherManager():getNextWeather(),
        }
        SceneWarManager.updateModelSceneWarWithAction(modelScene:getFileName(), actionEndTurn)
        return actionEndTurn, generateActionsForPublish(actionEndTurn, modelPlayerManager, action.playerAccount)
    end
end

local function translateWait(action, modelScene)
    local modelWarField        = modelScene:getModelWarField()
    local modelUnitMap         = modelWarField:getModelUnitMap()
    local modelTileMap         = modelWarField:getModelTileMap()
    local modelPlayerManager   = modelScene:getModelPlayerManager()
    local modelTurnManager     = modelScene:getModelTurnManager()
    local modelWeatherManager  = modelScene:getModelWeatherManager()
    local modelPlayer          = modelPlayerManager:getModelPlayer(modelTurnManager:getPlayerIndex())
    local currentPlayerAccount = modelPlayer:getAccount()

    if (currentPlayerAccount ~= action.playerAccount) then
        return {
            actionName = "Message",
            message    = "Server: translateWait() you are not the in-turn player. Please reenter the war."
        }
    end

    local translatedPath, translateMsg = translatePath(action.path, modelUnitMap, modelTileMap, modelWeatherManager, modelPlayerManager, currentPlayerAccount, modelPlayer)
    if (not translatedPath) then
        return {
            actionName = "Message",
            message    = "Server: translateWait() failed to translate the move path. Please reenter the war. " .. (translateMsg or ""),
        }
    end

    local existingModelUnit = modelUnitMap:getModelUnit(translatedPath[translatedPath.length])
    if (existingModelUnit) and (modelUnitMap:getModelUnit(translatedPath[1]) ~= existingModelUnit) then
        return {
            actionName = "Message",
            message    = "Server: translateWait() failed because there is another unit on the destination grid. Please reenter the war.",
        }
    end

    local fileName = modelScene:getFileName()
    local actionWait = {
        actionName = "Wait",
        fileName   = fileName,
        path       = translatedPath,
    }
    SceneWarManager.updateModelSceneWarWithAction(fileName, actionWait)
    return actionWait, generateActionsForPublish(actionWait, modelPlayerManager, action.playerAccount)
end

local function translateAttack(action, modelScene)
    local modelWarField        = modelScene:getModelWarField()
    local modelUnitMap         = modelWarField:getModelUnitMap()
    local modelTileMap         = modelWarField:getModelTileMap()
    local modelPlayerManager   = modelScene:getModelPlayerManager()
    local modelWeatherManager  = modelScene:getModelWeatherManager()
    local modelPlayer          = modelPlayerManager:getModelPlayer(modelScene:getModelTurnManager():getPlayerIndex())
    local currentPlayerAccount = modelPlayer:getAccount()

    if (currentPlayerAccount ~= action.playerAccount) then
        return {
            actionName = "Message",
            message    = "Server: translateAttack() you are not the in-turn player. Please reenter the war."
        }
    end

    local translatedPath, translateMsg = translatePath(action.path, modelUnitMap, modelTileMap, modelWeatherManager, modelPlayerManager, currentPlayerAccount, modelPlayer)
    if (not translatedPath) then
        return {
            actionName = "Message",
            message    = "Server: translateAttack() failed to translate the move path. Please reenter the war. " .. (translateMsg or ""),
        }
    end

    local fileName = modelScene:getFileName()
    if (translatedPath.isBlocked) then
        local actionWait = {
            actionName = "Wait",
            fileName   = fileName,
            path       = translatedPath,
        }
        SceneWarManager.updateModelSceneWarWithAction(fileName, actionWait)
        return actionWait, generateActionsForPublish(actionWait, modelPlayerManager, action.playerAccount)
    end

    local attackerGridIndex = translatedPath[#translatedPath]
    local targetGridIndex   = action.targetGridIndex
    local attacker          = modelUnitMap:getModelUnit(translatedPath[1])
    local target            = modelUnitMap:getModelUnit(action.targetGridIndex) or modelTileMap:getModelTile(action.targetGridIndex)
    local existingModelUnit = modelUnitMap:getModelUnit(attackerGridIndex)
    if (existingModelUnit) and (attacker ~= existingModelUnit) then
        return {
            actionName = "Message",
            message    = "Server: translateAttack() failed because there is another unit on the destination grid. Please reenter the war."
        }
    end

    if ((not attacker.canAttackTarget) or
        (not attacker:canAttackTarget(attackerGridIndex, target, targetGridIndex))) then
        return {
            actionName = "Message",
            message    = "Server: translateAttack() failed because the attacker can't attack the target.",
        }
    end

    local attackDamage, counterDamage = attacker:getUltimateBattleDamage(modelTileMap:getModelTile(attackerGridIndex), target, modelTileMap:getModelTile(targetGridIndex), modelPlayerManager, modelWeatherManager:getCurrentWeather())
    local actionAttack = {
        actionName      = "Attack",
        fileName        = fileName,
        path            = translatedPath,
        targetGridIndex = GridIndexFunctions.clone(targetGridIndex),
        attackDamage    = attackDamage,
        counterDamage   = counterDamage
    }
    SceneWarManager.updateModelSceneWarWithAction(fileName, actionAttack)
    return actionAttack, generateActionsForPublish(actionAttack, modelPlayerManager, action.playerAccount)
end

local function translateCapture(action, modelScene)
    local modelWarField        = modelScene:getModelWarField()
    local modelUnitMap         = modelWarField:getModelUnitMap()
    local modelTileMap         = modelWarField:getModelTileMap()
    local modelPlayerManager   = modelScene:getModelPlayerManager()
    local modelWeatherManager  = modelScene:getModelWeatherManager()
    local modelPlayer          = modelPlayerManager:getModelPlayer(modelScene:getModelTurnManager():getPlayerIndex())
    local currentPlayerAccount = modelPlayer:getAccount()

    if (currentPlayerAccount ~= action.playerAccount) then
        return {
            actionName = "Message",
            message = "Server: translateCapture() you are not the in-turn player. Please reenter the war.",
        }
    end

    local translatedPath, translateMsg = translatePath(action.path, modelUnitMap, modelTileMap, modelWeatherManager, modelPlayerManager, currentPlayerAccount, modelPlayer)
    if (not translatedPath) then
        return {
            actionName = "Message",
            message    = "Server: translateAttack() failed to translate the move path: " .. (translateMsg or ""),
        }
    end

    local fileName = modelScene:getFileName()
    if (translatedPath.isBlocked) then
        local actionWait = {
            actionName = "Wait",
            fileName   = fileName,
            path       = translatedPath,
        }
        SceneWarManager.updateModelSceneWarWithAction(fileName, actionWait)
        return actionWait, generateActionsForPublish(actionWait, modelPlayerManager, action.playerAccount)
    end

    local destination       = translatedPath[#translatedPath]
    local capturer          = modelUnitMap:getModelUnit(translatedPath[1])
    local existingModelUnit = modelUnitMap:getModelUnit(destination)
    if ((existingModelUnit) and (existingModelUnit ~= capturer)) then
        return {
            actionName = "Message",
            message    = "Server: translateCapture() failed because there's another unit on the destination grid. Please reenter the war.",
        }
    end

    if ((not capturer.canCapture) or (not capturer:canCapture(modelTileMap:getModelTile(destination)))) then
        return {
            actionName = "Message",
            message    = "Server: translateCapture() failed because the focus unit can't capture the target tile. Please reenter the war."
        }
    end

    local actionCapture = {
        actionName = "Capture",
        fileName   = fileName,
        path       = translatedPath,
    }
    SceneWarManager.updateModelSceneWarWithAction(fileName, actionCapture)
    return actionCapture, generateActionsForPublish(actionCapture, modelPlayerManager, action.playerAccount)
end

local function translateProduceOnTile(action, modelScene)
    local playerIndex        = modelScene:getModelTurnManager():getPlayerIndex()
    local modelPlayerManager = modelScene:getModelPlayerManager()
    local modelPlayer        = modelPlayerManager:getModelPlayer(playerIndex)
    local modelWarField      = modelScene:getModelWarField()
    local gridIndex          = action.gridIndex
    local tiledID            = action.tiledID

    if (modelPlayer:getAccount() ~= action.playerAccount) then
        return {
            actionName = "Message",
            message    = "Server: translateProduceOnTile() you are not the in-turn player. Please reenter the war."
        }
    end

    if (modelWarField:getModelUnitMap():getModelUnit(gridIndex)) then
        return {
            actionName = "Message",
            message    = "Server: translateProduceOnTile() failed because there's a unit on the tile. Please reenter the war.",
        }
    end

    local modelTile = modelWarField:getModelTileMap():getModelTile(action.gridIndex)
    if (not modelTile.getProductionCostWithTiledId) then
        return {
            actionName = "Message",
            message    = "Server: translateProduceOnTile() failed because the tile can't produce units. Please reenter the war.",
        }
    end

    local cost = modelTile:getProductionCostWithTiledId(tiledID, modelPlayer)
    if ((not cost) or (cost > modelPlayer:getFund())) then
        return {
            actionName = "Message",
            message    = "Server: translateProduceOnTile() failed because the player has not enough fund. Please reenter the war.",
        }
    end

    local fileName = modelScene:getFileName()
    local actionProduceOnTile = {
        actionName = "ProduceOnTile",
        fileName   = fileName,
        gridIndex  = GridIndexFunctions.clone(gridIndex),
        tiledID    = tiledID,
        cost       = cost, -- the cost can be calculated by the clients, but that calculations can be saved by sending the cost to clients.
    }
    SceneWarManager.updateModelSceneWarWithAction(fileName, actionProduceOnTile)
    return actionProduceOnTile, generateActionsForPublish(actionProduceOnTile, modelPlayerManager, action.playerAccount)
end

local function translateLogin(action, session)
    local account, password = action.account, action.password
    if (not PlayerProfileManager.isAccountAndPasswordValid(account, password)) then
        return {
            actionName = "Message",
            message    = "Invalid account/password.",
        }
    else
        -- By returning the actionLogin, the session will then automatically call subscribeToPlayerChannel().
        local actionLogin = {
            actionName = "Login",
            account    = account,
            password   = password,
        }

        if (SessionManager.getSessionIdWithPlayerAccount(account) == nil) then
            return actionLogin
        elseif (session:isSubscribingToPlayerChannel(account)) then
            return {
                actionName = "Message",
                message    = "You have already logged in as " .. account,
            }
        else
            return actionLogin, {
                [account] = {
                    actionName = "Logout",
                    message    = "Another device is logging in with your account!",
                }
            }
        end
    end
end

local function translateRegister(action, session)
    local account, password = action.account, action.password
    if (PlayerProfileManager.getPlayerProfile(account)) then
        return {
            actionName = "Message",
            message    = "The account is registered already. Please use another account.",
        }
    else
        PlayerProfileManager.createPlayerProfile(account, password)
        -- By returning the actionRegister, the session will then automatically call subscribeToPlayerChannel().
        return {
            actionName = "Register",
            account    = account,
            password   = password,
        }
    end
end

local function translateNewWar(action)
    local gameData, err = SceneWarManager.createNewWar(action)
    if (not gameData) then
        return {
            actionName = "Message",
            message    = "Server: translateNewWar() failed: " .. err
        }
    else
        return {
            actionName = "NewWar",
            message    = "The game is created successfully. Please wait for other players to join."
        }
    end
end

local function translateGetOngoingWarList(action)
    local list = {}
    for sceneWarFileName, item in pairs(PlayerProfileManager.getPlayerProfile(action.playerAccount).warLists.ongoing) do
        list[sceneWarFileName] = {
            isInTurn      = item.isInTurn,
            configuration = SceneWarManager.getOngoingSceneWarConfiguration(sceneWarFileName),
        }
    end

    return {
        actionName = "GetOngoingWarList",
        list       = list,
    }
end

local function translateGetSceneWarData(action)
    local data = SceneWarManager.getOngoingSceneWarData(action.fileName)
    if (not data) then
        ngx.log(ngx.ERR, "ActionTranslator-translateGetSceneWarData() failed to get the data with the param action.fileName: ", action.fileName)
        return {
            actionName = "Message",
            message    = "Server: translateGetSceneWarData() failed to get the data with the param action.fileName."
        }
    else
        return {
            actionName = "GetSceneWarData",
            data       = data,
        }
    end
end

local function translateGetJoinableWarList(action)
    local list, err = SceneWarManager.getJoinableSceneWarList(action.playerAccount)
    if (not list) then
        return {
            actionName = "Message",
            message    = "Server: failed to get the joinable war list: " .. (err or "")
        }
    else
        return {
            actionName = "GetJoinableWarList",
            list       = list,
        }
    end
end

local function translateJoinWar(action)
    local msg, err = SceneWarManager.joinWar(action)
    if (not msg) then
        return {
            actionName = "Message",
            message    = "Server: failed to join the war: " .. err,
        }
    else
        return {
            actionName = "JoinWar",
            message    = msg,
        }
    end
end

--------------------------------------------------------------------------------
-- The public functions.
--------------------------------------------------------------------------------
function ActionTranslator.translate(action, session)
    if (type(action) ~= "table") then
        return {
            actionName = "Error",
            error      = "Server: Illegal param action from the client: table expected. Please try again."
        }
    end

    local actionName = action.actionName
    if (actionName == "Login") then
        return translateLogin(action, session)
    elseif (actionName == "Register") then
        return translateRegister(action)
    end

    if (PlayerProfileManager.isAccountAndPasswordValid(action.playerAccount, action.playerPassword)) then
        session:subscribeToPlayerChannel(action.playerAccount, action.playerPassword)
    else
        return {
            actionName = "Logout",
            message    = "Invalid account/password. Please login again.",
        }
    end

    if (actionName == "NewWar") then
        return translateNewWar(action)
    elseif (actionName == "GetOngoingWarList") then
        return translateGetOngoingWarList(action)
    elseif (actionName == "GetSceneWarData") then
        return translateGetSceneWarData(action)
    elseif (actionName == "GetJoinableWarList") then
        return translateGetJoinableWarList(action)
    elseif (actionName == "JoinWar") then
        return translateJoinWar(action)
    end

    local modelSceneWar = SceneWarManager.getOngoingModelSceneWar(action.sceneWarFileName)
    if (actionName == "BeginTurn") then
        return translateBeginTurn(    action, modelSceneWar)
    elseif (actionName == "EndTurn") then
        return translateEndTurn(      action, modelSceneWar)
    elseif (actionName == "Wait") then
        return translateWait(         action, modelSceneWar)
    elseif (actionName == "Attack") then
        return translateAttack(       action, modelSceneWar)
    elseif (actionName == "Capture") then
        return translateCapture(      action, modelSceneWar)
    elseif (actionName == "ProduceOnTile") then
        return translateProduceOnTile(action, modelSceneWar)
    end

    return {
        actionName = "Error",
        error      = "Server: unrecognized action name from the client: " .. actionName,
    }
end

return ActionTranslator
