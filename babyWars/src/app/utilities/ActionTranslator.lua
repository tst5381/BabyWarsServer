
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

local Producible              = require("src.app.components.Producible")
local ModelSkillConfiguration = require("src.app.models.common.ModelSkillConfiguration")
local Actor                   = require("src.global.actors.Actor")
local ActionCodeFunctions     = require("src.app.utilities.ActionCodeFunctions")
local ActionPublisher         = require("src.app.utilities.ActionPublisher")
local DamageCalculator        = require("src.app.utilities.DamageCalculator")
local GameConstantFunctions   = require("src.app.utilities.GameConstantFunctions")
local GridIndexFunctions      = require("src.app.utilities.GridIndexFunctions")
local LocalizationFunctions   = require("src.app.utilities.LocalizationFunctions")
local PlayerProfileManager    = require("src.app.utilities.PlayerProfileManager")
local SceneWarManager         = require("src.app.utilities.SceneWarManager")
local SerializationFunctions  = require("src.app.utilities.SerializationFunctions")
local SkillDataAccessors      = require("src.app.utilities.SkillDataAccessors")
local SkillModifierFunctions  = require("src.app.utilities.SkillModifierFunctions")
local SingletonGetters        = require("src.app.utilities.SingletonGetters")
local TableFunctions          = require("src.app.utilities.TableFunctions")
local VisibilityFunctions     = require("src.app.utilities.VisibilityFunctions")
local ComponentManager        = require("src.global.components.ComponentManager")

local createActionsForPublish      = ActionPublisher.createActionsForPublish
local getLocalizedText             = LocalizationFunctions.getLocalizedText
local getModelFogMap               = SingletonGetters.getModelFogMap
local getModelPlayerManager        = SingletonGetters.getModelPlayerManager
local getModelTileMap              = SingletonGetters.getModelTileMap
local getModelTurnManager          = SingletonGetters.getModelTurnManager
local getModelUnitMap              = SingletonGetters.getModelUnitMap
local getRevealedTilesAndUnitsData = VisibilityFunctions.getRevealedTilesAndUnitsData
local isUnitVisible                = VisibilityFunctions.isUnitOnMapVisibleToPlayerIndex

local ACTION_CODES                   = ActionCodeFunctions.getFullList()
local GAME_VERSION                   = GameConstantFunctions.getGameVersion()
local IGNORED_ACTION_KEYS_FOR_SERVER = {"revealedTiles", "revealedUnits"}
local MESSAGE_PARAM_OUT_OF_SYNC      = {"OutOfSync"}
local SKILL_CONFIGURATIONS_COUNT     = SkillDataAccessors.getSkillConfigurationsCount()

local LOGOUT_INVALID_ACCOUNT_PASSWORD = {
    actionCode    = ACTION_CODES.ActionLogout,
    messageCode   = 81,
    messageParams = {"InvalidAccountOrPassword"},
}
local MESSAGE_CORRUPTED_ACTION = {
    actionCode    = ACTION_CODES.ActionMessage,
    messageCode   = 81,
    messageParams = {"CorruptedAction"},
}
local MESSAGE_DEFEATED_PLAYER = {
    actionCode    = ACTION_CODES.ActionMessage,
    messageCode   = 81,
    messageParams = {"DefeatedPlayer"},
}
local MESSAGE_ENDED_WAR = {
    actionCode    = ACTION_CODES.ActionMessage,
    messageCode   = 81,
    messageParams = {"EndedWar"},
}
local MESSAGE_MULTI_JOIN_WAR = {
    actionCode    = ACTION_CODES.ActionMessage,
    messageCode   = 81,
    messageParams = {"MultiJoinWar"},
}
local MESSAGE_INVALID_GAME_VERSION = {
    actionCode    = ACTION_CODES.ActionMessage,
    messageCode   = 81,
    messageParams = {"InvalidGameVersion", GAME_VERSION},
}
local MESSAGE_INVALID_LOGIN = {
    actionCode    = ACTION_CODES.ActionMessage,
    messageCode   = 81,
    messageParams = {"InvalidLogin"},
}
local MESSAGE_INVALID_SKILL_CONFIGURATION = {
    actionCode    = ACTION_CODES.ActionMessage,
    messageCode   = 81,
    messageParams = {"InvalidSkillConfiguration"},
}
local MESSAGE_INVALID_WAR_PASSWORD = {
    actionCode    = ACTION_CODES.ActionMessage,
    messageCode   = 81,
    messageParams = {"InvalidWarPassword"},
}
local MESSAGE_NO_REPLAY_DATA = {
    actionCode    = ACTION_CODES.ActionMessage,
    messageCode   = 81,
    messageParams = {"NoReplayData"},
}
local MESSAGE_NOT_JOINABLE_WAR = {
    actionCode    = ACTION_CODES.ActionMessage,
    messageCode   = 81,
    messageParams = {"NotJoinableWar"},
}
local MESSAGE_OCCUPIED_PLAYER_INDEX = {
    actionCode    = ACTION_CODES.ActionMessage,
    messageCode   = 81,
    messageParams = {"OccupiedPlayerIndex"},
}
local MESSAGE_OVERLOADED_SKILL_POINTS = {
    actionCode    = ACTION_CODES.ActionMessage,
    messageCode   = 81,
    messageParams = {"OverloadedSkillPoints"},
}
local MESSAGE_REGISTERED_ACCOUNT = {
    actionCode    = ACTION_CODES.ActionMessage,
    messageCode   = 81,
    messageParams = {"RegisteredAccount"},
}
local RUN_SCENE_MAIN_DEFEATED_PLAYER = {
    actionCode    = ACTION_CODES.ActionRunSceneMain,
    messageCode   = 81,
    messageParams = {"DefeatedPlayer"},
}
local RUN_SCENE_MAIN_ENDED_WAR = {
    actionCode    = ACTION_CODES.ActionRunSceneMain,
    messageCode   = 81,
    messageParams = {"EndedWar"},
}

--------------------------------------------------------------------------------
-- The util functions.
--------------------------------------------------------------------------------
local function isGridInPathNodes(gridIndex, pathNodes)
    for _, node in ipairs(pathNodes) do
        if (GridIndexFunctions.isEqual(gridIndex, node)) then
            return true
        end
    end

    return false
end

local function isModelUnitDiving(modelUnit)
    return (modelUnit.isDiving) and (modelUnit:isDiving())
end

local function isPathDestinationOccupiedByVisibleUnit(modelSceneWar, rawPath)
    local pathNodes  = rawPath.pathNodes
    local pathLength = #pathNodes
    if (pathLength == 1) then
        return false
    end

    local modelUnitMap = getModelUnitMap(modelSceneWar)
    local destination  = pathNodes[pathLength]
    local playerIndex  = modelUnitMap:getModelUnit(pathNodes[1]):getPlayerIndex()
    local modelUnit    = modelUnitMap:getModelUnit(destination)
    return (modelUnit) and
        (isUnitVisible(modelSceneWar:getFileName(), destination, modelUnit:getUnitType(), isModelUnitDiving(modelUnit), modelUnit:getPlayerIndex(), playerIndex))
end

local function isDropBlocked(destination, modelUnitMap, loaderModelUnit)
    local existingModelUnit = modelUnitMap:getModelUnit(destination.gridIndex)
    return (existingModelUnit) and (existingModelUnit ~= loaderModelUnit)
end

local function countModelUnitOnMapWithPlayerIndex(modelUnitMap, playerIndex)
    local count = 0
    modelUnitMap:forEachModelUnitOnMap(function(modelUnit)
        if (modelUnit:getPlayerIndex() == playerIndex) then
            count = count + 1
        end
    end)

    return count
end

local function getIncomeOnBeginTurn(modelSceneWar)
    local playerIndex = getModelTurnManager(modelSceneWar):getPlayerIndex()
    local income      = 0
    getModelTileMap(modelSceneWar):forEachModelTile(function(modelTile)
        if ((modelTile.getIncomeAmount) and (modelTile:getPlayerIndex() == playerIndex)) then
            income = income + (modelTile:getIncomeAmount() or 0)
        end
    end)

    return income
end

local function areAllUnitsDestroyedOnBeginTurn(modelSceneWar)
    local playerIndex   = getModelTurnManager(modelSceneWar):getPlayerIndex()
    local modelTileMap  = getModelTileMap(modelSceneWar)
    local modelUnitMap  = getModelUnitMap(modelSceneWar)
    local mapSize       = modelUnitMap:getMapSize()
    local width, height = mapSize.width, mapSize.height
    local hasUnit       = false

    for x = 1, width do
        for y = 1, height do
            local gridIndex = {x = x, y = y}
            local modelUnit = modelUnitMap:getModelUnit(gridIndex)
            if ((modelUnit) and (modelUnit:getPlayerIndex() == playerIndex)) then
                hasUnit = true
                if ((modelUnit.getCurrentFuel)                                            and
                    (modelUnit:getCurrentFuel() <= modelUnit:getFuelConsumptionPerTurn()) and
                    (modelUnit:shouldDestroyOnOutOfFuel()))                               then

                    local modelTile = modelTileMap:getModelTile(gridIndex)
                    if ((modelTile.canRepairTarget) and (modelTile:canRepairTarget(modelUnit))) then
                        return false
                    end
                else
                    return false
                end
            end
        end
    end

    return hasUnit
end

