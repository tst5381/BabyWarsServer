
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
--   - 在雾战下，为避免作弊，客户端应当只能获取其应当获取的信息（如视野内的单位信息），这就要求本文件里的函数做出合适实现（比如，
--     某些操作会使得视野变化，此时服务器就应当返回新视野内的所有单位的信息）
--]]--------------------------------------------------------------------------------

local ActionTranslator = {}

local Producible              = requireFW("src.app.components.Producible")
local Actor                   = requireFW("src.global.actors.Actor")
local ActionCodeFunctions     = requireFW("src.app.utilities.ActionCodeFunctions")
local ActionPublisher         = requireFW("src.app.utilities.ActionPublisher")
local DamageCalculator        = requireFW("src.app.utilities.DamageCalculator")
local GameConstantFunctions   = requireFW("src.app.utilities.GameConstantFunctions")
local GridIndexFunctions      = requireFW("src.app.utilities.GridIndexFunctions")
local LocalizationFunctions   = requireFW("src.app.utilities.LocalizationFunctions")
local PlayerProfileManager    = requireFW("src.app.utilities.PlayerProfileManager")
local SceneWarManager         = requireFW("src.app.utilities.SceneWarManager")
local SerializationFunctions  = requireFW("src.app.utilities.SerializationFunctions")
local SkillDataAccessors      = requireFW("src.app.utilities.SkillDataAccessors")
local SkillModifierFunctions  = requireFW("src.app.utilities.SkillModifierFunctions")
local SingletonGetters        = requireFW("src.app.utilities.SingletonGetters")
local TableFunctions          = requireFW("src.app.utilities.TableFunctions")
local VisibilityFunctions     = requireFW("src.app.utilities.VisibilityFunctions")
local ComponentManager        = requireFW("src.global.components.ComponentManager")

local createActionsForPublish      = ActionPublisher.createActionsForPublish
local getLocalizedText             = LocalizationFunctions.getLocalizedText
local getModelFogMap               = SingletonGetters.getModelFogMap
local getModelPlayerManager        = SingletonGetters.getModelPlayerManager
local getModelTileMap              = SingletonGetters.getModelTileMap
local getModelTurnManager          = SingletonGetters.getModelTurnManager
local getModelUnitMap              = SingletonGetters.getModelUnitMap
local getRevealedTilesAndUnitsData = VisibilityFunctions.getRevealedTilesAndUnitsData
local isUnitVisible                = VisibilityFunctions.isUnitOnMapVisibleToPlayerIndex
local ipairs, pairs, next          = ipairs, pairs, next

