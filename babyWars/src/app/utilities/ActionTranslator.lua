
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
local LocalizationFunctions  = require("babyWars.src.app.utilities.LocalizationFunctions")

--------------------------------------------------------------------------------
-- The util functions.
--------------------------------------------------------------------------------
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
local function translateLogin(action, session)
    local account, password = action.account, action.password
    if (not PlayerProfileManager.isAccountAndPasswordValid(account, password)) then
        return {
            actionName = "Message",
            message    = LocalizationFunctions.getLocalizedText(22),
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
                message    = LocalizationFunctions.getLocalizedText(21, account),
            }
        else
            return actionLogin, {
                [account] = {
                    actionName = "Logout",
                    message    = LocalizationFunctions.getLocalizedText(23, account),
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
            message    = LocalizationFunctions.getLocalizedText(25),
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
    local sceneWarFileName, err = SceneWarManager.createNewWar(action)
    if (not sceneWarFileName) then
        return {
            actionName = "Message",
            message    = LocalizationFunctions.getLocalizedText(50, err)
        }
    else
        return {
            actionName = "NewWar",
            message    = LocalizationFunctions.getLocalizedText(51, sceneWarFileName:sub(13))
        }
    end
end

local function translateGetOngoingWarList(action)
    local list                            = {}
    local account                         = action.playerAccount
    local isPlayerInTurn                  = SceneWarManager.isPlayerInTurn
    local getOngoingSceneWarConfiguration = SceneWarManager.getOngoingSceneWarConfiguration

    for sceneWarFileName, _ in pairs(PlayerProfileManager.getPlayerProfile(account).warLists.ongoing) do
        list[sceneWarFileName] = {
            isInTurn      = isPlayerInTurn(sceneWarFileName, account),
            configuration = getOngoingSceneWarConfiguration(sceneWarFileName),
        }
    end

    return {
        actionName = "GetOngoingWarList",
        list       = list,
    }
end

local function translateGetSceneWarData(action)
    local data, err = SceneWarManager.getOngoingSceneWarData(action.fileName)
    if (not data) then
        return {
            actionName = "Message",
            message    = LocalizationFunctions.getLocalizedText(52)
        }
    else
        return {
            actionName = "GetSceneWarData",
            data       = data,
        }
    end
end

local function translateGetJoinableWarList(action)
    local list, err = SceneWarManager.getJoinableSceneWarList(action.playerAccount, action.sceneWarShortName)
    if (not list) then
        return {
            actionName = "Message",
            message    = LocalizationFunctions.getLocalizedText(53, err)
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
            message    = LocalizationFunctions.getLocalizedText(54, err),
        }
    else
        return {
            actionName = "JoinWar",
            message    = msg,
        }
    end
end

-- This translation ignores the existing unit of the same player at the end of the path, so that the actions of Join/Attack/Wait can reuse this function.
local function translatePath(path, modelSceneWar)
    local modelWarField    = modelSceneWar:getModelWarField()
    local modelTurnManager = modelSceneWar:getModelTurnManager()
    local modelUnitMap     = modelWarField:getModelUnitMap()
    local modelTileMap     = modelWarField:getModelTileMap()

    local playerIndexInTurn = modelTurnManager:getPlayerIndex()
    local focusModelUnit    = modelUnitMap:getModelUnit(path[1].gridIndex)
    if (not focusModelUnit) then
        return nil, "ActionTranslator-translatePath() there is no unit on the starting grid of the path."
    elseif (focusModelUnit:getPlayerIndex() ~= playerIndexInTurn) then
        return nil, "ActionTranslator-translatePath() the owner player of the moving unit is not in his turn."
    elseif (focusModelUnit:getState() ~= "idle") then
        return nil, "ActionTranslator-translatePath() the moving unit is not in idle state."
    end

    local modelWeatherManager  = modelSceneWar:getModelWeatherManager()
    local moveType             = focusModelUnit:getMoveType()
    local totalFuelConsumption = 0
    local translatedPath       = {GridIndexFunctions.clone(path[1].gridIndex)}

    for i = 2, #path do
        local gridIndex = GridIndexFunctions.clone(path[i].gridIndex)
        if (not GridIndexFunctions.isAdjacent(path[i - 1].gridIndex, gridIndex)) then
            return nil, "ActionTranslator-translatePath() the path is invalid because some grids are not adjacent to previous ones."
        end

        local existingModelUnit = modelUnitMap:getModelUnit(gridIndex)
        if ((existingModelUnit) and (existingModelUnit:getPlayerIndex() ~= playerIndexInTurn)) then
            if (isModelUnitVisible(existingModelUnit, modelWeatherManager)) then
                return nil, "ActionTranslator-translatePath() the path is invalid because it is blocked by a visible enemy unit."
            else
                translatedPath.isBlocked = true
                break
            end
        end

        local fuelConsumption = modelTileMap:getModelTile(gridIndex):getMoveCost(moveType)
        if (not fuelConsumption) then
            return nil, "ActionTranslator-translatePath() the path is invalid because some tiles on it is impassable."
        end

        totalFuelConsumption = totalFuelConsumption + fuelConsumption
        translatedPath[#translatedPath + 1] = gridIndex
    end

    local modelPlayerManager = modelSceneWar:getModelPlayerManager()
    local modelPlayerInTurn  = modelPlayerManager:getModelPlayer(playerIndexInTurn)
    local modelWeather       = modelWeatherManager:getCurrentWeather()
    if ((totalFuelConsumption > focusModelUnit:getCurrentFuel()) or
        (totalFuelConsumption > focusModelUnit:getMoveRange(modelPlayerInTurn, modelWeather))) then
        return nil, "ActionTranslator-translatePath() the path is invalid because the fuel consumption is too high."
    else
        translatedPath.fuelConsumption = totalFuelConsumption
        return translatedPath
    end
end

local function translateBeginTurn(action, modelScene)
    local modelTurnManager = modelScene:getModelTurnManager()
    local playerIndex      = modelTurnManager:getPlayerIndex()

    if (modelTurnManager:getTurnPhase() ~= "requestToBegin") then
        ngx.log(ngx.ERR, "ActionTranslator-translateBeginTurn() the current turn phase is expected to be 'requestToBegin'.")
        return {
            actionName = "Message",
            message    = "The current turn phase is invalid. Please reenter the war.",
        }
    end

    local actionBeginTurn = {
        actionName = "BeginTurn",
        fileName   = modelScene:getFileName(),
    }
    SceneWarManager.updateModelSceneWarWithAction(modelScene:getFileName(), actionBeginTurn)

    local modelPlayerManager = modelScene:getModelPlayerManager()
    if (not modelPlayerManager:getModelPlayer(playerIndex):isAlive()) then
        actionBeginTurn.lostPlayerIndex = playerIndex
    end

    return actionBeginTurn, generateActionsForPublish(actionBeginTurn, modelPlayerManager, action.playerAccount)
end

local function translateEndTurn(action, modelScene)
    local modelPlayerManager = modelScene:getModelPlayerManager()
    local modelTurnManager   = modelScene:getModelTurnManager()

    if (modelTurnManager:getTurnPhase() ~= "main") then
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

local function translateSurrender(action, modelScene)
    local sceneWarFileName   = modelScene:getFileName()
    local modelPlayerManager = modelScene:getModelPlayerManager()
    local _, playerIndex     = modelPlayerManager:getModelPlayerWithAccount(action.playerAccount)

    local actionSurrender = {
        actionName      = "Surrender",
        fileName        = sceneWarFileName,
        lostPlayerIndex = playerIndex,
    }

    SceneWarManager.updateModelSceneWarWithAction(sceneWarFileName, actionSurrender)
    return actionSurrender, generateActionsForPublish(actionSurrender, modelPlayerManager, action.playerAccount)
end

local function translateWait(action, modelScene)
    local translatedPath, translateMsg = translatePath(action.path, modelScene)
    if (not translatedPath) then
        return {
            actionName = "Message",
            message    = "Failed to translate the move path. Please reenter the war.\n" .. (translateMsg or ""),
        }
    end

    local modelUnitMap = modelScene:getModelWarField():getModelUnitMap()
    if ((#translatedPath ~= 1) and (modelUnitMap:getModelUnit(translatedPath[#translatedPath]))) then
        return {
            actionName = "Message",
            message    = "There is another unit on the destination grid. Please reenter the war.",
        }
    end

    local sceneWarFileName = modelScene:getFileName()
    local actionWait = {
        actionName = "Wait",
        fileName   = sceneWarFileName,
        path       = translatedPath,
    }

    SceneWarManager.updateModelSceneWarWithAction(sceneWarFileName, actionWait)
    return actionWait, generateActionsForPublish(actionWait, modelScene:getModelPlayerManager(), action.playerAccount)
end

local function translateAttack(action, modelScene)
    local translatedPath, translateMsg = translatePath(action.path, modelScene)
    if (not translatedPath) then
        return {
            actionName = "Message",
            message    = "Failed to translate the move path. Please reenter the war.\n" .. (translateMsg or ""),
        }
    end

    local sceneWarFileName   = modelScene:getFileName()
    local modelPlayerManager = modelScene:getModelPlayerManager()
    if (translatedPath.isBlocked) then
        local actionWait = {
            actionName = "Wait",
            fileName   = sceneWarFileName,
            path       = translatedPath,
        }
        SceneWarManager.updateModelSceneWarWithAction(sceneWarFileName, actionWait)
        return actionWait, generateActionsForPublish(actionWait, modelPlayerManager, action.playerAccount)
    end

    local modelWarField     = modelScene:getModelWarField()
    local modelUnitMap      = modelWarField:getModelUnitMap()
    local attackerGridIndex = translatedPath[#translatedPath]
    if ((#translatedPath ~= 1) and (modelUnitMap:getModelUnit(attackerGridIndex))) then
        return {
            actionName = "Message",
            message    = "There is another unit on the destination grid. Please reenter the war."
        }
    end

    local modelTileMap      = modelWarField:getModelTileMap()
    local targetGridIndex   = action.targetGridIndex
    local attackerModelUnit = modelUnitMap:getModelUnit(translatedPath[1])
    local attackTarget      = modelUnitMap:getModelUnit(targetGridIndex) or modelTileMap:getModelTile(targetGridIndex)
    if ((not attackerModelUnit.canAttackTarget) or
        (not attackerModelUnit:canAttackTarget(attackerGridIndex, attackTarget, targetGridIndex))) then
        return {
            actionName = "Message",
            message    = "The attacker can't attack the target. Please reenter the war.",
        }
    end

    local modelWeatherManager = modelScene:getModelWeatherManager()
    local attackDamage, counterDamage = attackerModelUnit:getUltimateBattleDamage(modelTileMap:getModelTile(attackerGridIndex), attackTarget, modelTileMap:getModelTile(targetGridIndex), modelPlayerManager, modelWeatherManager:getCurrentWeather())
    local actionAttack = {
        actionName      = "Attack",
        fileName        = sceneWarFileName,
        path            = translatedPath,
        targetGridIndex = GridIndexFunctions.clone(targetGridIndex),
        attackDamage    = attackDamage,
        counterDamage   = counterDamage
    }
    SceneWarManager.updateModelSceneWarWithAction(sceneWarFileName, actionAttack)

    local attackerPlayerIndex = attackerModelUnit:getPlayerIndex()
    local targetPlayerIndex   = attackTarget:getPlayerIndex()
    if (not modelPlayerManager:getModelPlayer(attackerPlayerIndex):isAlive()) then
        actionAttack.lostPlayerIndex = attackerPlayerIndex
    elseif ((targetPlayerIndex ~= 0) and (not modelPlayerManager:getModelPlayer(targetPlayerIndex):isAlive())) then
        actionAttack.lostPlayerIndex = targetPlayerIndex
    end

    local actionsForPublish = generateActionsForPublish(actionAttack, modelPlayerManager, action.playerAccount) or {}
    if ((actionAttack.lostPlayerIndex) and (actionAttack.lostPlayerIndex == targetPlayerIndex)) then
        local lostModelPlayer = modelPlayerManager:getModelPlayer(actionAttack.lostPlayerIndex)
        actionsForPublish[lostModelPlayer:getAccount()] = actionAttack
    end

    return actionAttack, actionsForPublish
end

local function translateCapture(action, modelScene)
    local translatedPath, translateMsg = translatePath(action.path, modelScene)
    if (not translatedPath) then
        return {
            actionName = "Message",
            message    = "Failed to translate the move path: " .. (translateMsg or ""),
        }
    end

    local sceneWarFileName   = modelScene:getFileName()
    local modelPlayerManager = modelScene:getModelPlayerManager()
    if (translatedPath.isBlocked) then
        local actionWait = {
            actionName = "Wait",
            fileName   = sceneWarFileName,
            path       = translatedPath,
        }
        SceneWarManager.updateModelSceneWarWithAction(sceneWarFileName, actionWait)
        return actionWait, generateActionsForPublish(actionWait, modelPlayerManager, action.playerAccount)
    end

    local modelWarField   = modelScene:getModelWarField()
    local modelUnitMap    = modelWarField:getModelUnitMap()
    local targetGridIndex = translatedPath[#translatedPath]
    if ((#translatedPath ~= 1) and (modelUnitMap:getModelUnit(targetGridIndex))) then
        return {
            actionName = "Message",
            message    = "Failed because there's another unit on the target grid. Please reenter the war.",
        }
    end

    local modelTileMap      = modelWarField:getModelTileMap()
    local capturerModelUnit = modelUnitMap:getModelUnit(translatedPath[1])
    local targetModelTile   = modelTileMap:getModelTile(targetGridIndex)
    if ((not capturerModelUnit.canCapture) or
        (not capturerModelUnit:canCapture(targetModelTile))) then
        return {
            actionName = "Message",
            message    = "Failed because the focus unit can't capture the target tile. Please reenter the war."
        }
    end

    local targetPlayerIndex = targetModelTile:getPlayerIndex()
    local actionCapture     = {
        actionName = "Capture",
        fileName   = sceneWarFileName,
        path       = translatedPath,
    }
    SceneWarManager.updateModelSceneWarWithAction(sceneWarFileName, actionCapture)

    if ((targetPlayerIndex ~= 0) and (not modelPlayerManager:getModelPlayer(targetPlayerIndex):isAlive())) then
        actionCapture.lostPlayerIndex = targetPlayerIndex
    end

    local actionsForPublish = generateActionsForPublish(actionCapture, modelPlayerManager, action.playerAccount) or {}
    if (actionCapture.lostPlayerIndex) then
        local lostModelPlayer = modelPlayerManager:getModelPlayer(actionCapture.lostPlayerIndex)
        actionsForPublish[lostModelPlayer:getAccount()] = actionCapture
    end

    return actionCapture, actionsForPublish
end

local function translateProduceOnTile(action, modelScene)
    local playerIndex        = modelScene:getModelTurnManager():getPlayerIndex()
    local modelPlayerManager = modelScene:getModelPlayerManager()
    local modelPlayer        = modelPlayerManager:getModelPlayer(playerIndex)
    local modelWarField      = modelScene:getModelWarField()
    local gridIndex          = action.gridIndex
    local tiledID            = action.tiledID

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

    local playerAccount = action.playerAccount
    if (PlayerProfileManager.isAccountAndPasswordValid(playerAccount, action.playerPassword)) then
        session:subscribeToPlayerChannel(playerAccount, action.playerPassword)
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

    local sceneWarFileName = action.sceneWarFileName
    if (not SceneWarManager.isPlayerInTurn(sceneWarFileName, playerAccount)) then
        return {
            actionName = "Message",
            message    = "You are not the in-turn player. Please reenter the war."
        }
    end

    local modelSceneWar, err = SceneWarManager.getOngoingModelSceneWar(sceneWarFileName)
    if (not modelSceneWar) then
        return {
            actionName = "Message",
            message    = "The war is ended or invalid. Please go back to the main menu.\n" .. err
        }
    end

    if (actionName == "BeginTurn") then
        return translateBeginTurn(    action, modelSceneWar)
    elseif (actionName == "EndTurn") then
        return translateEndTurn(      action, modelSceneWar)
    elseif (actionName == "Surrender") then
        return translateSurrender(    action, modelSceneWar)
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