local function getRepairableModelUnits(modelSceneWar)
    local playerIndex  = getModelTurnManager(modelSceneWar):getPlayerIndex()
    local modelUnitMap = getModelUnitMap(modelSceneWar)
    local modelTileMap = getModelTileMap(modelSceneWar)
    local units        = {}

    modelUnitMap:forEachModelUnitOnMap(function(modelUnit)
            if (modelUnit:getPlayerIndex() == playerIndex) then
                local modelTile = modelTileMap:getModelTile(modelUnit:getGridIndex())
                if ((modelTile.canRepairTarget) and (modelTile:canRepairTarget(modelUnit))) then
                    units[#units + 1] = modelUnit
                end
            end
        end)
        :forEachModelUnitLoaded(function(modelUnit)
            if (modelUnit:getPlayerIndex() == playerIndex) then
                local loader = modelUnitMap:getModelUnit(modelUnit:getGridIndex())
                if ((loader:canRepairLoadedModelUnit()) and (loader:hasLoadUnitId(modelUnit:getUnitId()))) then
                    units[#units + 1] = modelUnit
                end
            end
        end)

    table.sort(units, function(unit1, unit2)
        local cost1, cost2 = unit1:getProductionCost(), unit2:getProductionCost()
        return (cost1 > cost2)                                             or
            ((cost1 == cost2) and (unit1:getUnitId() < unit2:getUnitId()))
    end)

    return units
end

local function getRepairAmountAndCost(modelUnit, fund, maxNormalizedRepairAmount, costModifier)
    local productionCost         = math.floor(modelUnit:getProductionCost() * costModifier)
    local normalizedCurrentHP    = modelUnit:getNormalizedCurrentHP()
    local normalizedRepairAmount = math.min(
        10 - normalizedCurrentHP,
        maxNormalizedRepairAmount,
        math.floor(fund * 10 / productionCost)
    )

    return (normalizedRepairAmount + normalizedCurrentHP) * 10 - modelUnit:getCurrentHP(),
        math.floor(normalizedRepairAmount * productionCost / 10)
end

local function generateRepairDataOnBeginTurn(modelSceneWar)
    local modelUnitMap              = getModelUnitMap(modelSceneWar)
    local modelPlayer               = getModelPlayerManager(modelSceneWar):getModelPlayer(getModelTurnManager(modelSceneWar):getPlayerIndex())
    local skillConfiguration        = modelPlayer:getModelSkillConfiguration()
    local fund                      = modelPlayer:getFund() + getIncomeOnBeginTurn(modelSceneWar)
    local maxNormalizedRepairAmount = GameConstantFunctions.getBaseNormalizedRepairAmount() + SkillModifierFunctions.getRepairAmountModifier(skillConfiguration)
    local costModifier              = SkillModifierFunctions.getRepairCostModifier(skillConfiguration)
    if (costModifier >= 0) then
        costModifier = (100 + costModifier) / 100
    else
        costModifier = 100 / (100 - costModifier)
    end

    local onMapData  = {}
    local loadedData = {}
    for _, modelUnit in ipairs(getRepairableModelUnits(modelSceneWar)) do
        local repairAmount, repairCost = getRepairAmountAndCost(modelUnit, fund, maxNormalizedRepairAmount, costModifier)
        local unitID                   = modelUnit:getUnitId()
        if (modelUnitMap:getLoadedModelUnitWithUnitId(unitID)) then
            loadedData[unitID] = {
                unitID       = unitID,
                repairAmount = repairAmount,
            }
        else
            onMapData[unitID] = {
                unitID       = unitID,
                repairAmount = repairAmount,
                gridIndex    = GridIndexFunctions.clone(modelUnit:getGridIndex()),
            }
        end
        fund = fund - repairCost
    end

    return {
        onMapData     = onMapData,
        loadedData    = loadedData,
        remainingFund = fund,
    }
end

local function canDoActionSupplyModelUnit(focusModelUnit, destination, modelUnitMap)
    if (focusModelUnit.canSupplyModelUnit) then
        for _, gridIndex in pairs(GridIndexFunctions.getAdjacentGrids(destination, modelUnitMap:getMapSize())) do
            local modelUnit = modelUnitMap:getModelUnit(gridIndex)
            if ((modelUnit)                                     and
                (modelUnit ~= focusModelUnit)                   and
                (focusModelUnit:canSupplyModelUnit(modelUnit))) then
                return true
            end
        end
    end

    return false
end

local function validateDropDestinations(action, modelSceneWar)
    local isEqual                  = GridIndexFunctions.isEqual
    local isAdjacent               = GridIndexFunctions.isAdjacent
    local isWithinMap              = GridIndexFunctions.isWithinMap
    local sceneWarFileName         = modelSceneWar:getFileName()
    local modelWarField            = modelSceneWar:getModelWarField()
    local modelUnitMap             = modelWarField:getModelUnitMap()
    local modelTileMap             = modelWarField:getModelTileMap()
    local destinations             = action.dropDestinations
    local mapSize                  = modelTileMap:getMapSize()
    local loaderBeginningGridIndex = action.path[1]
    local loaderEndingGridIndex    = action.path[#action.path]
    local loaderModelUnit          = modelUnitMap:getFocusModelUnit(loaderBeginningGridIndex, action.launchUnitID)
    local loaderEndingModelTile    = modelTileMap:getModelTile(loaderEndingGridIndex)
    local loadedUnitIdList         = loaderModelUnit:getLoadUnitIdList()
    local playerIndex              = loaderModelUnit:getPlayerIndex()

    if (#destinations < 1) then
        return false
    end

    for i = 1, #destinations do
        local droppingUnitID = destinations[i].unitID
        if (not loaderModelUnit:hasLoadUnitId(droppingUnitID)) then
            return false
        end

        local droppingGridIndex = destinations[i].gridIndex
        local droppingModelUnit = modelUnitMap:getLoadedModelUnitWithUnitId(droppingUnitID)
        if ((not droppingModelUnit)                                     or
            (not isWithinMap(droppingGridIndex, mapSize))               or
            (not isAdjacent(droppingGridIndex, loaderEndingGridIndex))) then
            return false
        else
            if ((not loaderEndingModelTile:getMoveCostWithModelUnit(droppingModelUnit))                         or
                (not modelTileMap:getModelTile(droppingGridIndex):getMoveCostWithModelUnit(droppingModelUnit))) then
                return false
            end

            local existingModelUnit = modelUnitMap:getModelUnit(droppingGridIndex)
            if ((existingModelUnit)                                                                                                                          and
                (existingModelUnit ~= loaderModelUnit)                                                                                                       and
                (isUnitVisible(sceneWarFileName, droppingGridIndex, existingModelUnit:getUnitType(), isModelUnitDiving(existingModelUnit), existingModelUnit:getPlayerIndex(), playerIndex))) then
                return false
            end
        end

        for j = i + 1, #destinations do
            local additionalDestination = destinations[j]
            if ((isEqual(droppingGridIndex, additionalDestination.gridIndex)) or
                (droppingUnitID == additionalDestination.unitID))             then
                return false
            end
        end
    end

    return true
end

local function translateDropDestinations(rawDestinations, modelUnitMap, loaderModelUnit)
    local translatedDestinations = {}
    for i = 1, #rawDestinations do
        if (isDropBlocked(rawDestinations[i], modelUnitMap, loaderModelUnit)) then
            translatedDestinations.isBlocked = true
            break
        else
            translatedDestinations[#translatedDestinations + 1] = rawDestinations[i]
        end
    end

    return translatedDestinations
end

local function getLostPlayerIndexForActionAttack(attacker, target, attackDamage, counterDamage)
    local modelUnitMap = getModelUnitMap(attacker:getSceneWarFileName())
    if ((target.getUnitType) and (attackDamage >= target:getCurrentHP())) then
        local playerIndex = target:getPlayerIndex()
        if (countModelUnitOnMapWithPlayerIndex(modelUnitMap, playerIndex) == 1) then
            return playerIndex
        end
    elseif ((counterDamage) and (counterDamage >= attacker:getCurrentHP())) then
        local playerIndex = attacker:getPlayerIndex()
        if (countModelUnitOnMapWithPlayerIndex(modelUnitMap, playerIndex) == 1) then
            return playerIndex
        end
    else
        return nil
    end
end

local function createActionReloadOrExitWar(sceneWarFileName, playerAccount, message)
    local modelSceneWar = SceneWarManager.getOngoingModelSceneWar(sceneWarFileName)
    if (not modelSceneWar) then
        return {
            actionName = "RunSceneMain",
            fileName   = sceneWarFileName,
            message    = getLocalizedText(81, "InvalidWarFileName"),
        }
    end

    modelSceneWar:getModelPlayerManager():forEachModelPlayer(function(modelPlayer, playerIndex)
        if ((modelPlayer:isAlive()) and (modelPlayer:getAccount() == playerAccount)) then
            return {
                actionName = "ReloadSceneWar",
                fileName   = sceneWarFileName,
                data       = modelSceneWar:toSerializableTableForPlayerIndex(playerIndex),
                message    = message,
            }
        end
    end)

    return {
        actionName = "RunSceneMain",
        fileName   = sceneWarFileName,
        message    = getLocalizedText(81, "InvalidWarFileName"),
    }
end

local function createActionForServer(action)
    return TableFunctions.clone(action, IGNORED_ACTION_KEYS_FOR_SERVER)
end

local function createActionReloadSceneWar(modelSceneWar, playerAccount, messageCode, messageParams)
    local _, playerIndex = modelSceneWar:getModelPlayerManager():getModelPlayerWithAccount(playerAccount)
    return {
        actionCode    = ACTION_CODES.ActionReloadSceneWar,
        warData       = modelSceneWar:toSerializableTableForPlayerIndex(playerIndex),
        messageCode   = messageCode,
        messageParams = messageParams,
    }
end

local function isPlayerInTurnInWar(modelSceneWar, playerAccount)
    local playerIndex = modelSceneWar:getModelTurnManager():getPlayerIndex()
    return modelSceneWar:getModelPlayerManager():getModelPlayer(playerIndex):getAccount() == playerAccount
end

local function isPlayerAliveInWar(modelSceneWar, playerAccount)
    local modelPlayer = modelSceneWar:getModelPlayerManager():getModelPlayerWithAccount(playerAccount)
    return (modelPlayer) and (modelPlayer:isAlive())
end

local function getModelSceneWarWithAction(action)
    local playerAccount = action.playerAccount
    if (not PlayerProfileManager.isAccountAndPasswordValid(action.playerAccount, action.playerPassword)) then
        return nil, LOGOUT_INVALID_ACCOUNT_PASSWORD
    end

    local modelSceneWar = SceneWarManager.getOngoingModelSceneWar(action.sceneWarFileName)
    if (not modelSceneWar) then
        return nil, RUN_SCENE_MAIN_ENDED_WAR
    elseif (not isPlayerAliveInWar(modelSceneWar, playerAccount)) then
        return nil, RUN_SCENE_MAIN_DEFEATED_PLAYER
    elseif ((not isPlayerInTurnInWar(modelSceneWar, playerAccount)) or (modelSceneWar:getActionId() ~= action.actionID - 1)) then
        return nil, createActionReloadSceneWar(modelSceneWar, playerAccount, 81, MESSAGE_PARAM_OUT_OF_SYNC)
    else
        return modelSceneWar
    end
end

--------------------------------------------------------------------------------
-- The translate functions.
--------------------------------------------------------------------------------
local function translateDownloadReplayData(action)
    local encodedReplayData = SceneWarManager.getEncodedReplayData(action.sceneWarFileName)
    if (not encodedReplayData) then
        return MESSAGE_NO_REPLAY_DATA
    else
        return {
            actionCode        = ACTION_CODES.ActionDownloadReplayData,
            encodedReplayData = encodedReplayData,
        }
    end
end

local function translateGetSkillConfiguration(action)
    if (not PlayerProfileManager.isAccountAndPasswordValid(action.playerAccount, action.playerPassword)) then
        return LOGOUT_INVALID_ACCOUNT_PASSWORD
    end

    local skillConfigurationID = action.skillConfigurationID
    return {
        actionCode           = ACTION_CODES.ActionGetSkillConfiguration,
        skillConfigurationID = skillConfigurationID,
        skillConfiguration   = PlayerProfileManager.getSkillConfiguration(action.playerAccount, skillConfigurationID),
    }
end

local function translateJoinWar(action)
    local playerAccount = action.playerAccount
    if (not PlayerProfileManager.isAccountAndPasswordValid(playerAccount, action.playerPassword)) then
        return LOGOUT_INVALID_ACCOUNT_PASSWORD
    end

    local sceneWarFileName = action.sceneWarFileName
    local warConfiguration = SceneWarManager.getJoinableSceneWarConfiguration(sceneWarFileName)
    if (not warConfiguration) then
        return MESSAGE_NOT_JOINABLE_WAR
    elseif (warConfiguration.warPassword ~= action.warPassword) then
        return MESSAGE_INVALID_WAR_PASSWORD
    elseif (SceneWarManager.hasPlayerJoinedWar(playerAccount, warConfiguration)) then
        return MESSAGE_MULTI_JOIN_WAR
    elseif (warConfiguration.players[action.playerIndex]) then
        return MESSAGE_OCCUPIED_PLAYER_INDEX
    end

    local skillConfigurationID = action.skillConfigurationID
    if (skillConfigurationID) then
        local maxBaseSkillPoints = warConfiguration.maxBaseSkillPoints
        if (not maxBaseSkillPoints) then
            return MESSAGE_OVERLOADED_SKILL_POINTS

        elseif (skillConfigurationID < 0) then
            if (maxBaseSkillPoints < 100) then
                return MESSAGE_OVERLOADED_SKILL_POINTS
            end

        else
            local skillConfiguration      = PlayerProfileManager.getSkillConfiguration(playerAccount, skillConfigurationID)
            local modelSkillConfiguration = ModelSkillConfiguration:create(skillConfiguration)
            if (modelSkillConfiguration:getBaseSkillPoints() > maxBaseSkillPoints) then
                return MESSAGE_OVERLOADED_SKILL_POINTS
            elseif (not modelSkillConfiguration:isValid()) then
                return MESSAGE_INVALID_SKILL_CONFIGURATION
            end
        end
    end

    return {
        actionCode       = ACTION_CODES.ActionJoinWar,
        sceneWarFileName = sceneWarFileName,
        isWarStarted     = SceneWarManager.isWarReadyForStartAfterJoin(warConfiguration),
    }, nil, action
end

local function translateLogin(action)
    local account, password = action.loginAccount, action.loginPassword
    if (action.clientVersion ~= GAME_VERSION) then
        return MESSAGE_INVALID_GAME_VERSION
    elseif (not PlayerProfileManager.isAccountAndPasswordValid(account, password)) then
        return MESSAGE_INVALID_LOGIN
    else
        return {
            actionCode    = ACTION_CODES.ActionLogin,
            loginAccount  = account,
            loginPassword = password,
        }, {
            [account] = {
                actionCode    = ACTION_CODES.ActionLogout,
                messageCode   = 81,
                messageParams = {"MultiLogin", account},
            }
        }
    end
end

local function translateNetworkHeartbeat(action)
    return {
        actionCode       = ACTION_CODES.ActionNetworkHeartbeat,
        heartbeatCounter = action.heartbeatCounter,
    }
end

local function translateNewWar(action)
    if (not PlayerProfileManager.isAccountAndPasswordValid(action.playerAccount, action.playerPassword)) then
        return LOGOUT_INVALID_ACCOUNT_PASSWORD
    end

    local skillConfigurationID = action.skillConfigurationID
    if (skillConfigurationID) then
        local maxBaseSkillPoints = action.maxBaseSkillPoints
        if (not maxBaseSkillPoints) then
            return MESSAGE_OVERLOADED_SKILL_POINTS

        elseif (skillConfigurationID < 0) then
            if (maxBaseSkillPoints < 100) then
                return MESSAGE_OVERLOADED_SKILL_POINTS
            end

        else
            local skillConfiguration      = PlayerProfileManager.getSkillConfiguration(action.playerAccount, skillConfigurationID)
            local modelSkillConfiguration = ModelSkillConfiguration:create(skillConfiguration)
            if (modelSkillConfiguration:getBaseSkillPoints() > maxBaseSkillPoints) then
                return MESSAGE_OVERLOADED_SKILL_POINTS
            elseif (not modelSkillConfiguration:isValid()) then
                return MESSAGE_INVALID_SKILL_CONFIGURATION
            end
        end
    end

    action.actionCode = ACTION_CODES.ActionNewWar
    -- TODO: validate more params.

    return {
        actionCode       = ACTION_CODES.ActionNewWar,
        sceneWarFileName = SceneWarManager.getNextSceneWarFileName()
    }, nil, action
end

local function translateRegister(action)
    local account, password = action.registerAccount, action.registerPassword
    if (action.clientVersion ~= GAME_VERSION) then
        return MESSAGE_INVALID_GAME_VERSION
    elseif (PlayerProfileManager.isAccountRegistered(account)) then
        return MESSAGE_REGISTERED_ACCOUNT
    else
        local actionRegister = {
            actionCode       = ACTION_CODES.ActionRegister,
            registerAccount  = account,
            registerPassword = password,
        }
        return actionRegister, nil, actionRegister
    end
end

local function translateReloadSceneWar(action)
    local playerAccount = action.playerAccount
    if (not PlayerProfileManager.isAccountAndPasswordValid(action.playerAccount, action.playerPassword)) then
        return nil, LOGOUT_INVALID_ACCOUNT_PASSWORD
    end

    local modelSceneWar = SceneWarManager.getOngoingModelSceneWar(action.sceneWarFileName)
    if (not modelSceneWar) then
        return nil, RUN_SCENE_MAIN_ENDED_WAR
    elseif (not isPlayerAliveInWar(modelSceneWar, playerAccount)) then
        return nil, RUN_SCENE_MAIN_DEFEATED_PLAYER
    else
        return createActionReloadSceneWar(modelSceneWar, playerAccount)
    end
end

local function translateRunSceneWar(action)
    local playerAccount = action.playerAccount
    if (not PlayerProfileManager.isAccountAndPasswordValid(playerAccount, action.playerPassword)) then
        return LOGOUT_INVALID_ACCOUNT_PASSWORD
    end

    local modelSceneWar = SceneWarManager.getOngoingModelSceneWar(action.sceneWarFileName)
    if (not modelSceneWar) then
        return MESSAGE_ENDED_WAR
    elseif (not isPlayerAliveInWar(modelSceneWar, playerAccount)) then
        return MESSAGE_DEFEATED_PLAYER
    else
        local _, playerIndex = modelSceneWar:getModelPlayerManager():getModelPlayerWithAccount(playerAccount)
        return {
            actionCode = ACTION_CODES.ActionRunSceneWar,
            warData    = modelSceneWar:toSerializableTableForPlayerIndex(playerIndex),
        }
    end
end

local function translateSetSkillConfiguration(action)
    if (not PlayerProfileManager.isAccountAndPasswordValid(action.playerAccount, action.playerPassword)) then
        return LOGOUT_INVALID_ACCOUNT_PASSWORD
    end

    local skillConfiguration, skillConfigurationID = action.skillConfiguration, action.skillConfigurationID
    if ((skillConfigurationID < 1)                                          or
        (skillConfigurationID > SKILL_CONFIGURATIONS_COUNT)                 or
        (not ModelSkillConfiguration:create(skillConfiguration):isValid())) then
        return MESSAGE_INVALID_SKILL_CONFIGURATION
    else
        action.actionCode = ACTION_CODES.ActionSetSkillConfiguration
        return {actionCode = ACTION_CODES.ActionSetSkillConfiguration}, nil, action
    end
end

local function translateSyncSceneWar(action)
    local playerAccount = action.playerAccount
    if (not PlayerProfileManager.isAccountAndPasswordValid(playerAccount, action.playerPassword)) then
        return LOGOUT_INVALID_ACCOUNT_PASSWORD
    end

    local modelSceneWar = SceneWarManager.getOngoingModelSceneWar(action.sceneWarFileName)
    if (not modelSceneWar) then
        return RUN_SCENE_MAIN_ENDED_WAR
    elseif (not isPlayerAliveInWar(modelSceneWar, playerAccount)) then
        return RUN_SCENE_MAIN_DEFEATED_PLAYER
    elseif (modelSceneWar:getActionId() > action.actionID) then
        return createActionReloadSceneWar(modelSceneWar, playerAccount, 81, {"AutoSyncWar"})
    else
        return {
            actionCode       = ACTION_CODES.ActionSyncSceneWar,
            actionID         = action.actionID,
            sceneWarFileName = action.sceneWarFileName,
        }
    end
end

local function translateGetReplayConfigurations(action)
    return {
        actionCode           = ACTION_CODES.ActionGetReplayConfigurations,
        replayConfigurations = SceneWarManager.getReplayConfigurations(action.pageIndex),
    }
end

local function translateGetJoinableWarConfigurations(action)
    if (not PlayerProfileManager.isAccountAndPasswordValid(action.playerAccount, action.playerPassword)) then
        return LOGOUT_INVALID_ACCOUNT_PASSWORD
    end

    return {
        actionCode        = ACTION_CODES.ActionGetJoinableWarConfigurations,
        warConfigurations = SceneWarManager.getJoinableWarConfigurations(action.playerAccount, action.sceneWarShortName),
    }
end

local function translateGetOngoingWarList(action)
    local playerAccount = action.playerAccount
    if (not PlayerProfileManager.isAccountAndPasswordValid(action.playerAccount, action.playerPassword)) then
        return LOGOUT_INVALID_ACCOUNT_PASSWORD
    end

    local list = {}
    for sceneWarFileName, _ in pairs(PlayerProfileManager.getPlayerProfile(playerAccount).warLists.ongoing) do
        list[#list + 1] = {
            isInTurn         = isPlayerInTurnInWar(SceneWarManager.getOngoingModelSceneWar(sceneWarFileName), playerAccount),
            warConfiguration = SceneWarManager.getOngoingSceneWarConfiguration(sceneWarFileName),
        }
    end

    return {
        actionCode     = ACTION_CODES.ActionGetOngoingWarList,
        ongoingWarList = list,
    }
end

-- This translation ignores the existing unit of the same player at the end of the path, so that the actions of Join/Attack/Wait can reuse this function.
local function translatePath(path, launchUnitID, modelSceneWar)
    local modelWarField      = modelSceneWar:getModelWarField()
    local modelTurnManager   = modelSceneWar:getModelTurnManager()
    local modelUnitMap       = modelWarField:getModelUnitMap()
    local playerIndexInTurn  = modelTurnManager:getPlayerIndex()
    local rawPathNodes       = path.pathNodes
    local beginningGridIndex = rawPathNodes[1]
    local mapSize            = modelUnitMap:getMapSize()
    local focusModelUnit     = modelUnitMap:getFocusModelUnit(beginningGridIndex, launchUnitID)
    local isWithinMap        = GridIndexFunctions.isWithinMap

    if (not isWithinMap(beginningGridIndex, mapSize)) then
        return nil, "ActionTranslator-translatePath() a node in the path is not within the map."
    elseif (not focusModelUnit) then
        return nil, "ActionTranslator-translatePath() there is no unit on the starting grid of the path."
    elseif (focusModelUnit:getPlayerIndex() ~= playerIndexInTurn) then
        return nil, "ActionTranslator-translatePath() the owner player of the moving unit is not in his turn."
    elseif (not focusModelUnit:isStateIdle()) then
        return nil, "ActionTranslator-translatePath() the moving unit is not in idle state."
    elseif (not modelTurnManager:isTurnPhaseMain()) then
        return nil, "ActionTranslator-translatePath() the turn phase is not 'main'."
    end

    local modelTileMap         = modelWarField:getModelTileMap()
    local translatedPathNodes  = {GridIndexFunctions.clone(beginningGridIndex)}
    local translatedPath       = {pathNodes = translatedPathNodes}
    local totalFuelConsumption = 0
    local maxFuelConsumption   = math.min(focusModelUnit:getCurrentFuel(), focusModelUnit:getMoveRange())
    local sceneWarFileName     = modelSceneWar:getFileName()

    for i = 2, #rawPathNodes do
        local gridIndex = rawPathNodes[i]
        if (not GridIndexFunctions.isAdjacent(rawPathNodes[i - 1], gridIndex)) then
            return nil, "ActionTranslator-translatePath() the path is invalid because some grids are not adjacent to previous ones."
        elseif (isGridInPathNodes(gridIndex, translatedPathNodes)) then
            return nil, "ActionTranslator-translatePath() some grids in the path are the same."
        elseif (not isWithinMap(gridIndex, mapSize)) then
            return nil, "ActionTranslator-translatePath() a node in the path is not within the map."
        end

        local existingModelUnit = modelUnitMap:getModelUnit(gridIndex)
        if ((existingModelUnit) and (existingModelUnit:getPlayerIndex() ~= playerIndexInTurn)) then
            if (isUnitVisible(sceneWarFileName, gridIndex, existingModelUnit:getUnitType(), isModelUnitDiving(existingModelUnit), existingModelUnit:getPlayerIndex(), playerIndexInTurn)) then
                return nil, "ActionTranslator-translatePath() the path is invalid because it is blocked by a visible enemy unit."
            else
                translatedPath.isBlocked = true
            end
        end

        local fuelConsumption = modelTileMap:getModelTile(gridIndex):getMoveCostWithModelUnit(focusModelUnit)
        if (not fuelConsumption) then
            return nil, "ActionTranslator-translatePath() the path is invalid because some tiles on it is impassable."
        end

        totalFuelConsumption = totalFuelConsumption + fuelConsumption
        if (totalFuelConsumption > maxFuelConsumption) then
            return nil, "ActionTranslator-translatePath() the path is invalid because the fuel consumption is too high."
        end

        if (not translatedPath.isBlocked) then
            translatedPath.fuelConsumption                = totalFuelConsumption
            translatedPathNodes[#translatedPathNodes + 1] = GridIndexFunctions.clone(gridIndex)
        end
    end

    return translatedPath
end

local function translateActivateSkillGroup(action)
    local modelSceneWar, actionOnError = getModelSceneWarWithAction(action)
    if (not modelSceneWar) then
        return actionOnError
    end

    local skillGroupID     = action.skillGroupID
    local modelTurnManager = modelSceneWar:getModelTurnManager()
    local modelPlayer      = modelSceneWar:getModelPlayerManager():getModelPlayer(modelTurnManager:getPlayerIndex())
    if ((not modelTurnManager:isTurnPhaseMain())               or
        (not modelPlayer:canActivateSkillGroup(skillGroupID))) then
        return createActionReloadSceneWar(modelSceneWar, action.playerAccount, 81, MESSAGE_PARAM_OUT_OF_SYNC)
    end

    local sceneWarFileName             = action.sceneWarFileName
    local revealedTiles, revealedUnits = VisibilityFunctions.getRevealedTilesAndUnitsDataForSkillActivation(sceneWarFileName, skillGroupID)
    local actionActivateSkillGroup = {
        actionCode       = ACTION_CODES.ActionActivateSkillGroup,
        actionID         = action.actionID,
        sceneWarFileName = sceneWarFileName,
        skillGroupID     = skillGroupID,
        revealedTiles    = revealedTiles,
        revealedUnits    = revealedUnits,
    }
    return actionActivateSkillGroup, createActionsForPublish(actionActivateSkillGroup), createActionForServer(actionActivateSkillGroup)
end

local function translateAttack(action)
    local modelSceneWar, actionOnError = getModelSceneWarWithAction(action)
    if (not modelSceneWar) then
        return actionOnError
    end

    local rawPath, launchUnitID        = action.path, action.launchUnitID
    local translatedPath, translateMsg = translatePath(rawPath, launchUnitID, modelSceneWar)
    if ((not translatedPath)                                              or
        (isPathDestinationOccupiedByVisibleUnit(modelSceneWar, rawPath))) then
        return createActionReloadSceneWar(modelSceneWar, action.playerAccount, 81, MESSAGE_PARAM_OUT_OF_SYNC)
    end

    local sceneWarFileName    = action.sceneWarFileName
    local modelUnitMap        = getModelUnitMap(modelSceneWar)
    local attacker            = modelUnitMap:getFocusModelUnit(rawPath.pathNodes[1], launchUnitID)
    local targetGridIndex     = action.targetGridIndex
    local attackTarget        = modelUnitMap:getModelUnit(targetGridIndex) or getModelTileMap(modelSceneWar):getModelTile(targetGridIndex)
    if ((not ComponentManager.getComponent(attacker, "AttackDoer"))                                                                                                                                                     or
        (not GridIndexFunctions.isWithinMap(targetGridIndex, modelUnitMap:getMapSize()))                                                                                                                                or
        ((attackTarget.getUnitType) and (not isUnitVisible(sceneWarFileName, targetGridIndex, attackTarget:getUnitType(), isModelUnitDiving(attackTarget), attackTarget:getPlayerIndex(), attacker:getPlayerIndex())))) then
        return createActionReloadSceneWar(modelSceneWar, action.playerAccount, 81, MESSAGE_PARAM_OUT_OF_SYNC)
    end

    local attackDamage, counterDamage = DamageCalculator.getUltimateBattleDamage(rawPath.pathNodes, launchUnitID, targetGridIndex, modelSceneWar)
    if (not attackDamage) then
        return createActionReloadSceneWar(modelSceneWar, action.playerAccount, 81, MESSAGE_PARAM_OUT_OF_SYNC)
    end

    local revealedTiles, revealedUnits = getRevealedTilesAndUnitsData(sceneWarFileName, translatedPath.pathNodes, attacker, (counterDamage) and (counterDamage >= attacker:getCurrentHP()))
    if (translatedPath.isBlocked) then
        local actionWait = {
            actionCode       = ACTION_CODES.ActionWait,
            actionID         = action.actionID,
            sceneWarFileName = sceneWarFileName,
            path             = translatedPath,
            launchUnitID     = launchUnitID,
            revealedTiles    = revealedTiles,
            revealedUnits    = revealedUnits,
        }
        return actionWait, createActionsForPublish(actionWait), createActionForServer(actionWait)
    else
        local actionAttack = {
            actionCode       = ACTION_CODES.ActionAttack,
            actionID         = action.actionID,
            sceneWarFileName = sceneWarFileName,
            path             = translatedPath,
            launchUnitID     = launchUnitID,
            targetGridIndex  = targetGridIndex,
            attackDamage     = attackDamage,
            counterDamage    = counterDamage,
            revealedTiles    = revealedTiles,
            revealedUnits    = revealedUnits,
            lostPlayerIndex  = getLostPlayerIndexForActionAttack(attacker, attackTarget, attackDamage, counterDamage),
        }
        return actionAttack, createActionsForPublish(actionAttack), createActionForServer(actionAttack)
    end
end

local function translateBeginTurn(action)
    local modelSceneWar, actionOnError = getModelSceneWarWithAction(action)
    if (not modelSceneWar) then
        return actionOnError
    end

    local modelTurnManager = modelSceneWar:getModelTurnManager()
    if (not modelTurnManager:isTurnPhaseRequestToBegin()) then
        return createActionReloadSceneWar(modelSceneWar, action.playerAccount, 81, MESSAGE_PARAM_OUT_OF_SYNC)
    end

    local actionBeginTurn = {
        actionCode       = ACTION_CODES.ActionBeginTurn,
        actionID         = action.actionID,
        sceneWarFileName = action.sceneWarFileName,
    }
    if (modelTurnManager:getTurnIndex() == 1) then
        actionBeginTurn.income = getIncomeOnBeginTurn(modelSceneWar)
    else
        actionBeginTurn.lostPlayerIndex = (areAllUnitsDestroyedOnBeginTurn(modelSceneWar)) and (modelTurnManager:getPlayerIndex()) or (nil)
        actionBeginTurn.repairData      = generateRepairDataOnBeginTurn(modelSceneWar)
    end
    return actionBeginTurn, createActionsForPublish(actionBeginTurn), createActionForServer(actionBeginTurn)
end

local function translateBuildModelTile(action)
    local modelSceneWar, actionOnError = getModelSceneWarWithAction(action)
    if (not modelSceneWar) then
        return actionOnError
    end

    local rawPath, launchUnitID        = action.path, action.launchUnitID
    local translatedPath, translateMsg = translatePath(rawPath, launchUnitID, modelSceneWar)
    if ((not translatedPath)                                              or
        (isPathDestinationOccupiedByVisibleUnit(modelSceneWar, rawPath))) then
        return createActionReloadSceneWar(modelSceneWar, action.playerAccount, 81, MESSAGE_PARAM_OUT_OF_SYNC)
    end

    local rawPathNodes     = rawPath.pathNodes
    local endingGridIndex  = rawPathNodes[#rawPathNodes]
    local focusModelUnit   = getModelUnitMap(modelSceneWar):getFocusModelUnit(rawPathNodes[1], launchUnitID)
    local modelTile        = getModelTileMap(modelSceneWar):getModelTile(endingGridIndex)
    if ((not focusModelUnit.canBuildOnTileType)                          or
        (not focusModelUnit:canBuildOnTileType(modelTile:getTileType())) or
        (not focusModelUnit.getCurrentMaterial)                          or
        (focusModelUnit:getCurrentMaterial() < 1))                       then
        return createActionReloadSceneWar(modelSceneWar, action.playerAccount, 81, MESSAGE_PARAM_OUT_OF_SYNC)
    end

    local sceneWarFileName             = modelSceneWar:getFileName()
    local revealedTiles, revealedUnits = getRevealedTilesAndUnitsData(sceneWarFileName, translatedPath.pathNodes, focusModelUnit, false)
    if (translatedPath.isBlocked) then
        local actionWait = {
            actionCode       = ACTION_CODES.ActionWait,
            actionID         = action.actionID,
            sceneWarFileName = sceneWarFileName,
            path             = translatedPath,
            launchUnitID     = launchUnitID,
            revealedTiles    = revealedTiles,
            revealedUnits    = revealedUnits,
        }
        return actionWait, createActionsForPublish(actionWait), createActionForServer(actionWait)
    else
        if (focusModelUnit:getBuildAmount() >= modelTile:getCurrentBuildPoint()) then
            local tiles, units = VisibilityFunctions.getRevealedTilesAndUnitsDataForBuild(sceneWarFileName, endingGridIndex, focusModelUnit)
            revealedTiles = TableFunctions.union(revealedTiles, tiles)
            revealedUnits = TableFunctions.union(revealedUnits, units)
        end
        local actionBuildModelTile = {
            actionCode       = ACTION_CODES.ActionBuildModelTile,
            actionID         = action.actionID,
            sceneWarFileName = sceneWarFileName,
            path             = translatedPath,
            launchUnitID     = launchUnitID,
            revealedTiles    = revealedTiles,
            revealedUnits    = revealedUnits,
        }
        return actionBuildModelTile, createActionsForPublish(actionBuildModelTile), createActionForServer(actionBuildModelTile)
    end
end

local function translateCaptureModelTile(action)
    local modelSceneWar, actionOnError = getModelSceneWarWithAction(action)
    if (not modelSceneWar) then
        return actionOnError
    end

    local rawPath, launchUnitID        = action.path, action.launchUnitID
    local translatedPath, translateMsg = translatePath(rawPath, launchUnitID, modelSceneWar)
    if ((not translatedPath)                                              or
        (isPathDestinationOccupiedByVisibleUnit(modelSceneWar, rawPath))) then
        return createActionReloadSceneWar(modelSceneWar, action.playerAccount, 81, MESSAGE_PARAM_OUT_OF_SYNC)
    end

    local rawPathNodes    = rawPath.pathNodes
    local endingGridIndex = rawPathNodes[#rawPathNodes]
    local capturer        = getModelUnitMap(modelSceneWar):getFocusModelUnit(rawPathNodes[1], launchUnitID)
    local captureTarget   = getModelTileMap(modelSceneWar):getModelTile(endingGridIndex)
    if ((not capturer.canCaptureModelTile) or (not capturer:canCaptureModelTile(captureTarget))) then
        return createActionReloadOrExitWar(sceneWarFileName, action.playerAccount, getLocalizedText(81, "OutOfSync"))
    end

    local sceneWarFileName             = modelSceneWar:getFileName()
    local revealedTiles, revealedUnits = getRevealedTilesAndUnitsData(sceneWarFileName, translatedPath.pathNodes, capturer, false)
    if (translatedPath.isBlocked) then
        local actionWait = {
            actionCode       = ACTION_CODES.ActionWait,
            actionID         = action.actionID,
            sceneWarFileName = sceneWarFileName,
            path             = translatedPath,
            launchUnitID     = launchUnitID,
            revealedTiles    = revealedTiles,
            revealedUnits    = revealedUnits,
        }
        return actionWait, createActionsForPublish(actionWait), createActionForServer(actionWait)
    else
        local isCaptureFinished = capturer:getCaptureAmount() >= captureTarget:getCurrentCapturePoint()
        if (isCaptureFinished) then
            local tiles, units = VisibilityFunctions.getRevealedTilesAndUnitsDataForCapture(sceneWarFileName, endingGridIndex, capturer:getPlayerIndex())
            revealedTiles = TableFunctions.union(revealedTiles, tiles)
            revealedUnits = TableFunctions.union(revealedUnits, units)
        end

        local actionCapture = {
            actionCode       = ACTION_CODES.ActionCaptureModelTile,
            actionID         = action.actionID,
            sceneWarFileName = sceneWarFileName,
            path             = translatedPath,
            launchUnitID     = launchUnitID,
            revealedTiles    = revealedTiles,
            revealedUnits    = revealedUnits,
            lostPlayerIndex  = ((isCaptureFinished) and (captureTarget:isDefeatOnCapture()))
                and (captureTarget:getPlayerIndex())
                or  (nil),
        }
        return actionCapture, createActionsForPublish(actionCapture), createActionForServer(actionCapture)
    end
end

local function translateDive(action, modelScene)
    local rawPath, launchUnitID        = action.path, action.launchUnitID
    local translatedPath, translateMsg = translatePath(rawPath, launchUnitID, modelScene)
    local sceneWarFileName             = modelScene:getFileName()
    if (not translatedPath) then
        return createActionReloadOrExitWar(sceneWarFileName, action.playerAccount, getLocalizedText(81, "OutOfSync", translateMsg))
    end

    local focusModelUnit = getModelUnitMap(sceneWarFileName):getFocusModelUnit(rawPath[1], launchUnitID)
    if ((not modelScene:getModelTurnManager():isTurnPhaseMain())                                              or
        (not focusModelUnit.canDive)                                                                          or
        (not focusModelUnit:canDive())                                                                        or
        (isPathDestinationOccupiedByVisibleUnit(sceneWarFileName, rawPath, focusModelUnit:getPlayerIndex()))) then
        return createActionReloadOrExitWar(sceneWarFileName, action.playerAccount, getLocalizedText(81, "OutOfSync"))
    end

    local revealedTiles, revealedUnits = getRevealedTilesAndUnitsData(sceneWarFileName, translatedPath.pathNodes, focusModelUnit, false)
    if (translatedPath.isBlocked) then
        local actionWait = {
            actionName    = "Wait",
            actionID      = action.actionID,
            fileName      = sceneWarFileName,
            path          = translatedPath,
            launchUnitID  = launchUnitID,
            revealedTiles = revealedTiles,
            revealedUnits = revealedUnits,
        }
        return actionWait, createActionsForPublish(actionWait), createActionForServer(actionWait)
    else
        local actionDive = {
            actionName    = "Dive",
            actionID      = action.actionID,
            fileName      = sceneWarFileName,
            path          = translatedPath,
            launchUnitID  = launchUnitID,
            revealedTiles = revealedTiles,
            revealedUnits = revealedUnits,
        }
        return actionDive, createActionsForPublish(actionDive), createActionForServer(actionDive)
    end
end

local function translateDropModelUnit(action, modelScene)
    local rawPath, launchUnitID        = action.path, action.launchUnitID
    local translatedPath, translateMsg = translatePath(rawPath, launchUnitID, modelScene)
    local sceneWarFileName             = modelScene:getFileName()
    if (not translatedPath) then
        return createActionReloadOrExitWar(sceneWarFileName, action.playerAccount, getLocalizedText(81, "OutOfSync", translateMsg))
    end

    local modelUnitMap    = getModelUnitMap(sceneWarFileName)
    local endingGridIndex = rawPath[#rawPath]
    local loaderModelUnit = modelUnitMap:getFocusModelUnit(rawPath[1], launchUnitID)
    local tileType        = getModelTileMap(sceneWarFileName):getModelTile(endingGridIndex):getTileType()
    if ((not modelScene:getModelTurnManager():isTurnPhaseMain())                                               or
        (not loaderModelUnit.canDropModelUnit)                                                                 or
        (not loaderModelUnit:canDropModelUnit(tileType))                                                       or
        (not validateDropDestinations(action, modelScene))                                                     or
        (isPathDestinationOccupiedByVisibleUnit(sceneWarFileName, rawPath, loaderModelUnit:getPlayerIndex()))) then
        return createActionReloadOrExitWar(sceneWarFileName, action.playerAccount, getLocalizedText(81, "OutOfSync"))
    end

    local revealedTiles, revealedUnits = getRevealedTilesAndUnitsData(sceneWarFileName, translatedPath.pathNodes, loaderModelUnit, false)
    if (translatedPath.isBlocked) then
        local actionWait = {
            actionName    = "Wait",
            actionID      = action.actionID,
            fileName      = sceneWarFileName,
            path          = translatedPath,
            launchUnitID  = launchUnitID,
            revealedTiles = revealedTiles,
            revealedUnits = revealedUnits,
        }
        return actionWait, createActionsForPublish(actionWait), createActionForServer(actionWait)
    else
        local dropDestinations = translateDropDestinations(action.dropDestinations, modelUnitMap, loaderModelUnit)
        for _, dropDestination in ipairs(dropDestinations) do
            local dropPath      = {endingGridIndex, dropDestination.gridIndex}
            local dropModelUnit = modelUnitMap:getLoadedModelUnitWithUnitId(dropDestination.unitID)
            local tiles, units  = getRevealedTilesAndUnitsData(sceneWarFileName, dropPath, dropModelUnit, false)
            revealedTiles = TableFunctions.union(revealedTiles, tiles)
            revealedUnits = TableFunctions.union(revealedUnits, units)
        end

        local actionDropModelUnit = {
            actionName       = "DropModelUnit",
            actionID         = action.actionID,
            fileName         = sceneWarFileName,
            path             = translatedPath,
            dropDestinations = dropDestinations,
            launchUnitID     = launchUnitID,
            revealedTiles    = revealedTiles,
            revealedUnits    = revealedUnits,
        }
        return actionDropModelUnit, createActionsForPublish(actionDropModelUnit), createActionForServer(actionDropModelUnit)
    end
end

local function translateEndTurn(action)
    local modelSceneWar, actionOnError = getModelSceneWarWithAction(action)
    if (not modelSceneWar) then
        return actionOnError
    end

    if (not modelSceneWar:getModelTurnManager():isTurnPhaseMain()) then
        return createActionReloadSceneWar(modelSceneWar, action.playerAccount, 81, MESSAGE_PARAM_OUT_OF_SYNC)
    end

    local actionEndTurn = {
        actionCode       = ACTION_CODES.ActionEndTurn,
        actionID         = action.actionID,
        sceneWarFileName = action.sceneWarFileName,
    }
    return actionEndTurn, createActionsForPublish(actionEndTurn), createActionForServer(actionEndTurn)
end

local function translateJoinModelUnit(action, modelScene)
    local rawPath, launchUnitID        = action.path, action.launchUnitID
    local translatedPath, translateMsg = translatePath(rawPath, launchUnitID, modelScene)
    local sceneWarFileName             = modelScene:getFileName()
    if (not translatedPath) then
        return createActionReloadOrExitWar(sceneWarFileName, action.playerAccount, getLocalizedText(81, "OutOfSync", translateMsg))
    end

    local modelUnitMap      = modelScene:getModelWarField():getModelUnitMap()
    local existingModelUnit = modelUnitMap:getModelUnit(rawPath[#rawPath])
    local focusModelUnit    = modelUnitMap:getFocusModelUnit(rawPath[1], launchUnitID)
    if ((not modelScene:getModelTurnManager():isTurnPhaseMain())    or
        (#rawPath == 1)                                             or
        (not existingModelUnit)                                     or
        (not focusModelUnit.canJoinModelUnit)                       or
        (not focusModelUnit:canJoinModelUnit(existingModelUnit)))   then
        return createActionReloadOrExitWar(sceneWarFileName, action.playerAccount, getLocalizedText(81, "OutOfSync"))
    end

    local revealedTiles, revealedUnits = getRevealedTilesAndUnitsData(sceneWarFileName, translatedPath.pathNodes, focusModelUnit, false)
    if (translatedPath.isBlocked) then
        local actionWait = {
            actionName    = "Wait",
            actionID      = action.actionID,
            fileName      = sceneWarFileName,
            path          = translatedPath,
            launchUnitID  = launchUnitID,
            revealedTiles = revealedTiles,
            revealedUnits = revealedUnits,
        }
        return actionWait, createActionsForPublish(actionWait), createActionForServer(actionWait)
    else
        local actionJoinModelUnit = {
            actionName    = "JoinModelUnit",
            actionID      = action.actionID,
            fileName      = sceneWarFileName,
            path          = translatedPath,
            launchUnitID  = launchUnitID,
            revealedTiles = revealedTiles,
            revealedUnits = revealedUnits,
        }
        return actionJoinModelUnit, createActionsForPublish(actionJoinModelUnit), createActionForServer(actionJoinModelUnit)
    end
end

local function translateLaunchFlare(action, modelScene)
    local rawPath, launchUnitID        = action.path, action.launchUnitID
    local translatedPath, translateMsg = translatePath(rawPath, launchUnitID, modelScene)
    local sceneWarFileName             = modelScene:getFileName()
    if (not translatedPath) then
        return createActionReloadOrExitWar(sceneWarFileName, action.playerAccount, getLocalizedText(81, "OutOfSync", translateMsg))
    end

    local modelUnitMap    = getModelUnitMap(sceneWarFileName)
    local targetGridIndex = action.targetGridIndex
    local focusModelUnit  = modelUnitMap:getFocusModelUnit(rawPath[1], launchUnitID)
    local playerIndex     = focusModelUnit:getPlayerIndex()
    if ((not modelScene:getModelTurnManager():isTurnPhaseMain())                                                 or
        (#rawPath > 1)                                                                                           or
        (not focusModelUnit.getCurrentFlareAmmo)                                                                 or
        (focusModelUnit:getCurrentFlareAmmo() == 0)                                                              or
        (not getModelFogMap(sceneWarFileName):isFogOfWarCurrently())                                             or
        (not GridIndexFunctions.isWithinMap(targetGridIndex, modelUnitMap:getMapSize())                          or
        (GridIndexFunctions.getDistance(targetGridIndex, rawPath[#rawPath]) > focusModelUnit:getMaxFlareRange()) or
        (isPathDestinationOccupiedByVisibleUnit(sceneWarFileName, rawPath, playerIndex))))                       then
        return createActionReloadOrExitWar(sceneWarFileName, action.playerAccount, getLocalizedText(81, "OutOfSync"))
    end

    local revealedTiles, revealedUnits = getRevealedTilesAndUnitsData(sceneWarFileName, translatedPath.pathNodes, focusModelUnit, false)
    if (translatedPath.isBlocked) then
        local actionWait = {
            actionName    = "Wait",
            actionID      = action.actionID,
            fileName      = sceneWarFileName,
            path          = translatedPath,
            launchUnitID  = launchUnitID,
            revealedTiles = revealedTiles,
            revealedUnits = revealedUnits,
        }
        return actionWait, createActionsForPublish(actionWait), createActionForServer(actionWait)
    else
        local tiles, units = VisibilityFunctions.getRevealedTilesAndUnitsDataForFlare(sceneWarFileName, targetGridIndex, focusModelUnit:getFlareAreaRadius(), playerIndex)
        local actionLaunchFlare = {
            actionName      = "LaunchFlare",
            actionID        = action.actionID,
            fileName        = sceneWarFileName,
            path            = translatedPath,
            targetGridIndex = targetGridIndex,
            launchUnitID    = launchUnitID,
            revealedTiles   = TableFunctions.union(revealedTiles, tiles),
            revealedUnits   = TableFunctions.union(revealedUnits, units),
        }
        return actionLaunchFlare, createActionsForPublish(actionLaunchFlare), createActionForServer(actionLaunchFlare)
    end
end

local function translateLaunchSilo(action, modelScene)
    local rawPath, launchUnitID        = action.path, action.launchUnitID
    local translatedPath, translateMsg = translatePath(rawPath, launchUnitID, modelScene)
    local sceneWarFileName             = modelScene:getFileName()
    if (not translatedPath) then
        return createActionReloadOrExitWar(sceneWarFileName, action.playerAccount, getLocalizedText(81, "OutOfSync", translateMsg))
    end

    local modelUnitMap    = getModelUnitMap(sceneWarFileName)
    local targetGridIndex = action.targetGridIndex
    local focusModelUnit  = modelUnitMap:getFocusModelUnit(rawPath[1], launchUnitID)
    local tileType        = getModelTileMap(sceneWarFileName):getModelTile(rawPath[#rawPath]):getTileType()
    if ((not modelScene:getModelTurnManager():isTurnPhaseMain())                                               or
        (not focusModelUnit.canLaunchSiloOnTileType)                                                           or
        (not focusModelUnit:canLaunchSiloOnTileType(tileType))                                                 or
        (not GridIndexFunctions.isWithinMap(targetGridIndex, modelUnitMap:getMapSize())                        or
        (isPathDestinationOccupiedByVisibleUnit(sceneWarFileName, rawPath, focusModelUnit:getPlayerIndex())))) then
        return createActionReloadOrExitWar(sceneWarFileName, action.playerAccount, getLocalizedText(81, "OutOfSync"))
    end

    local revealedTiles, revealedUnits = getRevealedTilesAndUnitsData(sceneWarFileName, translatedPath.pathNodes, focusModelUnit, false)
    if (translatedPath.isBlocked) then
        local actionWait = {
            actionName    = "Wait",
            actionID      = action.actionID,
            fileName      = sceneWarFileName,
            path          = translatedPath,
            launchUnitID  = launchUnitID,
            revealedTiles = revealedTiles,
            revealedUnits = revealedUnits,
        }
        return actionWait, createActionsForPublish(actionWait), createActionForServer(actionWait)
    else
        local actionLaunchSilo = {
            actionName      = "LaunchSilo",
            actionID        = action.actionID,
            fileName        = sceneWarFileName,
            path            = translatedPath,
            targetGridIndex = targetGridIndex,
            launchUnitID    = launchUnitID,
            revealedTiles   = revealedTiles,
            revealedUnits   = revealedUnits,
        }
        return actionLaunchSilo, createActionsForPublish(actionLaunchSilo), createActionForServer(actionLaunchSilo)
    end
end

local function translateLoadModelUnit(action, modelScene)
    local rawPath, launchUnitID        = action.path, action.launchUnitID
    local translatedPath, translateMsg = translatePath(rawPath, launchUnitID, modelScene)
    local sceneWarFileName             = modelScene:getFileName()
    if (not translatedPath) then
        return createActionReloadOrExitWar(sceneWarFileName, action.playerAccount, getLocalizedText(81, "OutOfSync", translateMsg))
    end

    local modelUnitMap    = getModelUnitMap(sceneWarFileName)
    local focusModelUnit  = modelUnitMap:getFocusModelUnit(rawPath[1], launchUnitID)
    local destination     = rawPath[#rawPath]
    local loaderModelUnit = modelUnitMap:getModelUnit(destination)
    local tileType        = getModelTileMap(sceneWarFileName):getModelTile(destination):getTileType()
    if ((not modelScene:getModelTurnManager():isTurnPhaseMain())          or
        (#rawPath == 1)                                                   or
        (not loaderModelUnit)                                             or
        (not loaderModelUnit.canLoadModelUnit)                            or
        (not loaderModelUnit:canLoadModelUnit(focusModelUnit, tileType))) then
        return createActionReloadOrExitWar(sceneWarFileName, action.playerAccount, getLocalizedText(81, "OutOfSync"))
    end

    local revealedTiles, revealedUnits = getRevealedTilesAndUnitsData(sceneWarFileName, translatedPath.pathNodes, focusModelUnit, false)
    if (translatedPath.isBlocked) then
        local actionWait = {
            actionName    = "Wait",
            actionID      = action.actionID,
            fileName      = sceneWarFileName,
            path          = translatedPath,
            launchUnitID  = launchUnitID,
            revealedTiles = revealedTiles,
            revealedUnits = revealedUnits,
        }
        return actionWait, createActionsForPublish(actionWait), createActionForServer(actionWait)
    else
        local actionLoadModelUnit = {
            actionName    = "LoadModelUnit",
            actionID      = action.actionID,
            fileName      = sceneWarFileName,
            path          = translatedPath,
            launchUnitID  = launchUnitID,
            revealedTiles = revealedTiles,
            revealedUnits = revealedUnits,
        }
        return actionLoadModelUnit, createActionsForPublish(actionLoadModelUnit), createActionForServer(actionLoadModelUnit)
    end
end

local function translateProduceModelUnitOnTile(action)
    local modelSceneWar, actionOnError = getModelSceneWarWithAction(action)
    if (not modelSceneWar) then
        return actionOnError
    end

    local modelTurnManager = modelSceneWar:getModelTurnManager()
    local modelWarField    = modelSceneWar:getModelWarField()
    local modelTileMap     = modelWarField:getModelTileMap()
    local gridIndex        = action.gridIndex
    if ((not modelTurnManager:isTurnPhaseMain())                                    or
        (not GridIndexFunctions.isWithinMap(gridIndex, modelTileMap:getMapSize()))) then
        return createActionReloadSceneWar(modelSceneWar, action.playerAccount, 81, MESSAGE_PARAM_OUT_OF_SYNC)
    end

    local tiledID            = action.tiledID
    local playerIndex        = modelTurnManager:getPlayerIndex()
    local modelPlayerManager = modelSceneWar:getModelPlayerManager()
    local modelTile          = modelTileMap:getModelTile(gridIndex)
    local cost               = Producible.getProductionCostWithTiledId(tiledID, modelPlayerManager)
    if ((not cost)                                                        or
        (cost > modelPlayerManager:getModelPlayer(playerIndex):getFund()) or
        (modelTile:getPlayerIndex() ~= playerIndex)                       or
        (modelWarField:getModelUnitMap():getModelUnit(gridIndex))         or
        (not modelTile.canProduceUnitWithTiledId)                         or
        (not modelTile:canProduceUnitWithTiledId(tiledID)))               then
        return createActionReloadSceneWar(modelSceneWar, action.playerAccount, 81, MESSAGE_PARAM_OUT_OF_SYNC)
    end

    local sceneWarFileName = modelSceneWar:getFileName()
    local focusModelUnit   = Actor.createModel("sceneWar.ModelUnit", {
        tiledID       = tiledID,
        unitID        = 0,
        GridIndexable = gridIndex,
    })
    focusModelUnit:onStartRunning(modelSceneWar, sceneWarFileName)

    local revealedTiles, revealedUnits = getRevealedTilesAndUnitsData(sceneWarFileName, {gridIndex}, focusModelUnit)
    local actionProduceModelUnitOnTile = {
        actionCode       = ACTION_CODES.ActionProduceModelUnitOnTile,
        actionID         = action.actionID,
        sceneWarFileName = sceneWarFileName,
        gridIndex        = gridIndex,
        tiledID          = tiledID,
        cost             = cost, -- the cost can be calculated by the clients, but that calculations can be eliminated by sending the cost to clients.
        revealedTiles    = revealedTiles,
        revealedUnits    = revealedUnits,
    }
    return actionProduceModelUnitOnTile, createActionsForPublish(actionProduceModelUnitOnTile), createActionForServer(actionProduceModelUnitOnTile)
end

local function translateProduceModelUnitOnUnit(action, modelScene)
    local rawPath, launchUnitID        = action.path, action.launchUnitID
    local translatedPath, translateMsg = translatePath(rawPath, launchUnitID, modelScene)
    local sceneWarFileName             = modelScene:getFileName()
    if (not translatedPath) then
        return createActionReloadOrExitWar(sceneWarFileName, action.playerAccount, getLocalizedText(81, "OutOfSync", translateMsg))
    end

    local focusModelUnit     = modelScene:getModelWarField():getModelUnitMap():getFocusModelUnit(rawPath[1], launchUnitID)
    local modelTurnManager   = modelScene:getModelTurnManager()
    local modelPlayer        = modelScene:getModelPlayerManager():getModelPlayer(modelTurnManager:getPlayerIndex())
    local cost               = (focusModelUnit.getMovableProductionCost) and (focusModelUnit:getMovableProductionCost()) or (nil)
    if ((not modelTurnManager:isTurnPhaseMain())                                    or
        (launchUnitID)                                                              or
        (#rawPath ~= 1)                                                             or
        (not focusModelUnit.getCurrentMaterial)                                     or
        (focusModelUnit:getCurrentMaterial() < 1)                                   or
        (not cost)                                                                  or
        (cost > modelPlayer:getFund())                                              or
        (not focusModelUnit.getCurrentLoadCount)                                    or
        (focusModelUnit:getCurrentLoadCount() >= focusModelUnit:getMaxLoadCount())) then
        return createActionReloadOrExitWar(sceneWarFileName, action.playerAccount, getLocalizedText(81, "OutOfSync"))
    end

    local revealedTiles, revealedUnits = getRevealedTilesAndUnitsData(sceneWarFileName, translatedPath.pathNodes, focusModelUnit, false)
    local actionProduceModelUnitOnUnit = {
        actionName    = "ProduceModelUnitOnUnit",
        actionID      = action.actionID,
        fileName      = sceneWarFileName,
        path          = translatedPath,
        cost          = cost,
        revealedTiles = revealedTiles,
        revealedUnits = revealedUnits,
    }
    return actionProduceModelUnitOnUnit, createActionsForPublish(actionProduceModelUnitOnUnit), createActionForServer(actionProduceModelUnitOnUnit)
end

local function translateSupplyModelUnit(action, modelScene)
    local rawPath, launchUnitID        = action.path, action.launchUnitID
    local translatedPath, translateMsg = translatePath(rawPath, launchUnitID, modelScene)
    local sceneWarFileName             = modelScene:getFileName()
    if (not translatedPath) then
        return createActionReloadOrExitWar(sceneWarFileName, action.playerAccount, getLocalizedText(81, "OutOfSync", translateMsg))
    end

    local modelUnitMap   = modelScene:getModelWarField():getModelUnitMap()
    local focusModelUnit = modelUnitMap:getFocusModelUnit(rawPath[1], launchUnitID)
    if ((not modelScene:getModelTurnManager():isTurnPhaseMain())                                              or
        (not canDoActionSupplyModelUnit(focusModelUnit, rawPath[#rawPath], modelUnitMap))                     or
        (isPathDestinationOccupiedByVisibleUnit(sceneWarFileName, rawPath, focusModelUnit:getPlayerIndex()))) then
        return createActionReloadOrExitWar(sceneWarFileName, action.playerAccount, getLocalizedText(81, "OutOfSync"))
    end

    local revealedTiles, revealedUnits = getRevealedTilesAndUnitsData(sceneWarFileName, translatedPath.pathNodes, focusModelUnit, false)
    if (translatedPath.isBlocked) then
        local actionWait = {
            actionName    = "Wait",
            actionID      = action.actionID,
            fileName      = sceneWarFileName,
            path          = translatedPath,
            launchUnitID  = launchUnitID,
            revealedTiles = revealedTiles,
            revealedUnits = revealedUnits,
        }
        return actionWait, createActionsForPublish(actionWait), createActionForServer(actionWait)
    else
        local actionSupplyModelUnit = {
            actionName    = "SupplyModelUnit",
            actionID      = action.actionID,
            fileName      = sceneWarFileName,
            path          = translatedPath,
            launchUnitID  = launchUnitID,
            revealedTiles = revealedTiles,
            revealedUnits = revealedUnits,
        }
        return actionSupplyModelUnit, createActionsForPublish(actionSupplyModelUnit), createActionForServer(actionSupplyModelUnit)
    end
end

local function translateSurface(action, modelScene)
    local rawPath, launchUnitID        = action.path, action.launchUnitID
    local translatedPath, translateMsg = translatePath(rawPath, launchUnitID, modelScene)
    local sceneWarFileName             = modelScene:getFileName()
    if (not translatedPath) then
        return createActionReloadOrExitWar(sceneWarFileName, action.playerAccount, getLocalizedText(81, "OutOfSync", translateMsg))
    end

    local focusModelUnit = getModelUnitMap(sceneWarFileName):getFocusModelUnit(rawPath[1], launchUnitID)
    if ((not modelScene:getModelTurnManager():isTurnPhaseMain())                                              or
        (not focusModelUnit.canSurface)                                                                       or
        (not focusModelUnit:canSurface())                                                                     or
        (isPathDestinationOccupiedByVisibleUnit(sceneWarFileName, rawPath, focusModelUnit:getPlayerIndex()))) then
        return createActionReloadOrExitWar(sceneWarFileName, action.playerAccount, getLocalizedText(81, "OutOfSync"))
    end

    local revealedTiles, revealedUnits = getRevealedTilesAndUnitsData(sceneWarFileName, translatedPath.pathNodes, focusModelUnit, false)
    if (translatedPath.isBlocked) then
        local actionWait = {
            actionName    = "Wait",
            actionID      = action.actionID,
            fileName      = sceneWarFileName,
            path          = translatedPath,
            launchUnitID  = launchUnitID,
            revealedTiles = revealedTiles,
            revealedUnits = revealedUnits,
        }
        return actionWait, createActionsForPublish(actionWait), createActionForServer(actionWait)
    else
        local actionSurface = {
            actionName    = "Surface",
            actionID      = action.actionID,
            fileName      = sceneWarFileName,
            path          = translatedPath,
            launchUnitID  = launchUnitID,
            revealedTiles = revealedTiles,
            revealedUnits = revealedUnits,
        }
        return actionSurface, createActionsForPublish(actionSurface), createActionForServer(actionSurface)
    end
end

local function translateSurrender(action)
    local modelSceneWar, actionOnError = getModelSceneWarWithAction(action)
    if (not modelSceneWar) then
        return actionOnError
    elseif (not modelSceneWar:getModelTurnManager():isTurnPhaseMain()) then
        return createActionReloadSceneWar(modelSceneWar, action.playerAccount, 81, MESSAGE_PARAM_OUT_OF_SYNC)
    end

    local actionSurrender = {
        actionCode       = ACTION_CODES.ActionSurrender,
        actionID         = action.actionID,
        sceneWarFileName = action.sceneWarFileName,
    }
    return actionSurrender, createActionsForPublish(actionSurrender), createActionForServer(actionSurrender)
end

local function translateWait(action)
    local modelSceneWar, actionOnError = getModelSceneWarWithAction(action)
    if (not modelSceneWar) then
        return actionOnError
    end

    local rawPath, launchUnitID        = action.path, action.launchUnitID
    local translatedPath, translateMsg = translatePath(rawPath, launchUnitID, modelSceneWar)
    if ((not translatedPath)                                              or
        (isPathDestinationOccupiedByVisibleUnit(modelSceneWar, rawPath))) then
        return createActionReloadSceneWar(modelSceneWar, action.playerAccount, 81, MESSAGE_PARAM_OUT_OF_SYNC)
    end

    local sceneWarFileName             = action.sceneWarFileName
    local focusModelUnit               = getModelUnitMap(modelSceneWar):getFocusModelUnit(translatedPath.pathNodes[1], launchUnitID)
    local revealedTiles, revealedUnits = getRevealedTilesAndUnitsData(sceneWarFileName, translatedPath.pathNodes, focusModelUnit, false)
    local actionWait = {
        actionCode       = ACTION_CODES.ActionWait,
        actionID         = action.actionID,
        sceneWarFileName = sceneWarFileName,
        path             = translatedPath,
        launchUnitID     = launchUnitID,
        revealedTiles    = revealedTiles,
        revealedUnits    = revealedUnits,
    }
    return actionWait, createActionsForPublish(actionWait), createActionForServer(actionWait)
end

--------------------------------------------------------------------------------
-- The public functions.
--------------------------------------------------------------------------------
function ActionTranslator.translate(action)
    local actionCode = action.actionCode
    assert(ActionCodeFunctions.getActionName(actionCode), "ActionTranslator.translate() invalid actionCode: " .. (actionCode or ""))

    if     (actionCode == ACTION_CODES.ActionDownloadReplayData)           then return translateDownloadReplayData(          action)
    elseif (actionCode == ACTION_CODES.ActionGetJoinableWarConfigurations) then return translateGetJoinableWarConfigurations(action)
    elseif (actionCode == ACTION_CODES.ActionGetOngoingWarList)            then return translateGetOngoingWarList(           action)
    elseif (actionCode == ACTION_CODES.ActionGetReplayConfigurations)      then return translateGetReplayConfigurations(     action)
    elseif (actionCode == ACTION_CODES.ActionGetSkillConfiguration)        then return translateGetSkillConfiguration(       action)
    elseif (actionCode == ACTION_CODES.ActionJoinWar)                      then return translateJoinWar(                     action)
    elseif (actionCode == ACTION_CODES.ActionLogin)                        then return translateLogin(                       action)
    elseif (actionCode == ACTION_CODES.ActionNetworkHeartbeat)             then return translateNetworkHeartbeat(            action)
    elseif (actionCode == ACTION_CODES.ActionNewWar)                       then return translateNewWar(                      action)
    elseif (actionCode == ACTION_CODES.ActionRegister)                     then return translateRegister(                    action)
    elseif (actionCode == ACTION_CODES.ActionReloadSceneWar)               then return translateReloadSceneWar(              action)
    elseif (actionCode == ACTION_CODES.ActionRunSceneWar)                  then return translateRunSceneWar(                 action)
    elseif (actionCode == ACTION_CODES.ActionSetSkillConfiguration)        then return translateSetSkillConfiguration(       action)
    elseif (actionCode == ACTION_CODES.ActionSyncSceneWar)                 then return translateSyncSceneWar(                action)
    elseif (actionCode == ACTION_CODES.ActionActivateSkillGroup)           then return translateActivateSkillGroup(          action)
    elseif (actionCode == ACTION_CODES.ActionAttack)                       then return translateAttack(                      action)
    elseif (actionCode == ACTION_CODES.ActionBeginTurn)                    then return translateBeginTurn(                   action)
    elseif (actionCode == ACTION_CODES.ActionBuildModelTile)               then return translateBuildModelTile(              action)
    elseif (actionCode == ACTION_CODES.ActionCaptureModelTile)             then return translateCaptureModelTile(            action)
    elseif (actionCode == ACTION_CODES.ActionEndTurn)                      then return translateEndTurn(                     action)
    elseif (actionCode == ACTION_CODES.ActionProduceModelUnitOnTile)       then return translateProduceModelUnitOnTile(      action)
    elseif (actionCode == ACTION_CODES.ActionSurrender)                    then return translateSurrender(                   action)
    elseif (actionCode == ACTION_CODES.ActionWait)                         then return translateWait(                        action)
    else   error("ActionTranslator.translate() invalid actionCode: " .. (actionCode or ""))
    end

    --[[
    local actionName = action.actionName
    local playerAccount = action.playerAccount
    if (not PlayerProfileManager.isAccountAndPasswordValid(playerAccount, action.playerPassword)) then
        return LOGOUT_INVALID_ACCOUNT_PASSWORD
    end

    local sceneWarFileName   = action.sceneWarFileName
    local modelSceneWar, err = SceneWarManager.getOngoingModelSceneWar(sceneWarFileName)
    if ((not modelSceneWar)                                                   or
        (not SceneWarManager.isPlayerInTurn(sceneWarFileName, playerAccount)) or
        (modelSceneWar:getActionId() + 1 ~= action.actionID))                 then
        return createActionReloadOrExitWar(sceneWarFileName, playerAccount, getLocalizedText(81, "OutOfSync"))
    end

    elseif (actionName == "Dive")                   then return translateDive(                  action, modelSceneWar)
    elseif (actionName == "DropModelUnit")          then return translateDropModelUnit(         action, modelSceneWar)
    elseif (actionName == "JoinModelUnit")          then return translateJoinModelUnit(         action, modelSceneWar)
    elseif (actionName == "LaunchFlare")            then return translateLaunchFlare(           action, modelSceneWar)
    elseif (actionName == "LaunchSilo")             then return translateLaunchSilo(            action, modelSceneWar)
    elseif (actionName == "LoadModelUnit")          then return translateLoadModelUnit(         action, modelSceneWar)
    elseif (actionName == "ProduceModelUnitOnUnit") then return translateProduceModelUnitOnUnit(action, modelSceneWar)
    elseif (actionName == "SupplyModelUnit")        then return translateSupplyModelUnit(       action, modelSceneWar)
    elseif (actionName == "Surface")                then return translateSurface(               action, modelSceneWar)
    else    return createActionReloadOrExitWar(sceneWarFileName, playerAccount, getLocalizedText(81, "OutOfSync", actionName))
    end
    --]]
end

return ActionTranslator