local ACTION_CODES                   = ActionCodeFunctions.getFullList()
local GAME_VERSION                   = GameConstantFunctions.getGameVersion()
local MESSAGE_PARAM_OUT_OF_SYNC      = {"OutOfSync"}
local MAX_PARTICIPATED_WARS_COUNT    = 20
local IGNORED_ACTION_KEYS_FOR_SERVER = {"revealedTiles", "revealedUnits"}
local WAR_PASSWORD_VALID_TIME        = 3600 * 24 -- seconds of a day

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
local MESSAGE_INVALID_ACCOUNT_FOR_PROFILE = {
    actionCode    = ACTION_CODES.ActionMessage,
    messageCode   = 81,
    messageParams = {"InvalidAccountForProfile"},
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
local MESSAGE_NOT_EXITABLE_WAR = {
    actionCode    = ACTION_CODES.ActionMessage,
    messageCode   = 81,
    messageParams = {"NotExitableWar"},
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
local MESSAGE_OVERLOADED_RANK_SCORE = {
    actionCode    = ACTION_CODES.ActionMessage,
    messageCode   = 81,
    messageParams = {"OverloadedRankScore"},
}
local MESSAGE_OVERLOADED_WARS_COUNT = {
    actionCode    = ACTION_CODES.ActionMessage,
    messageCode   = 81,
    messageParams = {"OverloadedWarsCount"},
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
local function getPlayersCountWithWarFieldFileName(warFieldFileName)
    return requireFW("res.data.templateWarField." .. warFieldFileName).playersCount
end

local function getGameTypeIndexWithWarConfiguration(warConfiguration)
    return getPlayersCountWithWarFieldFileName(warConfiguration.warFieldFileName) * 2 - 3 + (warConfiguration.isFogOfWarByDefault and 1 or 0)
end

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
        (isUnitVisible(modelSceneWar, destination, modelUnit:getUnitType(), isModelUnitDiving(modelUnit), modelUnit:getPlayerIndex(), playerIndex))
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
    local maxNormalizedRepairAmount = GameConstantFunctions.getBaseNormalizedRepairAmount() -- + SkillModifierFunctions.getRepairAmountModifier(skillConfiguration)
    local costModifier              = 1 -- + SkillModifierFunctions.getRepairCostModifier(skillConfiguration) / 100

    local onMapData, loadedData
    for _, modelUnit in ipairs(getRepairableModelUnits(modelSceneWar)) do
        local repairAmount, repairCost = getRepairAmountAndCost(modelUnit, fund, maxNormalizedRepairAmount, costModifier)
        local unitID                   = modelUnit:getUnitId()
        if (modelUnitMap:getLoadedModelUnitWithUnitId(unitID)) then
            loadedData         = loadedData or {}
            loadedData[unitID] = {
                unitID       = unitID,
                repairAmount = repairAmount,
            }
        else
            onMapData         = onMapData or {}
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

local function generateSupplyDataOnBeginTurn(modelSceneWar, repairData)
    local modelUnitMap          = getModelUnitMap(modelSceneWar)
    local playerIndex           = getModelTurnManager(modelSceneWar):getPlayerIndex()
    local mapSize               = modelUnitMap:getMapSize()
    local repairDataOnMap       = repairData.onMapData
    local repairDataLoaded      = repairData.loadedData
    local onMapData, loadedData

    local updateOnMapData = function(supplier)
        if ((supplier:getPlayerIndex() == playerIndex) and (supplier.canSupplyModelUnit)) then
            if (((repairDataOnMap) and (repairDataOnMap[supplier:getUnitId()]))                                                        or
                (not ((supplier:shouldDestroyOnOutOfFuel()) and (supplier:getCurrentFuel() <= supplier:getFuelConsumptionPerTurn())))) then

                for _, adjacentGridIndex in pairs(GridIndexFunctions.getAdjacentGrids(supplier:getGridIndex(), mapSize)) do
                    local target = modelUnitMap:getModelUnit(adjacentGridIndex)
                    if ((target) and (supplier:canSupplyModelUnit(target))) then
                        local unitID = target:getUnitId()
                        if (((not repairDataOnMap) or (not repairDataOnMap[unitID]))                                                         and
                            ((not onMapData)       or (not onMapData[unitID]))                                                               and
                            (not ((target:shouldDestroyOnOutOfFuel()) and (target:getCurrentFuel() <= target:getFuelConsumptionPerTurn())))) then

                            onMapData         = onMapData or {}
                            onMapData[unitID] = {
                                unitID    = unitID,
                                gridIndex = adjacentGridIndex,
                            }
                        end
                    end
                end
            end
        end
    end

    local updateLoadedData = function(supplier)
        if ((supplier:getPlayerIndex() == playerIndex) and
            (supplier.canSupplyLoadedModelUnit)        and
            (supplier:canSupplyLoadedModelUnit())      and
            (not supplier:canRepairLoadedModelUnit())) then
            if (((repairDataOnMap) and (repairDataOnMap[supplier:getUnitId()]))                                                        or
                (not ((supplier:shouldDestroyOnOutOfFuel()) and (supplier:getCurrentFuel() <= supplier:getFuelConsumptionPerTurn())))) then

                for _, unitID in pairs(supplier:getLoadUnitIdList()) do
                    loadedData         = loadedData or {}
                    loadedData[unitID] = {unitID = unitID}
                end
            end
        end
    end

    modelUnitMap:forEachModelUnitOnMap(updateOnMapData)
        :forEachModelUnitOnMap(        updateLoadedData)
        :forEachModelUnitLoaded(       updateLoadedData)

    if ((not onMapData) and (not loadedData)) then
        return nil
    else
        return {
            onMapData  = onMapData,
            loadedData = loadedData,
        }
    end
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
    local destinations = action.dropDestinations
    if (#destinations < 1) then
        return false
    end

    local modelUnitMap             = getModelUnitMap(modelSceneWar)
    local modelTileMap             = getModelTileMap(modelSceneWar)
    local mapSize                  = modelTileMap:getMapSize()
    local pathNodes                = action.path.pathNodes
    local loaderBeginningGridIndex = pathNodes[1]
    local loaderEndingGridIndex    = pathNodes[#pathNodes]
    local loaderModelUnit          = modelUnitMap:getFocusModelUnit(loaderBeginningGridIndex, action.launchUnitID)
    local loaderEndingModelTile    = modelTileMap:getModelTile(loaderEndingGridIndex)
    local playerIndex              = loaderModelUnit:getPlayerIndex()

    for i = 1, #destinations do
        local droppingUnitID    = destinations[i].unitID
        local droppingGridIndex = destinations[i].gridIndex
        local droppingModelUnit = modelUnitMap:getLoadedModelUnitWithUnitId(droppingUnitID)
        if ((not droppingModelUnit)                                                                         or
            (not loaderModelUnit:hasLoadUnitId(droppingUnitID))                                             or
            (not GridIndexFunctions.isWithinMap(droppingGridIndex, mapSize))                                or
            (not GridIndexFunctions.isAdjacent(droppingGridIndex, loaderEndingGridIndex))                   or
            (not loaderEndingModelTile:getMoveCostWithModelUnit(droppingModelUnit))                         or
            (not modelTileMap:getModelTile(droppingGridIndex):getMoveCostWithModelUnit(droppingModelUnit))) then
            return false
        end

        local existingModelUnit = modelUnitMap:getModelUnit(droppingGridIndex)
        if ((existingModelUnit)                                                                                                                                                           and
            (existingModelUnit ~= loaderModelUnit)                                                                                                                                        and
            (isUnitVisible(modelSceneWar, droppingGridIndex, existingModelUnit:getUnitType(), isModelUnitDiving(existingModelUnit), existingModelUnit:getPlayerIndex(), playerIndex))) then
            return false
        end

        for j = i + 1, #destinations do
            local additionalDestination = destinations[j]
            if ((GridIndexFunctions.isEqual(droppingGridIndex, additionalDestination.gridIndex)) or
                (droppingUnitID == additionalDestination.unitID))                                then
                return false
            end
        end
    end

    return true
end

local function isDropDestinationBlocked(destination, modelUnitMap, loaderModelUnit)
    local existingModelUnit = modelUnitMap:getModelUnit(destination.gridIndex)
    return (existingModelUnit) and (existingModelUnit ~= loaderModelUnit)
end

local function translateDropDestinations(rawDestinations, modelUnitMap, loaderModelUnit)
    local translatedDestinations = {}
    local isDropBlocked
    for i = 1, #rawDestinations do
        if (isDropDestinationBlocked(rawDestinations[i], modelUnitMap, loaderModelUnit)) then
            isDropBlocked = true
        else
            translatedDestinations[#translatedDestinations + 1] = rawDestinations[i]
        end
    end

    return translatedDestinations, isDropBlocked
end

local function getLostPlayerIndexForActionAttack(modelSceneWar, attacker, target, attackDamage, counterDamage)
    local modelUnitMap = getModelUnitMap(modelSceneWar)
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

local function createActionForServer(action)
    return TableFunctions.clone(action, IGNORED_ACTION_KEYS_FOR_SERVER)
end

local function createActionReloadSceneWar(modelSceneWar, playerAccount, messageCode, messageParams)
    local _, playerIndex = getModelPlayerManager(modelSceneWar):getModelPlayerWithAccount(playerAccount)
    return {
        actionCode    = ACTION_CODES.ActionReloadSceneWar,
        warData       = modelSceneWar:toSerializableTableForPlayerIndex(playerIndex),
        messageCode   = messageCode,
        messageParams = messageParams,
    }
end

local function isPlayerInTurnInWar(modelSceneWar, playerAccount)
    local playerIndex = getModelTurnManager(modelSceneWar):getPlayerIndex()
    return getModelPlayerManager(modelSceneWar):getModelPlayer(playerIndex):getAccount() == playerAccount
end

local function isPlayerAliveInWar(modelSceneWar, playerAccount)
    local modelPlayer = getModelPlayerManager(modelSceneWar):getModelPlayerWithAccount(playerAccount)
    return (modelPlayer) and (modelPlayer:isAlive())
end

local function getModelSceneWarWithAction(action)
    local playerAccount = action.playerAccount
    if (not PlayerProfileManager.isAccountAndPasswordValid(action.playerAccount, action.playerPassword)) then
        return nil, LOGOUT_INVALID_ACCOUNT_PASSWORD
    end

    local modelSceneWar = SceneWarManager.getOngoingModelSceneWar(action.warID)
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

local function createActionWait(warID, actionID, path, launchUnitID, revealedTiles, revealedUnits)
    return {
        actionCode    = ACTION_CODES.ActionWait,
        actionID      = actionID,
        launchUnitID  = launchUnitID,
        path          = path,
        revealedTiles = revealedTiles,
        revealedUnits = revealedUnits,
        warID         = warID,
    }
end

--------------------------------------------------------------------------------
-- The translate functions.
--------------------------------------------------------------------------------
local function translateChat(action)
    local playerAccount = action.playerAccount
    if (not PlayerProfileManager.isAccountAndPasswordValid(action.playerAccount, action.playerPassword)) then
        return nil, LOGOUT_INVALID_ACCOUNT_PASSWORD
    end

    local modelSceneWar = SceneWarManager.getOngoingModelSceneWar(action.warID)
    if (not modelSceneWar) then
        return nil, RUN_SCENE_MAIN_ENDED_WAR
    elseif (not isPlayerAliveInWar(modelSceneWar, playerAccount)) then
        return nil, RUN_SCENE_MAIN_DEFEATED_PLAYER
    end

    -- TODO: validate more params.
    local _, playerIndex = SingletonGetters.getModelPlayerManager(modelSceneWar):getModelPlayerWithAccount(playerAccount)
    local actionChat = {
        actionCode        = ACTION_CODES.ActionChat,
        senderPlayerIndex = playerIndex,
        warID             = action.warID,
        channelID         = action.channelID,
        chatText          = action.chatText,
    }
    return actionChat, createActionsForPublish(actionChat, modelSceneWar), createActionForServer(actionChat)
end

local function translateDownloadReplayData(action)
    local encodedReplayData = SceneWarManager.getEncodedReplayData(action.warID)
    if (not encodedReplayData) then
        return MESSAGE_NO_REPLAY_DATA
    else
        return {
            actionCode        = ACTION_CODES.ActionDownloadReplayData,
            encodedReplayData = encodedReplayData,
        }
    end
end

local function translateExitWar(action)
    local playerAccount = action.playerAccount
    if (not PlayerProfileManager.isAccountAndPasswordValid(playerAccount, action.playerPassword)) then
        return LOGOUT_INVALID_ACCOUNT_PASSWORD
    elseif (not SceneWarManager.isPlayerWaitingForWarId(playerAccount, action.warID)) then
        return MESSAGE_NOT_EXITABLE_WAR
    end

    return {
        actionCode = ACTION_CODES.ActionExitWar,
        warID      = action.warID,
    }, nil, action
end

local function translateGetJoinableWarConfigurations(action)
    if (not PlayerProfileManager.isAccountAndPasswordValid(action.playerAccount, action.playerPassword)) then
        return LOGOUT_INVALID_ACCOUNT_PASSWORD
    end

    return {
        actionCode        = ACTION_CODES.ActionGetJoinableWarConfigurations,
        warConfigurations = SceneWarManager.getJoinableWarConfigurations(action.playerAccount, action.warID),
    }
end

local function translateGetOngoingWarConfigurations(action)
    local playerAccount = action.playerAccount
    if (not PlayerProfileManager.isAccountAndPasswordValid(action.playerAccount, action.playerPassword)) then
        return LOGOUT_INVALID_ACCOUNT_PASSWORD
    end

    return {
        actionCode        = ACTION_CODES.ActionGetOngoingWarConfigurations,
        warConfigurations = SceneWarManager.getOngoingWarConfigurationsForPlayer(playerAccount),
    }
end

local function translateGetPlayerProfile(action)
    local profile = PlayerProfileManager.getPlayerProfile(action.playerAccount)
    if (not profile) then
        return MESSAGE_INVALID_ACCOUNT_FOR_PROFILE
    else
        return {
            actionCode    = ACTION_CODES.ActionGetPlayerProfile,
            playerAccount = action.playerAccount,
            playerProfile = profile,
        }
    end
end

local function translateGetRankingList(action)
    local rankingList   = {}
    local accountsCount = 0
    for i, item in ipairs(PlayerProfileManager.getRankingLists()[action.rankingListIndex].list) do
        if (accountsCount >= 50) then
            break
        end
        accountsCount = accountsCount + #(item.accounts)
        rankingList[i] = item
    end

    return {
        actionCode       = ACTION_CODES.ActionGetRankingList,
        rankingListIndex = action.rankingListIndex,
        rankingList      = rankingList,
    }
end

local function translateGetWaitingWarConfigurations(action)
    local playerAccount = action.playerAccount
    if (not PlayerProfileManager.isAccountAndPasswordValid(action.playerAccount, action.playerPassword)) then
        return LOGOUT_INVALID_ACCOUNT_PASSWORD
    end

    return {
        actionCode        = ACTION_CODES.ActionGetWaitingWarConfigurations,
        warConfigurations = SceneWarManager.getWaitingWarConfigurationsForPlayer(playerAccount),
    }
end

local function translateJoinWar(action)
    local playerAccount = action.playerAccount
    if (not PlayerProfileManager.isAccountAndPasswordValid(playerAccount, action.playerPassword)) then
        return LOGOUT_INVALID_ACCOUNT_PASSWORD
    elseif (PlayerProfileManager.getParticipatedWarsCount(playerAccount) >= MAX_PARTICIPATED_WARS_COUNT) then
        return MESSAGE_OVERLOADED_WARS_COUNT
    end

    local warID              = action.warID
    local warConfiguration   = SceneWarManager.getJoinableSceneWarConfiguration(warID)
    local playerIndexJoining = action.playerIndex
    if (not warConfiguration) then
        return MESSAGE_NOT_JOINABLE_WAR
    elseif ((warConfiguration.warPassword ~= action.warPassword) and (warConfiguration.createdTime) and ((ngx.time() - warConfiguration.createdTime) < WAR_PASSWORD_VALID_TIME)) then
        return MESSAGE_INVALID_WAR_PASSWORD
    elseif (SceneWarManager.hasPlayerJoinedWar(playerAccount, warConfiguration)) then
        return MESSAGE_MULTI_JOIN_WAR
    elseif (warConfiguration.players[playerIndexJoining]) then
        return MESSAGE_OCCUPIED_PLAYER_INDEX
    elseif ((playerIndexJoining < 1) or (playerIndexJoining > getPlayersCountWithWarFieldFileName(warConfiguration.warFieldFileName))) then
        return MESSAGE_OCCUPIED_PLAYER_INDEX
    end

    if (warConfiguration.maxDiffScore) then
        local gameTypeIndex  = getGameTypeIndexWithWarConfiguration(warConfiguration)
        local totalRankScore = 0
        local playersCount   = 0
        for playerIndex, playerInfo in pairs(warConfiguration.players) do
            playersCount   = playersCount + 1
            totalRankScore = totalRankScore + PlayerProfileManager.getPlayerProfile(playerInfo.account).gameRecords[gameTypeIndex].rankScore
        end
        if (math.abs(totalRankScore / playersCount - PlayerProfileManager.getPlayerProfile(playerAccount).gameRecords[gameTypeIndex].rankScore) > warConfiguration.maxDiffScore) then
            return MESSAGE_OVERLOADED_RANK_SCORE
        end
    end

    return {
        actionCode   = ACTION_CODES.ActionJoinWar,
        warID        = warID,
        isWarStarted = SceneWarManager.isWarReadyForStartAfterJoin(warConfiguration),
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
    local playerAccount = action.playerAccount
    local actionNetworkHeartbeat = {
        actionCode       = ACTION_CODES.ActionNetworkHeartbeat,
        heartbeatCounter = action.heartbeatCounter,
    }

    if (not PlayerProfileManager.isAccountAndPasswordValid(playerAccount, action.playerPassword)) then
        return actionNetworkHeartbeat
    else
        return actionNetworkHeartbeat, nil, {
            actionCode    = ACTION_CODES.ActionNetworkHeartbeat,
            playerAccount = playerAccount,
        }
    end
end

local function translateNewWar(action)
    local playerAccount = action.playerAccount
    if (not PlayerProfileManager.isAccountAndPasswordValid(playerAccount, action.playerPassword)) then
        return LOGOUT_INVALID_ACCOUNT_PASSWORD
    elseif (PlayerProfileManager.getParticipatedWarsCount(playerAccount) >= MAX_PARTICIPATED_WARS_COUNT) then
        return MESSAGE_OVERLOADED_WARS_COUNT
    end

    -- TODO: validate more params.

    return {
        actionCode = ACTION_CODES.ActionNewWar,
        warID      = SceneWarManager.getNextWarId(),
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

    local modelSceneWar = SceneWarManager.getOngoingModelSceneWar(action.warID)
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

    local modelSceneWar = SceneWarManager.getOngoingModelSceneWar(action.warID)
    if (not modelSceneWar) then
        return MESSAGE_ENDED_WAR
    elseif (not isPlayerAliveInWar(modelSceneWar, playerAccount)) then
        return MESSAGE_DEFEATED_PLAYER
    else
        local _, playerIndex = getModelPlayerManager(modelSceneWar):getModelPlayerWithAccount(playerAccount)
        return {
            actionCode = ACTION_CODES.ActionRunSceneWar,
            warData    = modelSceneWar:toSerializableTableForPlayerIndex(playerIndex),
        }
    end
end

local function translateSyncSceneWar(action)
    local playerAccount = action.playerAccount
    if (not PlayerProfileManager.isAccountAndPasswordValid(playerAccount, action.playerPassword)) then
        return LOGOUT_INVALID_ACCOUNT_PASSWORD
    end

    local modelSceneWar = SceneWarManager.getOngoingModelSceneWar(action.warID)
    if (not modelSceneWar) then
        return RUN_SCENE_MAIN_ENDED_WAR
    elseif (not isPlayerAliveInWar(modelSceneWar, playerAccount)) then
        return RUN_SCENE_MAIN_DEFEATED_PLAYER
    elseif (modelSceneWar:getActionId() > action.actionID) then
        return createActionReloadSceneWar(modelSceneWar, playerAccount, 81, {"AutoSyncWar"})
    else
        return {
            actionCode = ACTION_CODES.ActionSyncSceneWar,
            actionID   = action.actionID,
            warID      = action.warID,
        }
    end
end

local function translateGetReplayConfigurations(action)
    return {
        actionCode           = ACTION_CODES.ActionGetReplayConfigurations,
        replayConfigurations = SceneWarManager.getReplayConfigurations(action.warID),
    }
end

-- This translation ignores the existing unit of the same player at the end of the path, so that the actions of Join/Attack/Wait can reuse this function.
local function translatePath(path, launchUnitID, modelSceneWar)
    local modelTurnManager   = getModelTurnManager(modelSceneWar)
    local modelUnitMap       = getModelUnitMap(modelSceneWar)
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

    local modelTileMap         = getModelTileMap(modelSceneWar)
    local translatedPathNodes  = {GridIndexFunctions.clone(beginningGridIndex)}
    local translatedPath       = {pathNodes = translatedPathNodes}
    local totalFuelConsumption = 0
    local maxFuelConsumption   = math.min(focusModelUnit:getCurrentFuel(), focusModelUnit:getMoveRange())

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
            if (isUnitVisible(modelSceneWar, gridIndex, existingModelUnit:getUnitType(), isModelUnitDiving(existingModelUnit), existingModelUnit:getPlayerIndex(), playerIndexInTurn)) then
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

local function translateActivateSkill(action)
    local modelSceneWar, actionOnError = getModelSceneWarWithAction(action)
    if (not modelSceneWar) then
        return actionOnError
    end

    local skillID          = action.skillID
    local skillLevel       = action.skillLevel
    local isActiveSkill    = action.isActiveSkill
    local modelTurnManager = getModelTurnManager(modelSceneWar)
    local modelPlayer      = getModelPlayerManager(modelSceneWar):getModelPlayer(modelTurnManager:getPlayerIndex())
    if ((not modelTurnManager:isTurnPhaseMain())                                                                   or
        ((isActiveSkill) and ((not modelPlayer:canActivateSkill()) or (not modelSceneWar:isActiveSkillEnabled()))) or
        ((not isActiveSkill) and (not modelSceneWar:isPassiveSkillEnabled()))                                      or
        (modelPlayer:getEnergy() < SkillDataAccessors.getSkillPoints(skillID, skillLevel, isActiveSkill)))         then
        return createActionReloadSceneWar(modelSceneWar, action.playerAccount, 81, MESSAGE_PARAM_OUT_OF_SYNC)
    end

    local revealedTiles, revealedUnits = VisibilityFunctions.getRevealedTilesAndUnitsDataForSkillActivation(modelSceneWar, skillID)
    local actionActivateSkill = {
        actionCode    = ACTION_CODES.ActionActivateSkill,
        actionID      = action.actionID,
        warID         = action.warID,
        skillID       = skillID,
        skillLevel    = skillLevel,
        isActiveSkill = isActiveSkill,
        revealedTiles = revealedTiles,
        revealedUnits = revealedUnits,
    }
    return actionActivateSkill, createActionsForPublish(actionActivateSkill, modelSceneWar), createActionForServer(actionActivateSkill)
end

local function translateAttack(action)
    local modelSceneWar, actionOnError = getModelSceneWarWithAction(action)
    if (not modelSceneWar) then
        return actionOnError
    end

    local rawPath, launchUnitID        = action.path, action.launchUnitID
    local translatedPath, translateMsg = translatePath(rawPath, launchUnitID, modelSceneWar)
    if ((not translatedPath) or (isPathDestinationOccupiedByVisibleUnit(modelSceneWar, rawPath))) then
        return createActionReloadSceneWar(modelSceneWar, action.playerAccount, 81, MESSAGE_PARAM_OUT_OF_SYNC)
    end

    local modelUnitMap        = getModelUnitMap(modelSceneWar)
    local attacker            = modelUnitMap:getFocusModelUnit(rawPath.pathNodes[1], launchUnitID)
    local targetGridIndex     = action.targetGridIndex
    local attackTarget        = modelUnitMap:getModelUnit(targetGridIndex) or getModelTileMap(modelSceneWar):getModelTile(targetGridIndex)
    if ((not ComponentManager.getComponent(attacker, "AttackDoer"))                                                                                                                                                     or
        (not GridIndexFunctions.isWithinMap(targetGridIndex, modelUnitMap:getMapSize()))                                                                                                                                or
        ((attackTarget.getUnitType) and (not isUnitVisible(modelSceneWar, targetGridIndex, attackTarget:getUnitType(), isModelUnitDiving(attackTarget), attackTarget:getPlayerIndex(), attacker:getPlayerIndex())))) then
        return createActionReloadSceneWar(modelSceneWar, action.playerAccount, 81, MESSAGE_PARAM_OUT_OF_SYNC)
    end

    local attackDamage, counterDamage = DamageCalculator.getUltimateBattleDamage(rawPath.pathNodes, launchUnitID, targetGridIndex, modelSceneWar)
    if (not attackDamage) then
        return createActionReloadSceneWar(modelSceneWar, action.playerAccount, 81, MESSAGE_PARAM_OUT_OF_SYNC)
    end

    local revealedTiles, revealedUnits = getRevealedTilesAndUnitsData(modelSceneWar, translatedPath.pathNodes, attacker, (counterDamage) and (counterDamage >= attacker:getCurrentHP()))
    if (translatedPath.isBlocked) then
        local actionWait = createActionWait(action.warID, action.actionID, translatedPath, launchUnitID, revealedTiles, revealedUnits)
        return actionWait, createActionsForPublish(actionWait, modelSceneWar), createActionForServer(actionWait)
    else
        local actionAttack = {
            actionCode       = ACTION_CODES.ActionAttack,
            actionID         = action.actionID,
            warID            = action.warID,
            path             = translatedPath,
            launchUnitID     = launchUnitID,
            targetGridIndex  = targetGridIndex,
            attackDamage     = attackDamage,
            counterDamage    = counterDamage,
            revealedTiles    = revealedTiles,
            revealedUnits    = revealedUnits,
            lostPlayerIndex  = getLostPlayerIndexForActionAttack(modelSceneWar, attacker, attackTarget, attackDamage, counterDamage),
        }
        return actionAttack, createActionsForPublish(actionAttack, modelSceneWar), createActionForServer(actionAttack)
    end
end

local function translateBeginTurn(action)
    local modelSceneWar, actionOnError = getModelSceneWarWithAction(action)
    if (not modelSceneWar) then
        return actionOnError
    end

    local modelTurnManager = getModelTurnManager(modelSceneWar)
    if (not modelTurnManager:isTurnPhaseRequestToBegin()) then
        return createActionReloadSceneWar(modelSceneWar, action.playerAccount, 81, MESSAGE_PARAM_OUT_OF_SYNC)
    end

    local actionBeginTurn = {
        actionCode       = ACTION_CODES.ActionBeginTurn,
        actionID         = action.actionID,
        warID            = action.warID,
    }
    if (modelTurnManager:getTurnIndex() == 1) then
        actionBeginTurn.income = getIncomeOnBeginTurn(modelSceneWar)
    else
        actionBeginTurn.lostPlayerIndex = (areAllUnitsDestroyedOnBeginTurn(modelSceneWar)) and (modelTurnManager:getPlayerIndex()) or (nil)
        actionBeginTurn.repairData      = generateRepairDataOnBeginTurn(modelSceneWar)
        actionBeginTurn.supplyData      = generateSupplyDataOnBeginTurn(modelSceneWar, actionBeginTurn.repairData)
    end
    return actionBeginTurn, createActionsForPublish(actionBeginTurn, modelSceneWar), createActionForServer(actionBeginTurn)
end

local function translateBuildModelTile(action)
    local modelSceneWar, actionOnError = getModelSceneWarWithAction(action)
    if (not modelSceneWar) then
        return actionOnError
    end

    local rawPath, launchUnitID        = action.path, action.launchUnitID
    local translatedPath, translateMsg = translatePath(rawPath, launchUnitID, modelSceneWar)
    if ((not translatedPath) or (isPathDestinationOccupiedByVisibleUnit(modelSceneWar, rawPath))) then
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

    local revealedTiles, revealedUnits = getRevealedTilesAndUnitsData(modelSceneWar, translatedPath.pathNodes, focusModelUnit, false)
    if (translatedPath.isBlocked) then
        local actionWait = createActionWait(action.warID, action.actionID, translatedPath, launchUnitID, revealedTiles, revealedUnits)
        return actionWait, createActionsForPublish(actionWait, modelSceneWar), createActionForServer(actionWait)
    else
        if (focusModelUnit:getBuildAmount() >= modelTile:getCurrentBuildPoint()) then
            local tiles, units = VisibilityFunctions.getRevealedTilesAndUnitsDataForBuild(modelSceneWar, endingGridIndex, focusModelUnit)
            revealedTiles = TableFunctions.union(revealedTiles, tiles)
            revealedUnits = TableFunctions.union(revealedUnits, units)
        end
        local actionBuildModelTile = {
            actionCode       = ACTION_CODES.ActionBuildModelTile,
            actionID         = action.actionID,
            warID            = action.warID,
            path             = translatedPath,
            launchUnitID     = launchUnitID,
            revealedTiles    = revealedTiles,
            revealedUnits    = revealedUnits,
        }
        return actionBuildModelTile, createActionsForPublish(actionBuildModelTile, modelSceneWar), createActionForServer(actionBuildModelTile)
    end
end

local function translateCaptureModelTile(action)
    local modelSceneWar, actionOnError = getModelSceneWarWithAction(action)
    if (not modelSceneWar) then
        return actionOnError
    end

    local rawPath, launchUnitID        = action.path, action.launchUnitID
    local translatedPath, translateMsg = translatePath(rawPath, launchUnitID, modelSceneWar)
    if ((not translatedPath) or (isPathDestinationOccupiedByVisibleUnit(modelSceneWar, rawPath))) then
        return createActionReloadSceneWar(modelSceneWar, action.playerAccount, 81, MESSAGE_PARAM_OUT_OF_SYNC)
    end

    local rawPathNodes    = rawPath.pathNodes
    local endingGridIndex = rawPathNodes[#rawPathNodes]
    local capturer        = getModelUnitMap(modelSceneWar):getFocusModelUnit(rawPathNodes[1], launchUnitID)
    local captureTarget   = getModelTileMap(modelSceneWar):getModelTile(endingGridIndex)
    if ((not capturer.canCaptureModelTile) or (not capturer:canCaptureModelTile(captureTarget))) then
        return createActionReloadSceneWar(modelSceneWar, action.playerAccount, 81, MESSAGE_PARAM_OUT_OF_SYNC)
    end

    local revealedTiles, revealedUnits = getRevealedTilesAndUnitsData(modelSceneWar, translatedPath.pathNodes, capturer, false)
    if (translatedPath.isBlocked) then
        local actionWait = createActionWait(action.warID, action.actionID, translatedPath, launchUnitID, revealedTiles, revealedUnits)
        return actionWait, createActionsForPublish(actionWait, modelSceneWar), createActionForServer(actionWait)
    else
        local isCaptureFinished = capturer:getCaptureAmount() >= captureTarget:getCurrentCapturePoint()
        if (isCaptureFinished) then
            local tiles, units = VisibilityFunctions.getRevealedTilesAndUnitsDataForCapture(modelSceneWar, endingGridIndex, capturer:getPlayerIndex())
            revealedTiles = TableFunctions.union(revealedTiles, tiles)
            revealedUnits = TableFunctions.union(revealedUnits, units)
        end

        local actionCapture = {
            actionCode       = ACTION_CODES.ActionCaptureModelTile,
            actionID         = action.actionID,
            warID            = action.warID,
            path             = translatedPath,
            launchUnitID     = launchUnitID,
            revealedTiles    = revealedTiles,
            revealedUnits    = revealedUnits,
            lostPlayerIndex  = ((isCaptureFinished) and (captureTarget:isDefeatOnCapture()))
                and (captureTarget:getPlayerIndex())
                or  (nil),
        }
        return actionCapture, createActionsForPublish(actionCapture, modelSceneWar), createActionForServer(actionCapture)
    end
end

local function translateDeclareSkill(action)
    local modelSceneWar, actionOnError = getModelSceneWarWithAction(action)
    if (not modelSceneWar) then
        return actionOnError
    end

    local modelTurnManager = getModelTurnManager(modelSceneWar)
    local modelPlayer      = getModelPlayerManager(modelSceneWar):getModelPlayer(modelTurnManager:getPlayerIndex())
    if ((not modelTurnManager:isTurnPhaseMain())                                  or
        (not modelSceneWar:isActiveSkillEnabled())                                or
        (modelPlayer:isSkillDeclared())                                           or
        (modelPlayer:getEnergy() < SkillDataAccessors.getSkillDeclarationCost())) then
        return createActionReloadSceneWar(modelSceneWar, action.playerAccount, 81, MESSAGE_PARAM_OUT_OF_SYNC)
    end

    return action, createActionsForPublish(action, modelSceneWar), createActionForServer(action)
end

local function translateDestroyOwnedModelUnit(action)
    local modelSceneWar, actionOnError = getModelSceneWarWithAction(action)
    if (not modelSceneWar) then
        return actionOnError
    end

    local modelUnit = getModelUnitMap(modelSceneWar):getModelUnit(action.gridIndex)
    if ((not getModelTurnManager(modelSceneWar):isTurnPhaseMain())                          or
        (not modelUnit)                                                                      or
        (modelUnit:getPlayerIndex() ~= getModelTurnManager(modelSceneWar):getPlayerIndex()) or
        (not modelUnit:isStateIdle()))                                                       then
        return createActionReloadSceneWar(modelSceneWar, action.playerAccount, 81, MESSAGE_PARAM_OUT_OF_SYNC)
    end

    local actionDestroyOwnedModelUnit = {
        actionCode       = ACTION_CODES.ActionDestroyOwnedModelUnit,
        actionID         = action.actionID,
        warID            = action.warID,
        gridIndex        = action.gridIndex,
    }
    return actionDestroyOwnedModelUnit, createActionsForPublish(actionDestroyOwnedModelUnit, modelSceneWar), createActionForServer(actionDestroyOwnedModelUnit)
end

local function translateDive(action)
    local modelSceneWar, actionOnError = getModelSceneWarWithAction(action)
    if (not modelSceneWar) then
        return actionOnError
    end

    local rawPath, launchUnitID        = action.path, action.launchUnitID
    local translatedPath, translateMsg = translatePath(rawPath, launchUnitID, modelSceneWar)
    if ((not translatedPath) or (isPathDestinationOccupiedByVisibleUnit(modelSceneWar, rawPath))) then
        return createActionReloadSceneWar(modelSceneWar, action.playerAccount, 81, MESSAGE_PARAM_OUT_OF_SYNC)
    end

    local focusModelUnit = getModelUnitMap(modelSceneWar):getFocusModelUnit(rawPath.pathNodes[1], launchUnitID)
    if ((not focusModelUnit.canDive) or (not focusModelUnit:canDive())) then
        return createActionReloadSceneWar(modelSceneWar, action.playerAccount, 81, MESSAGE_PARAM_OUT_OF_SYNC)
    end

    local revealedTiles, revealedUnits = getRevealedTilesAndUnitsData(modelSceneWar, translatedPath.pathNodes, focusModelUnit, false)
    if (translatedPath.isBlocked) then
        local actionWait = createActionWait(action.warID, action.actionID, translatedPath, launchUnitID, revealedTiles, revealedUnits)
        return actionWait, createActionsForPublish(actionWait, modelSceneWar), createActionForServer(actionWait)
    else
        local actionDive = {
            actionCode       = ACTION_CODES.ActionDive,
            actionID         = action.actionID,
            warID            = action.warID,
            path             = translatedPath,
            launchUnitID     = launchUnitID,
            revealedTiles    = revealedTiles,
            revealedUnits    = revealedUnits,
        }
        return actionDive, createActionsForPublish(actionDive, modelSceneWar), createActionForServer(actionDive)
    end
end

local function translateDropModelUnit(action)
    local modelSceneWar, actionOnError = getModelSceneWarWithAction(action)
    if (not modelSceneWar) then
        return actionOnError
    end

    local rawPath, launchUnitID        = action.path, action.launchUnitID
    local translatedPath, translateMsg = translatePath(rawPath, launchUnitID, modelSceneWar)
    if ((not translatedPath) or (isPathDestinationOccupiedByVisibleUnit(modelSceneWar, rawPath))) then
        return createActionReloadSceneWar(modelSceneWar, action.playerAccount, 81, MESSAGE_PARAM_OUT_OF_SYNC)
    end

    local modelUnitMap    = getModelUnitMap(modelSceneWar)
    local rawPathNodes    = rawPath.pathNodes
    local endingGridIndex = rawPathNodes[#rawPathNodes]
    local loaderModelUnit = modelUnitMap:getFocusModelUnit(rawPathNodes[1], launchUnitID)
    local tileType        = getModelTileMap(modelSceneWar):getModelTile(endingGridIndex):getTileType()
    if ((not loaderModelUnit.canDropModelUnit)                 or
        (not loaderModelUnit:canDropModelUnit(tileType))       or
        (not validateDropDestinations(action, modelSceneWar))) then
        return createActionReloadSceneWar(modelSceneWar, action.playerAccount, 81, MESSAGE_PARAM_OUT_OF_SYNC)
    end

    local revealedTiles, revealedUnits = getRevealedTilesAndUnitsData(modelSceneWar, translatedPath.pathNodes, loaderModelUnit, false)
    if (translatedPath.isBlocked) then
        local actionWait = createActionWait(action.warID, action.actionID, translatedPath, launchUnitID, revealedTiles, revealedUnits)
        return actionWait, createActionsForPublish(actionWait, modelSceneWar), createActionForServer(actionWait)
    else
        local dropDestinations, isDropBlocked = translateDropDestinations(action.dropDestinations, modelUnitMap, loaderModelUnit)
        for _, dropDestination in ipairs(dropDestinations) do
            local dropModelUnit = modelUnitMap:getLoadedModelUnitWithUnitId(dropDestination.unitID)
            local tiles, units  = getRevealedTilesAndUnitsData(modelSceneWar, {endingGridIndex, dropDestination.gridIndex}, dropModelUnit, false)
            revealedTiles = TableFunctions.union(revealedTiles, tiles)
            revealedUnits = TableFunctions.union(revealedUnits, units)
        end

        local actionDropModelUnit = {
            actionCode       = ACTION_CODES.ActionDropModelUnit,
            actionID         = action.actionID,
            warID            = action.warID,
            path             = translatedPath,
            dropDestinations = dropDestinations,
            isDropBlocked    = isDropBlocked,
            launchUnitID     = launchUnitID,
            revealedTiles    = revealedTiles,
            revealedUnits    = revealedUnits,
        }
        return actionDropModelUnit, createActionsForPublish(actionDropModelUnit, modelSceneWar), createActionForServer(actionDropModelUnit)
    end
end

local function translateEndTurn(action)
    local modelSceneWar, actionOnError = getModelSceneWarWithAction(action)
    if (not modelSceneWar) then
        return actionOnError
    end

    local modelTurnManager = getModelTurnManager(modelSceneWar)
    local modelPlayer      = getModelPlayerManager(modelSceneWar):getModelPlayer(modelTurnManager:getPlayerIndex())
    if ((not modelTurnManager:isTurnPhaseMain())                                              or
        ((modelSceneWar:getRemainingVotesForDraw()) and (not modelPlayer:hasVotedForDraw()))) then
        return createActionReloadSceneWar(modelSceneWar, action.playerAccount, 81, MESSAGE_PARAM_OUT_OF_SYNC)
    end

    local actionEndTurn = {
        actionCode       = ACTION_CODES.ActionEndTurn,
        actionID         = action.actionID,
        warID            = action.warID,
    }
    return actionEndTurn, createActionsForPublish(actionEndTurn, modelSceneWar), createActionForServer(actionEndTurn)
end

local function translateJoinModelUnit(action)
    local modelSceneWar, actionOnError = getModelSceneWarWithAction(action)
    if (not modelSceneWar) then
        return actionOnError
    end

    local rawPath, launchUnitID        = action.path, action.launchUnitID
    local translatedPath, translateMsg = translatePath(rawPath, launchUnitID, modelSceneWar)
    if (not translatedPath) then
        return createActionReloadSceneWar(modelSceneWar, action.playerAccount, 81, MESSAGE_PARAM_OUT_OF_SYNC)
    end

    local rawPathNodes      = rawPath.pathNodes
    local modelUnitMap      = getModelUnitMap(modelSceneWar)
    local existingModelUnit = modelUnitMap:getModelUnit(rawPathNodes[#rawPathNodes])
    local focusModelUnit    = modelUnitMap:getFocusModelUnit(rawPathNodes[1], launchUnitID)
    if ((#rawPathNodes == 1)                                      or
        (not existingModelUnit)                                   or
        (not focusModelUnit.canJoinModelUnit)                     or
        (not focusModelUnit:canJoinModelUnit(existingModelUnit))) then
        return createActionReloadSceneWar(modelSceneWar, action.playerAccount, 81, MESSAGE_PARAM_OUT_OF_SYNC)
    end

    local revealedTiles, revealedUnits = getRevealedTilesAndUnitsData(modelSceneWar, translatedPath.pathNodes, focusModelUnit, false)
    if (translatedPath.isBlocked) then
        local actionWait = createActionWait(action.warID, action.actionID, translatedPath, launchUnitID, revealedTiles, revealedUnits)
        return actionWait, createActionsForPublish(actionWait, modelSceneWar), createActionForServer(actionWait)
    else
        local actionJoinModelUnit = {
            actionCode       = ACTION_CODES.ActionJoinModelUnit,
            actionID         = action.actionID,
            warID            = action.warID,
            path             = translatedPath,
            launchUnitID     = launchUnitID,
            revealedTiles    = revealedTiles,
            revealedUnits    = revealedUnits,
        }
        return actionJoinModelUnit, createActionsForPublish(actionJoinModelUnit, modelSceneWar), createActionForServer(actionJoinModelUnit)
    end
end

local function translateLaunchFlare(action)
    local modelSceneWar, actionOnError = getModelSceneWarWithAction(action)
    if (not modelSceneWar) then
        return actionOnError
    end

    local rawPath, launchUnitID        = action.path, action.launchUnitID
    local translatedPath, translateMsg = translatePath(rawPath, launchUnitID, modelSceneWar)
    if ((not translatedPath) or (isPathDestinationOccupiedByVisibleUnit(modelSceneWar, rawPath))) then
        return createActionReloadSceneWar(modelSceneWar, action.playerAccount, 81, MESSAGE_PARAM_OUT_OF_SYNC)
    end

    local rawPathNodes    = rawPath.pathNodes
    local modelUnitMap    = getModelUnitMap(modelSceneWar)
    local targetGridIndex = action.targetGridIndex
    local focusModelUnit  = modelUnitMap:getFocusModelUnit(rawPathNodes[1], launchUnitID)
    if ((#rawPathNodes > 1)                                                                                                 or
        (not focusModelUnit.getCurrentFlareAmmo)                                                                            or
        (focusModelUnit:getCurrentFlareAmmo() == 0)                                                                         or
        (not getModelFogMap(modelSceneWar):isFogOfWarCurrently())                                                           or
        (not GridIndexFunctions.isWithinMap(targetGridIndex, modelUnitMap:getMapSize()))                                    or
        (GridIndexFunctions.getDistance(targetGridIndex, rawPathNodes[#rawPathNodes]) > focusModelUnit:getMaxFlareRange())) then
        return createActionReloadSceneWar(modelSceneWar, action.playerAccount, 81, MESSAGE_PARAM_OUT_OF_SYNC)
    end

    local revealedTiles, revealedUnits = getRevealedTilesAndUnitsData(modelSceneWar, translatedPath.pathNodes, focusModelUnit, false)
    if (translatedPath.isBlocked) then
        local actionWait = createActionWait(action.warID, action.actionID, translatedPath, launchUnitID, revealedTiles, revealedUnits)
        return actionWait, createActionsForPublish(actionWait, modelSceneWar), createActionForServer(actionWait)
    else
        local tiles, units = VisibilityFunctions.getRevealedTilesAndUnitsDataForFlare(modelSceneWar, targetGridIndex, focusModelUnit:getFlareAreaRadius(), focusModelUnit:getPlayerIndex())
        local actionLaunchFlare = {
            actionCode       = ACTION_CODES.ActionLaunchFlare,
            actionID         = action.actionID,
            warID            = action.warID,
            path             = translatedPath,
            targetGridIndex  = targetGridIndex,
            launchUnitID     = launchUnitID,
            revealedTiles    = TableFunctions.union(revealedTiles, tiles),
            revealedUnits    = TableFunctions.union(revealedUnits, units),
        }
        return actionLaunchFlare, createActionsForPublish(actionLaunchFlare, modelSceneWar), createActionForServer(actionLaunchFlare)
    end
end

local function translateLaunchSilo(action)
    local modelSceneWar, actionOnError = getModelSceneWarWithAction(action)
    if (not modelSceneWar) then
        return actionOnError
    end

    local rawPath, launchUnitID        = action.path, action.launchUnitID
    local translatedPath, translateMsg = translatePath(rawPath, launchUnitID, modelSceneWar)
    if ((not translatedPath) or (isPathDestinationOccupiedByVisibleUnit(modelSceneWar, rawPath))) then
        return createActionReloadSceneWar(modelSceneWar, action.playerAccount, 81, MESSAGE_PARAM_OUT_OF_SYNC)
    end

    local modelUnitMap    = getModelUnitMap(modelSceneWar)
    local targetGridIndex = action.targetGridIndex
    local rawPathNodes    = rawPath.pathNodes
    local focusModelUnit  = modelUnitMap:getFocusModelUnit(rawPathNodes[1], launchUnitID)
    if ((not focusModelUnit.canLaunchSiloOnTileType)                                                                                         or
        (not focusModelUnit:canLaunchSiloOnTileType(getModelTileMap(modelSceneWar):getModelTile(rawPathNodes[#rawPathNodes]):getTileType())) or
        (not GridIndexFunctions.isWithinMap(targetGridIndex, modelUnitMap:getMapSize())))                                                    then
        return createActionReloadSceneWar(modelSceneWar, action.playerAccount, 81, MESSAGE_PARAM_OUT_OF_SYNC)
    end

    local revealedTiles, revealedUnits = getRevealedTilesAndUnitsData(modelSceneWar, translatedPath.pathNodes, focusModelUnit, false)
    if (translatedPath.isBlocked) then
        local actionWait = createActionWait(action.warID, action.actionID, translatedPath, launchUnitID, revealedTiles, revealedUnits)
        return actionWait, createActionsForPublish(actionWait, modelSceneWar), createActionForServer(actionWait)
    else
        local actionLaunchSilo = {
            actionCode       = ACTION_CODES.ActionLaunchSilo,
            actionID         = action.actionID,
            warID            = action.warID,
            path             = translatedPath,
            targetGridIndex  = targetGridIndex,
            launchUnitID     = launchUnitID,
            revealedTiles    = revealedTiles,
            revealedUnits    = revealedUnits,
        }
        return actionLaunchSilo, createActionsForPublish(actionLaunchSilo, modelSceneWar), createActionForServer(actionLaunchSilo)
    end
end

local function translateLoadModelUnit(action)
    local modelSceneWar, actionOnError = getModelSceneWarWithAction(action)
    if (not modelSceneWar) then
        return actionOnError
    end

    local rawPath, launchUnitID        = action.path, action.launchUnitID
    local translatedPath, translateMsg = translatePath(rawPath, launchUnitID, modelSceneWar)
    if (not translatedPath) then
        return createActionReloadSceneWar(modelSceneWar, action.playerAccount, 81, MESSAGE_PARAM_OUT_OF_SYNC)
    end

    local modelUnitMap    = getModelUnitMap(modelSceneWar)
    local rawPathNodes    = rawPath.pathNodes
    local focusModelUnit  = modelUnitMap:getFocusModelUnit(rawPathNodes[1], launchUnitID)
    local destination     = rawPathNodes[#rawPathNodes]
    local loaderModelUnit = modelUnitMap:getModelUnit(destination)
    local tileType        = getModelTileMap(modelSceneWar):getModelTile(destination):getTileType()
    if ((#rawPathNodes == 1)                                                                                                            or
        (not loaderModelUnit)                                                                                                           or
        (not loaderModelUnit.canLoadModelUnit)                                                                                          or
        (not loaderModelUnit:canLoadModelUnit(focusModelUnit, getModelTileMap(modelSceneWar):getModelTile(destination):getTileType()))) then
        return createActionReloadSceneWar(modelSceneWar, action.playerAccount, 81, MESSAGE_PARAM_OUT_OF_SYNC)
    end

    local revealedTiles, revealedUnits = getRevealedTilesAndUnitsData(modelSceneWar, translatedPath.pathNodes, focusModelUnit, false)
    if (translatedPath.isBlocked) then
        local actionWait = createActionWait(action.warID, action.actionID, translatedPath, launchUnitID, revealedTiles, revealedUnits)
        return actionWait, createActionsForPublish(actionWait, modelSceneWar), createActionForServer(actionWait)
    else
        local actionLoadModelUnit = {
            actionCode       = ACTION_CODES.ActionLoadModelUnit,
            actionID         = action.actionID,
            warID            = action.warID,
            path             = translatedPath,
            launchUnitID     = launchUnitID,
            revealedTiles    = revealedTiles,
            revealedUnits    = revealedUnits,
        }
        return actionLoadModelUnit, createActionsForPublish(actionLoadModelUnit, modelSceneWar), createActionForServer(actionLoadModelUnit)
    end
end

local function translateProduceModelUnitOnTile(action)
    local modelSceneWar, actionOnError = getModelSceneWarWithAction(action)
    if (not modelSceneWar) then
        return actionOnError
    end

    local modelTurnManager = getModelTurnManager(modelSceneWar)
    local modelWarField    = modelSceneWar:getModelWarField()
    local modelTileMap     = getModelTileMap(modelSceneWar)
    local gridIndex        = action.gridIndex
    if ((not modelTurnManager:isTurnPhaseMain())                                    or
        (not GridIndexFunctions.isWithinMap(gridIndex, modelTileMap:getMapSize()))) then
        return createActionReloadSceneWar(modelSceneWar, action.playerAccount, 81, MESSAGE_PARAM_OUT_OF_SYNC)
    end

    local tiledID            = action.tiledID
    local playerIndex        = modelTurnManager:getPlayerIndex()
    local modelPlayerManager = getModelPlayerManager(modelSceneWar)
    local modelTile          = modelTileMap:getModelTile(gridIndex)
    local cost               = Producible.getProductionCostWithTiledId(tiledID, modelPlayerManager)
    if ((not cost)                                                        or
        (cost > modelPlayerManager:getModelPlayer(playerIndex):getFund()) or
        (modelTile:getPlayerIndex() ~= playerIndex)                       or
        (getModelUnitMap(modelSceneWar):getModelUnit(gridIndex))          or
        (not modelTile.canProduceUnitWithTiledId)                         or
        (not modelTile:canProduceUnitWithTiledId(tiledID)))               then
        return createActionReloadSceneWar(modelSceneWar, action.playerAccount, 81, MESSAGE_PARAM_OUT_OF_SYNC)
    end

    local focusModelUnit   = Actor.createModel("warOnline.ModelUnit", {
        tiledID       = tiledID,
        unitID        = 0,
        GridIndexable = gridIndex,
    })
    focusModelUnit:onStartRunning(modelSceneWar)

    local revealedTiles, revealedUnits = getRevealedTilesAndUnitsData(modelSceneWar, {gridIndex}, focusModelUnit)
    local actionProduceModelUnitOnTile = {
        actionCode       = ACTION_CODES.ActionProduceModelUnitOnTile,
        actionID         = action.actionID,
        warID            = action.warID,
        gridIndex        = gridIndex,
        tiledID          = tiledID,
        cost             = cost, -- the cost can be calculated by the clients, but that calculations can be eliminated by sending the cost to clients.
        revealedTiles    = revealedTiles,
        revealedUnits    = revealedUnits,
    }
    return actionProduceModelUnitOnTile, createActionsForPublish(actionProduceModelUnitOnTile, modelSceneWar), createActionForServer(actionProduceModelUnitOnTile)
end

local function translateProduceModelUnitOnUnit(action)
    local modelSceneWar, actionOnError = getModelSceneWarWithAction(action)
    if (not modelSceneWar) then
        return actionOnError
    end

    local rawPath, launchUnitID        = action.path, action.launchUnitID
    local translatedPath, translateMsg = translatePath(rawPath, launchUnitID, modelSceneWar)
    if ((not translatedPath) or (isPathDestinationOccupiedByVisibleUnit(modelSceneWar, rawPath))) then
        return createActionReloadSceneWar(modelSceneWar, action.playerAccount, 81, MESSAGE_PARAM_OUT_OF_SYNC)
    end

    local rawPathNodes   = rawPath.pathNodes
    local focusModelUnit = getModelUnitMap(modelSceneWar):getFocusModelUnit(rawPathNodes[1], launchUnitID)
    local cost           = (focusModelUnit.getMovableProductionCost) and (focusModelUnit:getMovableProductionCost()) or (nil)
    if ((launchUnitID)                                                                                                                or
        (#rawPathNodes ~= 1)                                                                                                          or
        (not focusModelUnit.getCurrentMaterial)                                                                                       or
        (focusModelUnit:getCurrentMaterial() < 1)                                                                                     or
        (not cost)                                                                                                                    or
        (cost > getModelPlayerManager(modelSceneWar):getModelPlayer(getModelTurnManager(modelSceneWar):getPlayerIndex()):getFund()) or
        (not focusModelUnit.getCurrentLoadCount)                                                                                      or
        (focusModelUnit:getCurrentLoadCount() >= focusModelUnit:getMaxLoadCount()))                                                   then
        return createActionReloadSceneWar(modelSceneWar, action.playerAccount, 81, MESSAGE_PARAM_OUT_OF_SYNC)
    end

    local revealedTiles, revealedUnits = getRevealedTilesAndUnitsData(modelSceneWar, translatedPath.pathNodes, focusModelUnit, false)
    local actionProduceModelUnitOnUnit = {
        actionCode       = ACTION_CODES.ActionProduceModelUnitOnUnit,
        actionID         = action.actionID,
        warID            = action.warID,
        path             = translatedPath,
        cost             = cost,
        revealedTiles    = revealedTiles,
        revealedUnits    = revealedUnits,
    }
    return actionProduceModelUnitOnUnit, createActionsForPublish(actionProduceModelUnitOnUnit, modelSceneWar), createActionForServer(actionProduceModelUnitOnUnit)
end

local function translateSupplyModelUnit(action)
    local modelSceneWar, actionOnError = getModelSceneWarWithAction(action)
    if (not modelSceneWar) then
        return actionOnError
    end

    local rawPath, launchUnitID        = action.path, action.launchUnitID
    local translatedPath, translateMsg = translatePath(rawPath, launchUnitID, modelSceneWar)
    if ((not translatedPath) or (isPathDestinationOccupiedByVisibleUnit(modelSceneWar, rawPath))) then
        return createActionReloadSceneWar(modelSceneWar, action.playerAccount, 81, MESSAGE_PARAM_OUT_OF_SYNC)
    end

    local rawPathNodes   = rawPath.pathNodes
    local modelUnitMap   = getModelUnitMap(modelSceneWar)
    local focusModelUnit = modelUnitMap:getFocusModelUnit(rawPathNodes[1], launchUnitID)
    if (not canDoActionSupplyModelUnit(focusModelUnit, rawPathNodes[#rawPathNodes], modelUnitMap)) then
        return createActionReloadSceneWar(modelSceneWar, action.playerAccount, 81, MESSAGE_PARAM_OUT_OF_SYNC)
    end

    local revealedTiles, revealedUnits = getRevealedTilesAndUnitsData(modelSceneWar, translatedPath.pathNodes, focusModelUnit, false)
    if (translatedPath.isBlocked) then
        local actionWait = createActionWait(action.warID, action.actionID, translatedPath, launchUnitID, revealedTiles, revealedUnits)
        return actionWait, createActionsForPublish(actionWait, modelSceneWar), createActionForServer(actionWait)
    else
        local actionSupplyModelUnit = {
            actionCode       = ACTION_CODES.ActionSupplyModelUnit,
            actionID         = action.actionID,
            warID            = action.warID,
            path             = translatedPath,
            launchUnitID     = launchUnitID,
            revealedTiles    = revealedTiles,
            revealedUnits    = revealedUnits,
        }
        return actionSupplyModelUnit, createActionsForPublish(actionSupplyModelUnit, modelSceneWar), createActionForServer(actionSupplyModelUnit)
    end
end

local function translateSurface(action)
    local modelSceneWar, actionOnError = getModelSceneWarWithAction(action)
    if (not modelSceneWar) then
        return actionOnError
    end

    local rawPath, launchUnitID        = action.path, action.launchUnitID
    local translatedPath, translateMsg = translatePath(rawPath, launchUnitID, modelSceneWar)
    if ((not translatedPath) or (isPathDestinationOccupiedByVisibleUnit(modelSceneWar, rawPath))) then
        return createActionReloadSceneWar(modelSceneWar, action.playerAccount, 81, MESSAGE_PARAM_OUT_OF_SYNC)
    end

    local focusModelUnit = getModelUnitMap(modelSceneWar):getFocusModelUnit(rawPath.pathNodes[1], launchUnitID)
    if ((not focusModelUnit.canSurface) or (not focusModelUnit:canSurface())) then
        return createActionReloadSceneWar(modelSceneWar, action.playerAccount, 81, MESSAGE_PARAM_OUT_OF_SYNC)
    end

    local revealedTiles, revealedUnits = getRevealedTilesAndUnitsData(modelSceneWar, translatedPath.pathNodes, focusModelUnit, false)
    if (translatedPath.isBlocked) then
        local actionWait = createActionWait(action.warID, action.actionID, translatedPath, launchUnitID, revealedTiles, revealedUnits)
        return actionWait, createActionsForPublish(actionWait, modelSceneWar), createActionForServer(actionWait)
    else
        local actionSurface = {
            actionCode       = ACTION_CODES.ActionSurface,
            actionID         = action.actionID,
            warID            = action.warID,
            path             = translatedPath,
            launchUnitID     = launchUnitID,
            revealedTiles    = revealedTiles,
            revealedUnits    = revealedUnits,
        }
        return actionSurface, createActionsForPublish(actionSurface, modelSceneWar), createActionForServer(actionSurface)
    end
end

local function translateSurrender(action)
    local modelSceneWar, actionOnError = getModelSceneWarWithAction(action)
    if (not modelSceneWar) then
        return actionOnError
    elseif (not getModelTurnManager(modelSceneWar):isTurnPhaseMain()) then
        return createActionReloadSceneWar(modelSceneWar, action.playerAccount, 81, MESSAGE_PARAM_OUT_OF_SYNC)
    end

    local actionSurrender = {
        actionCode       = ACTION_CODES.ActionSurrender,
        actionID         = action.actionID,
        warID            = action.warID,
    }
    return actionSurrender, createActionsForPublish(actionSurrender, modelSceneWar), createActionForServer(actionSurrender)
end

local function translateVoteForDraw(action)
    local modelSceneWar, actionOnError = getModelSceneWarWithAction(action)
    if (not modelSceneWar) then
        return actionOnError
    end

    if ((not getModelTurnManager(modelSceneWar):isTurnPhaseMain())                                               or
        (getModelPlayerManager(modelSceneWar):getModelPlayerWithAccount(action.playerAccount):hasVotedForDraw()) or
        ((not modelSceneWar:getRemainingVotesForDraw()) and (not action.doesAgree)))                              then
        return createActionReloadSceneWar(modelSceneWar, action.playerAccount, 81, MESSAGE_PARAM_OUT_OF_SYNC)
    end

    local actionVoteForDraw = {
        actionCode       = ACTION_CODES.ActionVoteForDraw,
        actionID         = action.actionID,
        warID            = action.warID,
        doesAgree        = action.doesAgree,
    }
    return actionVoteForDraw, createActionsForPublish(actionVoteForDraw, modelSceneWar), createActionForServer(actionVoteForDraw)
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

    local focusModelUnit               = getModelUnitMap(modelSceneWar):getFocusModelUnit(translatedPath.pathNodes[1], launchUnitID)
    local revealedTiles, revealedUnits = getRevealedTilesAndUnitsData(modelSceneWar, translatedPath.pathNodes, focusModelUnit, false)
    local actionWait = {
        actionCode       = ACTION_CODES.ActionWait,
        actionID         = action.actionID,
        warID            = action.warID,
        path             = translatedPath,
        launchUnitID     = launchUnitID,
        revealedTiles    = revealedTiles,
        revealedUnits    = revealedUnits,
    }
    return actionWait, createActionsForPublish(actionWait, modelSceneWar), createActionForServer(actionWait)
end

--------------------------------------------------------------------------------
-- The public functions.
--------------------------------------------------------------------------------
function ActionTranslator.translate(action)
    local actionCode = action.actionCode
    assert(ActionCodeFunctions.getActionName(actionCode), "ActionTranslator.translate() invalid actionCode: " .. (actionCode or ""))

    if     (actionCode == ACTION_CODES.ActionChat)                         then return translateChat(                        action)
    elseif (actionCode == ACTION_CODES.ActionDownloadReplayData)           then return translateDownloadReplayData(          action)
    elseif (actionCode == ACTION_CODES.ActionExitWar)                      then return translateExitWar(                     action)
    elseif (actionCode == ACTION_CODES.ActionGetJoinableWarConfigurations) then return translateGetJoinableWarConfigurations(action)
    elseif (actionCode == ACTION_CODES.ActionGetOngoingWarConfigurations)  then return translateGetOngoingWarConfigurations( action)
    elseif (actionCode == ACTION_CODES.ActionGetPlayerProfile)             then return translateGetPlayerProfile(            action)
    elseif (actionCode == ACTION_CODES.ActionGetRankingList)               then return translateGetRankingList(              action)
    elseif (actionCode == ACTION_CODES.ActionGetReplayConfigurations)      then return translateGetReplayConfigurations(     action)
    elseif (actionCode == ACTION_CODES.ActionGetWaitingWarConfigurations)  then return translateGetWaitingWarConfigurations( action)
    elseif (actionCode == ACTION_CODES.ActionJoinWar)                      then return translateJoinWar(                     action)
    elseif (actionCode == ACTION_CODES.ActionLogin)                        then return translateLogin(                       action)
    elseif (actionCode == ACTION_CODES.ActionNetworkHeartbeat)             then return translateNetworkHeartbeat(            action)
    elseif (actionCode == ACTION_CODES.ActionNewWar)                       then return translateNewWar(                      action)
    elseif (actionCode == ACTION_CODES.ActionRegister)                     then return translateRegister(                    action)
    elseif (actionCode == ACTION_CODES.ActionReloadSceneWar)               then return translateReloadSceneWar(              action)
    elseif (actionCode == ACTION_CODES.ActionRunSceneWar)                  then return translateRunSceneWar(                 action)
    elseif (actionCode == ACTION_CODES.ActionSyncSceneWar)                 then return translateSyncSceneWar(                action)
    elseif (actionCode == ACTION_CODES.ActionActivateSkill)                then return translateActivateSkill(               action)
    elseif (actionCode == ACTION_CODES.ActionAttack)                       then return translateAttack(                      action)
    elseif (actionCode == ACTION_CODES.ActionBeginTurn)                    then return translateBeginTurn(                   action)
    elseif (actionCode == ACTION_CODES.ActionBuildModelTile)               then return translateBuildModelTile(              action)
    elseif (actionCode == ACTION_CODES.ActionCaptureModelTile)             then return translateCaptureModelTile(            action)
    elseif (actionCode == ACTION_CODES.ActionDeclareSkill)                 then return translateDeclareSkill(                action)
    elseif (actionCode == ACTION_CODES.ActionDestroyOwnedModelUnit)        then return translateDestroyOwnedModelUnit(       action)
    elseif (actionCode == ACTION_CODES.ActionDive)                         then return translateDive(                        action)
    elseif (actionCode == ACTION_CODES.ActionDropModelUnit)                then return translateDropModelUnit(               action)
    elseif (actionCode == ACTION_CODES.ActionEndTurn)                      then return translateEndTurn(                     action)
    elseif (actionCode == ACTION_CODES.ActionJoinModelUnit)                then return translateJoinModelUnit(               action)
    elseif (actionCode == ACTION_CODES.ActionLaunchFlare)                  then return translateLaunchFlare(                 action)
    elseif (actionCode == ACTION_CODES.ActionLaunchSilo)                   then return translateLaunchSilo(                  action)
    elseif (actionCode == ACTION_CODES.ActionLoadModelUnit)                then return translateLoadModelUnit(               action)
    elseif (actionCode == ACTION_CODES.ActionProduceModelUnitOnTile)       then return translateProduceModelUnitOnTile(      action)
    elseif (actionCode == ACTION_CODES.ActionProduceModelUnitOnUnit)       then return translateProduceModelUnitOnUnit(      action)
    elseif (actionCode == ACTION_CODES.ActionSurface)                      then return translateSurface(                     action)
    elseif (actionCode == ACTION_CODES.ActionSurrender)                    then return translateSurrender(                   action)
    elseif (actionCode == ACTION_CODES.ActionSupplyModelUnit)              then return translateSupplyModelUnit(             action)
    elseif (actionCode == ACTION_CODES.ActionVoteForDraw)                  then return translateVoteForDraw(                 action)
    elseif (actionCode == ACTION_CODES.ActionWait)                         then return translateWait(                        action)
    else                                                                        error("ActionTranslator.translate() invalid actionCode: " .. (actionCode or ""))
    end
end

return ActionTranslator
