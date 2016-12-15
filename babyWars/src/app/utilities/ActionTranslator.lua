
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
local ActionPublisher         = require("src.app.utilities.ActionPublisher")
local DamageCalculator        = require("src.app.utilities.DamageCalculator")
local GameConstantFunctions   = require("src.app.utilities.GameConstantFunctions")
local GridIndexFunctions      = require("src.app.utilities.GridIndexFunctions")
local LocalizationFunctions   = require("src.app.utilities.LocalizationFunctions")
local PlayerProfileManager    = require("src.app.utilities.PlayerProfileManager")
local SceneWarManager         = require("src.app.utilities.SceneWarManager")
local SerializationFunctions  = require("src.app.utilities.SerializationFunctions")
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

local ACTION_CODES                   = require("src.app.utilities.ActionCodeFunctions").getFullList()
local GAME_VERSION                   = GameConstantFunctions.getGameVersion()
local IGNORED_ACTION_KEYS_FOR_SERVER = {"revealedTiles", "revealedUnits"}

--------------------------------------------------------------------------------
-- The util functions.
--------------------------------------------------------------------------------
local function isGridInPath(gridIndex, path)
    for _, node in ipairs(path) do
        if (GridIndexFunctions.isEqual(gridIndex, node)) then
            return true
        end
    end

    return false
end

local function isModelUnitDiving(modelUnit)
    return (modelUnit.isDiving) and (modelUnit:isDiving())
end

local function isPathDestinationOccupiedByVisibleUnit(sceneWarFileName, path, playerIndex)
    local pathLength = #path
    if (pathLength <= 1) then
        return false
    end

    local destination = path[pathLength]
    local modelUnit   = getModelUnitMap(sceneWarFileName):getModelUnit(destination)
    return (modelUnit) and
        (isUnitVisible(sceneWarFileName, destination, modelUnit:getUnitType(), isModelUnitDiving(modelUnit), modelUnit:getPlayerIndex(), playerIndex))
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

local function getIncome(sceneWarFileName)
    local playerIndex = getModelTurnManager(sceneWarFileName):getPlayerIndex()
    local income      = 0
    getModelTileMap(sceneWarFileName):forEachModelTile(function(modelTile)
        if ((modelTile.getIncomeAmount) and (modelTile:getPlayerIndex() == playerIndex)) then
            income = income + (modelTile:getIncomeAmount() or 0)
        end
    end)

    return income
end

local function getRepairableModelUnits(sceneWarFileName)
    local playerIndex  = getModelTurnManager(sceneWarFileName):getPlayerIndex()
    local modelUnitMap = getModelUnitMap(sceneWarFileName)
    local modelTileMap = getModelTileMap(sceneWarFileName)
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

local function generateRepairData(sceneWarFileName, income)
    local modelUnitMap              = getModelUnitMap(sceneWarFileName)
    local modelPlayer               = getModelPlayerManager(sceneWarFileName):getModelPlayer(getModelTurnManager(sceneWarFileName):getPlayerIndex())
    local skillConfiguration        = modelPlayer:getModelSkillConfiguration()
    local fund                      = modelPlayer:getFund() + income
    local maxNormalizedRepairAmount = GameConstantFunctions.getBaseNormalizedRepairAmount() + SkillModifierFunctions.getRepairAmountModifier(skillConfiguration)
    local costModifier              = SkillModifierFunctions.getRepairCostModifier(skillConfiguration)
    if (costModifier >= 0) then
        costModifier = (100 + costModifier) / 100
    else
        costModifier = 100 / (100 - costModifier)
    end

    local onMapData  = {}
    local loadedData = {}
    for _, modelUnit in ipairs(getRepairableModelUnits(sceneWarFileName)) do
        local repairAmount, repairCost = getRepairAmountAndCost(modelUnit, fund, maxNormalizedRepairAmount, costModifier)
        local unitID                   = modelUnit:getUnitId()
        if (modelUnitMap:getLoadedModelUnitWithUnitId(unitID)) then
            loadedData[unitID] = {repairAmount = repairAmount}
        else
            onMapData[unitID] = {
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

local function areAllUnitsOutOfFuelAndDestroyed(sceneWarFileName)
    local playerIndex   = getModelTurnManager(sceneWarFileName):getPlayerIndex()
    local modelTileMap  = getModelTileMap(sceneWarFileName)
    local modelUnitMap  = getModelUnitMap(sceneWarFileName)
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
    local data = SceneWarManager.getOngoingSceneWarData(sceneWarFileName, playerAccount)
    if (data) then
        return {
            actionName = "ReloadSceneWar",
            fileName   = sceneWarFileName,
            data       = data,
            message    = message,
        }
    else
        return {
            actionName = "RunSceneMain",
            fileName   = sceneWarFileName,
            message    = getLocalizedText(81, "InvalidWarFileName"),
        }
    end
end

local function createActionForServer(action)
    return TableFunctions.clone(action, IGNORED_ACTION_KEYS_FOR_SERVER)
end

--------------------------------------------------------------------------------
-- The translate functions.
--------------------------------------------------------------------------------
local function translateNetworkHeartbeat(action)
    return {
        actionCode       = ACTION_CODES.NetworkHeartbeat,
        heartbeatCounter = action.heartbeatCounter,
    }
end

local function translateLogin(action)
    local account, password = action.playerAccount, action.playerPassword
    if (action.version ~= GAME_VERSION) then
        return {
            actionName = "Message",
            message    = getLocalizedText(81, "InvalidGameVersion", GAME_VERSION)
        }
    elseif (not PlayerProfileManager.isAccountAndPasswordValid(account, password)) then
        return {
            actionName = "Message",
            message    = getLocalizedText(22),
        }
    else
        return {
            actionName = "Login",
            account    = account,
            password   = password,
        }, {
            [account] = {
                actionName = "Logout",
                message    = getLocalizedText(23, account),
            }
        }
    end
end

local function translateRegister(action)
    local account, password = action.playerAccount, action.playerPassword
    if (action.version ~= GAME_VERSION) then
        return {
            actionName = "Message",
            message    = getLocalizedText(81, "InvalidGameVersion", GAME_VERSION)
        }
    elseif (PlayerProfileManager.isAccountRegistered(account)) then
        return {
            actionName = "Message",
            message    = getLocalizedText(25),
        }
    else
        PlayerProfileManager.createPlayerProfile(account, password)
        return {
            actionName = "Register",
            account    = account,
            password   = password,
        }
    end
end

local function translateDownloadReplayData(action)
    local sceneWarFileName = action.sceneWarFileName
    local data             = SceneWarManager.getReplayData(sceneWarFileName)
    if (data) then
        return {
            actionName       = "DownloadReplayData",
            sceneWarFileName = sceneWarFileName,
            data             = data,
        }
    else
        return {
            actionName = "Message",
            message    = getLocalizedText(10, "ReplayDataNotExists")
        }
    end
end

local function translateGetReplayList(action)
    return {
        actionName = "GetReplayList",
        list       = SceneWarManager.getReplayList(action.pageIndex),
    }
end

local function translateNewWar(action)
    -- TODO: validate more params.
    local skillConfigurationID = action.skillConfigurationID
    local maxSkillPoints       = action.maxSkillPoints
    if ((type(skillConfigurationID) == "number") and (skillConfigurationID > 0)) then
        local skillConfiguration = PlayerProfileManager.getSkillConfiguration(action.playerAccount, skillConfigurationID)
        if (not skillConfiguration) then
            return {
                actionName = "Message",
                message    = getLocalizedText(81, "FailToGetSkillConfiguration"),
            }
        end

        local modelSkillConfiguration = ModelSkillConfiguration:create(skillConfiguration)
        local isValid, err            = modelSkillConfiguration:isValid()
        if (not isValid) then
            return {
                actionName = "Message",
                message    = getLocalizedText(81, "InvalidSkillConfiguration", err)
            }
        elseif ((not maxSkillPoints) or (modelSkillConfiguration:getBaseSkillPoints() > maxSkillPoints)) then
            return {
                actionName = "Message",
                message    = getLocalizedText(81, "OverloadedSkillPoints"),
            }
        end
    elseif (type(skillConfigurationID) == "string") then
        if (not GameConstantFunctions.getSkillPresets()[skillConfigurationID]) then
            return {
                actionName = "Message",
                message    = getLocalizedText(81, "InvalidSkillConfiguration", err)
            }
        elseif ((not maxSkillPoints) or (maxSkillPoints < 100)) then
            return {
                actionName = "Message",
                message    = getLocalizedText(81, "OverloadedSkillPoints"),
            }
        end
    end

    local sceneWarFileName, err = SceneWarManager.createNewWar(action)
    if (not sceneWarFileName) then
        return {
            actionName = "Message",
            message    = getLocalizedText(50, err)
        }
    else
        return {
            actionName = "NewWar",
            message    = getLocalizedText(51, sceneWarFileName:sub(13))
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

local function translateGetSceneWarActionId(action)
    local sceneWarFileName = action.fileName
    local data, err        = SceneWarManager.getOngoingSceneWarData(sceneWarFileName, action.playerAccount)
    return {
        actionName       = "GetSceneWarActionId",
        fileName         = sceneWarFileName,
        sceneWarActionID = (data) and (data.actionID) or (nil),
    }
end

local function translateGetSceneWarData(action)
    local data, err = SceneWarManager.getOngoingSceneWarData(action.fileName, action.playerAccount)
    if (not data) then
        return {
            actionName = "Message",
            message    = getLocalizedText(52)
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
            message    = getLocalizedText(53, err)
        }
    else
        return {
            actionName = "GetJoinableWarList",
            list       = list,
        }
    end
end

local function translateJoinWar(action)
    local warConfiguration, err = SceneWarManager.getJoinableSceneWarConfiguration(action.sceneWarFileName)
    if (not warConfiguration) then
        return {
            actionName = "Message",
            message    = getLocalizedText(81, "WarNotJoinable", err)
        }
    end

    local skillConfigurationID = action.skillConfigurationID
    local maxSkillPoints       = warConfiguration.maxSkillPoints
    if ((type(skillConfigurationID) == "number") and (skillConfigurationID > 0)) then
        local skillConfiguration = PlayerProfileManager.getSkillConfiguration(action.playerAccount, skillConfigurationID)
        if (not skillConfiguration) then
            return {
                actionName = "Message",
                message    = getLocalizedText(81, "FailToGetSkillConfiguration"),
            }
        end

        local modelSkillConfiguration = ModelSkillConfiguration:create(skillConfiguration)
        local isValid, err            = modelSkillConfiguration:isValid()
        if (not isValid) then
            return {
                actionName = "Message",
                message    = getLocalizedText(81, "InvalidSkillConfiguration", err)
            }
        elseif ((not maxSkillPoints) or (modelSkillConfiguration:getBaseSkillPoints() > maxSkillPoints)) then
            return {
                actionName = "Message",
                message    = getLocalizedText(81, "OverloadedSkillPoints"),
            }
        end
    elseif (type(skillConfigurationID) == "string") then
        if (not GameConstantFunctions.getSkillPresets()[skillConfigurationID]) then
            return {
                actionName = "Message",
                message    = getLocalizedText(81, "InvalidSkillConfiguration", err)
            }
        elseif ((not maxSkillPoints) or (maxSkillPoints < 100)) then
            return {
                actionName = "Message",
                message    = getLocalizedText(81, "OverloadedSkillPoints"),
            }
        end
    end

    local msg, err = SceneWarManager.joinWar(action)
    if (not msg) then
        return {
            actionName = "Message",
            message    = getLocalizedText(54, err),
        }
    else
        return {
            actionName = "JoinWar",
            message    = msg,
        }
    end
end

local function translateGetSkillConfiguration(action)
    local configurationID    = action.configurationID
    local configuration, err = PlayerProfileManager.getSkillConfiguration(action.playerAccount, configurationID)
    if (not configuration) then
        return {
            actionName = "Message",
            message    = getLocalizedText(81, "FailToGetSkillConfiguration", err),
        }
    else
        return {
            actionName      = "GetSkillConfiguration",
            configurationID = configurationID,
            configuration   = configuration,
        }
    end
end

local function translateReloadSceneWar(action)
    return createActionReloadOrExitWar(action.fileName, action.playerAccount)
end

local function translateSetSkillConfiguration(action)
    local configuration   = ModelSkillConfiguration:create(action.configuration)
    local configurationID = action.configurationID
    if ((configurationID < 1)                                                   or
        (configurationID > GameConstantFunctions.getSkillConfigurationsCount()) or
        (configurationID ~= math.floor(configurationID))                        or
        (not configuration:isValid()))                                          then
        return {
            actionName = "Message",
            message    = getLocalizedText(81, "InvalidSkillConfiguration"),
        }
    end

    PlayerProfileManager.setSkillConfiguration(action.playerAccount, configurationID, configuration)
    return {
        actionName = "Message",
        message    = getLocalizedText(81, "SucceedToSetSkillConfiguration"),
    }
end

-- This translation ignores the existing unit of the same player at the end of the path, so that the actions of Join/Attack/Wait can reuse this function.
local function translatePath(path, launchUnitID, modelSceneWar)
    local modelWarField      = modelSceneWar:getModelWarField()
    local modelTurnManager   = modelSceneWar:getModelTurnManager()
    local modelUnitMap       = modelWarField:getModelUnitMap()
    local playerIndexInTurn  = modelTurnManager:getPlayerIndex()
    local beginningGridIndex = path[1]
    local mapSize            = modelUnitMap:getMapSize()
    local focusModelUnit     = modelUnitMap:getFocusModelUnit(beginningGridIndex, launchUnitID)
    local isWithinMap        = GridIndexFunctions.isWithinMap

    if (not isWithinMap(beginningGridIndex, mapSize)) then
        return nil, "ActionTranslator-translatePath() a node in the path is not within the map."
    elseif (not focusModelUnit) then
        return nil, "ActionTranslator-translatePath() there is no unit on the starting grid of the path."
    elseif (focusModelUnit:getPlayerIndex() ~= playerIndexInTurn) then
        return nil, "ActionTranslator-translatePath() the owner player of the moving unit is not in his turn."
    elseif (focusModelUnit:getState() ~= "idle") then
        return nil, "ActionTranslator-translatePath() the moving unit is not in idle state."
    end

    local clone                = GridIndexFunctions.clone
    local isAdjacent           = GridIndexFunctions.isAdjacent
    local modelTileMap         = modelWarField:getModelTileMap()
    local translatedPath       = {clone(beginningGridIndex)}
    local totalFuelConsumption = 0
    local maxFuelConsumption   = math.min(focusModelUnit:getCurrentFuel(), focusModelUnit:getMoveRange())
    local sceneWarFileName     = modelSceneWar:getFileName()

    for i = 2, #path do
        local gridIndex = path[i]
        if (not isAdjacent(path[i - 1], gridIndex)) then
            return nil, "ActionTranslator-translatePath() the path is invalid because some grids are not adjacent to previous ones."
        elseif (isGridInPath(gridIndex, translatedPath)) then
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
            translatedPath.fuelConsumption      = totalFuelConsumption
            translatedPath[#translatedPath + 1] = clone(gridIndex)
        end
    end

    return translatedPath
end

local function translateActivateSkillGroup(action, modelScene)
    local skillGroupID     = action.skillGroupID
    local playerAccount    = action.playerAccount
    local modelPlayer      = modelScene:getModelPlayerManager():getModelPlayerWithAccount(playerAccount)
    local sceneWarFileName = modelScene:getFileName()
    if ((modelScene:getModelTurnManager():getTurnPhase() ~= "main") or
        (not modelPlayer:canActivateSkillGroup(skillGroupID)))      then
        return createActionReloadOrExitWar(sceneWarFileName, playerAccount, getLocalizedText(81, "OutOfSync"))
    end

    local revealedTiles, revealedUnits = VisibilityFunctions.getRevealedTilesAndUnitsDataForSkillActivation(sceneWarFileName, skillGroupID)
    local actionActivateSkillGroup = {
        actionName    = "ActivateSkillGroup",
        actionID      = action.actionID,
        fileName      = sceneWarFileName,
        skillGroupID  = skillGroupID,
        revealedTiles = revealedTiles,
        revealedUnits = revealedUnits,
    }
    return actionActivateSkillGroup, createActionsForPublish(actionActivateSkillGroup), createActionForServer(actionActivateSkillGroup)
end

local function translateAttack(action, modelScene)
    local rawPath, launchUnitID        = action.path, action.launchUnitID
    local translatedPath, translateMsg = translatePath(rawPath, launchUnitID, modelScene)
    local sceneWarFileName             = modelScene:getFileName()
    if (not translatedPath) then
        return createActionReloadOrExitWar(sceneWarFileName, action.playerAccount, getLocalizedText(81, "OutOfSync", translateMsg))
    end

    local modelWarField       = modelScene:getModelWarField()
    local modelUnitMap        = modelWarField:getModelUnitMap()
    local modelTileMap        = modelWarField:getModelTileMap()
    local endingGridIndex     = rawPath[#rawPath]
    local attacker            = modelUnitMap:getFocusModelUnit(rawPath[1], launchUnitID)
    local targetGridIndex     = action.targetGridIndex
    local existingModelUnit   = modelUnitMap:getModelUnit(endingGridIndex)
    local targetTile          = modelTileMap:getModelTile(targetGridIndex)
    local attackTarget        = modelUnitMap:getModelUnit(targetGridIndex) or targetTile
    local attackerPlayerIndex = attacker:getPlayerIndex()
    if ((modelScene:getModelTurnManager():getTurnPhase() ~= "main")                                                                                                                                               or
        (not ComponentManager.getComponent(attacker, "AttackDoer"))                                                                                                                                               or
        (not GridIndexFunctions.isWithinMap(targetGridIndex, modelUnitMap:getMapSize()))                                                                                                                          or
        (isPathDestinationOccupiedByVisibleUnit(sceneWarFileName, rawPath, attackerPlayerIndex))                                                                                                                  or
        ((attackTarget.getUnitType) and (not isUnitVisible(sceneWarFileName, targetGridIndex, attackTarget:getUnitType(), isModelUnitDiving(attackTarget), attackTarget:getPlayerIndex(), attackerPlayerIndex)))) then
        return createActionReloadOrExitWar(sceneWarFileName, action.playerAccount, getLocalizedText(81, "OutOfSync"))
    end

    local attackDamage, counterDamage = DamageCalculator.getUltimateBattleDamage(rawPath, launchUnitID, targetGridIndex, modelScene)
    if (not attackDamage) then
        return createActionReloadOrExitWar(sceneWarFileName, action.playerAccount, getLocalizedText(81, "OutOfSync"))
    end

    local revealedTiles, revealedUnits = getRevealedTilesAndUnitsData(sceneWarFileName, translatedPath, attacker, (counterDamage) and (counterDamage >= attacker:getCurrentHP()))
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
        local actionAttack = {
            actionName      = "Attack",
            actionID        = action.actionID,
            fileName        = sceneWarFileName,
            path            = translatedPath,
            launchUnitID    = launchUnitID,
            targetGridIndex = targetGridIndex,
            attackDamage    = attackDamage,
            counterDamage   = counterDamage,
            revealedTiles   = revealedTiles,
            revealedUnits   = revealedUnits,
            lostPlayerIndex = getLostPlayerIndexForActionAttack(attacker, attackTarget, attackDamage, counterDamage),
        }
        return actionAttack, createActionsForPublish(actionAttack), createActionForServer(actionAttack)
    end
end

local function translateBeginTurn(action, modelScene)
    local sceneWarFileName = modelScene:getFileName()
    local modelTurnManager = modelScene:getModelTurnManager()
    if (modelTurnManager:getTurnPhase() ~= "requestToBegin") then
        ngx.log(ngx.ERR, "ActionTranslator-translateBeginTurn() the current turn phase is expected to be 'requestToBegin'.")
        return createActionReloadOrExitWar(sceneWarFileName, action.playerAccount, getLocalizedText(81, "OutOfSync"))
    end

    local income          = getIncome(sceneWarFileName)
    local actionBeginTurn = {
        actionName = "BeginTurn",
        actionID   = action.actionID,
        fileName   = sceneWarFileName,
    }
    if (modelTurnManager:getTurnIndex() == 1) then
        actionBeginTurn.income = income
    else
        actionBeginTurn.lostPlayerIndex = (areAllUnitsOutOfFuelAndDestroyed(sceneWarFileName)) and (playerIndex) or (nil)
        actionBeginTurn.repairData      = generateRepairData(sceneWarFileName, income)
    end
    return actionBeginTurn, createActionsForPublish(actionBeginTurn), createActionForServer(actionBeginTurn)
end

local function translateBuildModelTile(action, modelScene)
    local rawPath, launchUnitID        = action.path, action.launchUnitID
    local translatedPath, translateMsg = translatePath(rawPath, launchUnitID, modelScene)
    local sceneWarFileName             = modelScene:getFileName()
    if (not translatedPath) then
        return createActionReloadOrExitWar(sceneWarFileName, action.playerAccount, getLocalizedText(81, "OutOfSync", translateMsg))
    end

    local endingGridIndex = rawPath[#rawPath]
    local focusModelUnit  = getModelUnitMap(sceneWarFileName):getFocusModelUnit(rawPath[1], launchUnitID)
    local modelTile       = getModelTileMap(sceneWarFileName):getModelTile(endingGridIndex)
    if ((modelScene:getModelTurnManager():getTurnPhase() ~= "main")                                           or
        (not focusModelUnit.canBuildOnTileType)                                                               or
        (not focusModelUnit:canBuildOnTileType(modelTile:getTileType()))                                      or
        (not focusModelUnit.getCurrentMaterial)                                                               or
        (focusModelUnit:getCurrentMaterial() < 1)                                                             or
        (isPathDestinationOccupiedByVisibleUnit(sceneWarFileName, rawPath, focusModelUnit:getPlayerIndex()))) then
        return createActionReloadOrExitWar(sceneWarFileName, action.playerAccount, getLocalizedText(81, "OutOfSync"))
    end

    local revealedTiles, revealedUnits = getRevealedTilesAndUnitsData(sceneWarFileName, translatedPath, focusModelUnit, false)
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
        if (focusModelUnit:getBuildAmount() >= modelTile:getCurrentBuildPoint()) then
            local tiles, units = VisibilityFunctions.getRevealedTilesAndUnitsDataForBuild(sceneWarFileName, endingGridIndex, focusModelUnit)
            revealedTiles = TableFunctions.union(revealedTiles, tiles)
            revealedUnits = TableFunctions.union(revealedUnits, units)
        end
        local actionBuildModelTile = {
            actionName    = "BuildModelTile",
            actionID      = action.actionID,
            fileName      = sceneWarFileName,
            path          = translatedPath,
            launchUnitID  = launchUnitID,
            revealedTiles = revealedTiles,
            revealedUnits = revealedUnits,
        }
        return actionBuildModelTile, createActionsForPublish(actionBuildModelTile), createActionForServer(actionBuildModelTile)
    end
end

local function translateCaptureModelTile(action, modelScene)
    local rawPath, launchUnitID        = action.path, action.launchUnitID
    local translatedPath, translateMsg = translatePath(rawPath, launchUnitID, modelScene)
    local sceneWarFileName             = modelScene:getFileName()
    if (not translatedPath) then
        return createActionReloadOrExitWar(sceneWarFileName, action.playerAccount, getLocalizedText(81, "OutOfSync", translateMsg))
    end

    local endingGridIndex = rawPath[#rawPath]
    local capturer        = getModelUnitMap(sceneWarFileName):getFocusModelUnit(rawPath[1], launchUnitID)
    local captureTarget   = getModelTileMap(sceneWarFileName):getModelTile(endingGridIndex)
    if ((modelScene:getModelTurnManager():getTurnPhase() ~= "main")                                     or
        (not capturer.canCaptureModelTile)                                                              or
        (not capturer:canCaptureModelTile(captureTarget))                                               or
        (isPathDestinationOccupiedByVisibleUnit(sceneWarFileName, rawPath, capturer:getPlayerIndex()))) then
        return createActionReloadOrExitWar(sceneWarFileName, action.playerAccount, getLocalizedText(81, "OutOfSync"))
    end

    local revealedTiles, revealedUnits = getRevealedTilesAndUnitsData(sceneWarFileName, translatedPath, capturer, false)
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
        local isCaptureFinished = capturer:getCaptureAmount() >= captureTarget:getCurrentCapturePoint()
        if (isCaptureFinished) then
            local tiles, units = VisibilityFunctions.getRevealedTilesAndUnitsDataForCapture(sceneWarFileName, endingGridIndex, capturer:getPlayerIndex())
            revealedTiles = TableFunctions.union(revealedTiles, tiles)
            revealedUnits = TableFunctions.union(revealedUnits, units)
        end

        local actionCapture = {
            actionName      = "CaptureModelTile",
            actionID        = action.actionID,
            fileName        = sceneWarFileName,
            path            = translatedPath,
            launchUnitID    = launchUnitID,
            revealedTiles   = revealedTiles,
            revealedUnits   = revealedUnits,
            lostPlayerIndex = ((isCaptureFinished) and (captureTarget:isDefeatOnCapture()))
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
    if ((modelScene:getModelTurnManager():getTurnPhase() ~= "main")                                           or
        (not focusModelUnit.canDive)                                                                          or
        (not focusModelUnit:canDive())                                                                        or
        (isPathDestinationOccupiedByVisibleUnit(sceneWarFileName, rawPath, focusModelUnit:getPlayerIndex()))) then
        return createActionReloadOrExitWar(sceneWarFileName, action.playerAccount, getLocalizedText(81, "OutOfSync"))
    end

    local revealedTiles, revealedUnits = getRevealedTilesAndUnitsData(sceneWarFileName, translatedPath, focusModelUnit, false)
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
    if ((modelScene:getModelTurnManager():getTurnPhase() ~= "main")                                            or
        (not loaderModelUnit.canDropModelUnit)                                                                 or
        (not loaderModelUnit:canDropModelUnit(tileType))                                                       or
        (not validateDropDestinations(action, modelScene))                                                     or
        (isPathDestinationOccupiedByVisibleUnit(sceneWarFileName, rawPath, loaderModelUnit:getPlayerIndex()))) then
        return createActionReloadOrExitWar(sceneWarFileName, action.playerAccount, getLocalizedText(81, "OutOfSync"))
    end

    local revealedTiles, revealedUnits = getRevealedTilesAndUnitsData(sceneWarFileName, translatedPath, loaderModelUnit, false)
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

local function translateEndTurn(action, modelScene)
    local sceneWarFileName = modelScene:getFileName()
    if (modelScene:getModelTurnManager():getTurnPhase() ~= "main") then
        ngx.log(ngx.ERR, "ActionTranslator-translateEndTurn() the current turn phase is expected to be 'main'.")
        return createActionReloadOrExitWar(sceneWarFileName, action.playerAccount, getLocalizedText(81, "OutOfSync"))
    end

    -- TODO: enable the weather.
    local actionEndTurn = {
        actionName  = "EndTurn",
        actionID    = action.actionID,
        fileName    = sceneWarFileName,
        nextWeather = modelScene:getModelWeatherManager():getNextWeather(),
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
    if ((modelScene:getModelTurnManager():getTurnPhase() ~= "main") or
        (#rawPath == 1)                                             or
        (not existingModelUnit)                                     or
        (not focusModelUnit.canJoinModelUnit)                       or
        (not focusModelUnit:canJoinModelUnit(existingModelUnit)))   then
        return createActionReloadOrExitWar(sceneWarFileName, action.playerAccount, getLocalizedText(81, "OutOfSync"))
    end

    local revealedTiles, revealedUnits = getRevealedTilesAndUnitsData(sceneWarFileName, translatedPath, focusModelUnit, false)
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
    if ((modelScene:getModelTurnManager():getTurnPhase() ~= "main")                                              or
        (#rawPath > 1)                                                                                           or
        (not focusModelUnit.getCurrentFlareAmmo)                                                                 or
        (focusModelUnit:getCurrentFlareAmmo() == 0)                                                              or
        (not getModelFogMap(sceneWarFileName):isFogOfWarCurrently())                                             or
        (not GridIndexFunctions.isWithinMap(targetGridIndex, modelUnitMap:getMapSize())                          or
        (GridIndexFunctions.getDistance(targetGridIndex, rawPath[#rawPath]) > focusModelUnit:getMaxFlareRange()) or
        (isPathDestinationOccupiedByVisibleUnit(sceneWarFileName, rawPath, playerIndex))))                       then
        return createActionReloadOrExitWar(sceneWarFileName, action.playerAccount, getLocalizedText(81, "OutOfSync"))
    end

    local revealedTiles, revealedUnits = getRevealedTilesAndUnitsData(sceneWarFileName, translatedPath, focusModelUnit, false)
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
    if ((modelScene:getModelTurnManager():getTurnPhase() ~= "main")                                            or
        (not focusModelUnit.canLaunchSiloOnTileType)                                                           or
        (not focusModelUnit:canLaunchSiloOnTileType(tileType))                                                 or
        (not GridIndexFunctions.isWithinMap(targetGridIndex, modelUnitMap:getMapSize())                        or
        (isPathDestinationOccupiedByVisibleUnit(sceneWarFileName, rawPath, focusModelUnit:getPlayerIndex())))) then
        return createActionReloadOrExitWar(sceneWarFileName, action.playerAccount, getLocalizedText(81, "OutOfSync"))
    end

    local revealedTiles, revealedUnits = getRevealedTilesAndUnitsData(sceneWarFileName, translatedPath, focusModelUnit, false)
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
    if ((modelScene:getModelTurnManager():getTurnPhase() ~= "main")       or
        (#rawPath == 1)                                                   or
        (not loaderModelUnit)                                             or
        (not loaderModelUnit.canLoadModelUnit)                            or
        (not loaderModelUnit:canLoadModelUnit(focusModelUnit, tileType))) then
        return createActionReloadOrExitWar(sceneWarFileName, action.playerAccount, getLocalizedText(81, "OutOfSync"))
    end

    local revealedTiles, revealedUnits = getRevealedTilesAndUnitsData(sceneWarFileName, translatedPath, focusModelUnit, false)
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

local function translateProduceModelUnitOnTile(action, modelScene)
    local modelPlayerManager    = modelScene:getModelPlayerManager()
    local modelTurnManager      = modelScene:getModelTurnManager()
    local playerIndex           = modelTurnManager:getPlayerIndex()
    local modelWarField         = modelScene:getModelWarField()
    local modelTileMap          = modelWarField:getModelTileMap()
    local gridIndex             = action.gridIndex
    local tiledID               = action.tiledID
    local sceneWarFileName      = modelScene:getFileName()

    if ((modelTurnManager:getTurnPhase() ~= "main")                                 or
        (not GridIndexFunctions.isWithinMap(gridIndex, modelTileMap:getMapSize()))) then
        return createActionReloadOrExitWar(sceneWarFileName, action.playerAccount, getLocalizedText(81, "OutOfSync"))
    end

    local modelTile = modelTileMap:getModelTile(gridIndex)
    local cost      = Producible.getProductionCostWithTiledId(tiledID, modelPlayerManager)
    if ((not cost)                                                        or
        (cost > modelPlayerManager:getModelPlayer(playerIndex):getFund()) or
        (modelTile:getPlayerIndex() ~= playerIndex)                       or
        (modelWarField:getModelUnitMap():getModelUnit(gridIndex))         or
        (not modelTile.canProduceUnitWithTiledId)                         or
        (not modelTile:canProduceUnitWithTiledId(tiledID)))               then
        return createActionReloadOrExitWar(sceneWarFileName, action.playerAccount, getLocalizedText(81, "OutOfSync"))
    end

    local focusModelUnit = Actor.createModel("sceneWar.ModelUnit", {
        tiledID       = tiledID,
        unitID        = 0,
        GridIndexable = {gridIndex = {gridIndex}},
    })
    focusModelUnit:onStartRunning(sceneWarFileName)

    local revealedTiles, revealedUnits = getRevealedTilesAndUnitsData(sceneWarFileName, {gridIndex}, focusModelUnit)
    local actionProduceModelUnitOnTile = {
        actionName    = "ProduceModelUnitOnTile",
        actionID      = action.actionID,
        fileName      = sceneWarFileName,
        gridIndex     = gridIndex,
        tiledID       = tiledID,
        cost          = cost, -- the cost can be calculated by the clients, but that calculations can be eliminated by sending the cost to clients.
        revealedTiles = revealedTiles,
        revealedUnits = revealedUnits,
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
    if ((modelTurnManager:getTurnPhase() ~= "main")                                 or
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

    local revealedTiles, revealedUnits = getRevealedTilesAndUnitsData(sceneWarFileName, translatedPath, focusModelUnit, false)
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
    if ((modelScene:getModelTurnManager():getTurnPhase() ~= "main")                                           or
        (not canDoActionSupplyModelUnit(focusModelUnit, rawPath[#rawPath], modelUnitMap))                     or
        (isPathDestinationOccupiedByVisibleUnit(sceneWarFileName, rawPath, focusModelUnit:getPlayerIndex()))) then
        return createActionReloadOrExitWar(sceneWarFileName, action.playerAccount, getLocalizedText(81, "OutOfSync"))
    end

    local revealedTiles, revealedUnits = getRevealedTilesAndUnitsData(sceneWarFileName, translatedPath, focusModelUnit, false)
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
    if ((modelScene:getModelTurnManager():getTurnPhase() ~= "main")                                           or
        (not focusModelUnit.canSurface)                                                                       or
        (not focusModelUnit:canSurface())                                                                     or
        (isPathDestinationOccupiedByVisibleUnit(sceneWarFileName, rawPath, focusModelUnit:getPlayerIndex()))) then
        return createActionReloadOrExitWar(sceneWarFileName, action.playerAccount, getLocalizedText(81, "OutOfSync"))
    end

    local revealedTiles, revealedUnits = getRevealedTilesAndUnitsData(sceneWarFileName, translatedPath, focusModelUnit, false)
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

local function translateSurrender(action, modelScene)
    local sceneWarFileName = modelScene:getFileName()
    if (modelScene:getModelTurnManager():getTurnPhase() ~= "main") then
        ngx.log(ngx.ERR, "ActionTranslator-translateSurrender() the current turn phase is expected to be 'main'.")
        return createActionReloadOrExitWar(sceneWarFileName, action.playerAccount, getLocalizedText(81, "OutOfSync"))
    end

    local actionSurrender = {
        actionName = "Surrender",
        actionID   = action.actionID,
        fileName   = sceneWarFileName,
    }
    return actionSurrender, createActionsForPublish(actionSurrender), createActionForServer(actionSurrender)
end

local function translateWait(action, modelScene)
    local rawPath, launchUnitID        = action.path, action.launchUnitID
    local translatedPath, translateMsg = translatePath(rawPath, launchUnitID, modelScene)
    local sceneWarFileName             = modelScene:getFileName()
    if (not translatedPath) then
        return createActionReloadOrExitWar(sceneWarFileName, action.playerAccount, getLocalizedText(81, "OutOfSync", translateMsg))
    end

    local focusModelUnit = getModelUnitMap(sceneWarFileName):getFocusModelUnit(translatedPath[1], launchUnitID)
    if ((modelScene:getModelTurnManager():getTurnPhase() ~= "main")                                           or
        (isPathDestinationOccupiedByVisibleUnit(sceneWarFileName, rawPath, focusModelUnit:getPlayerIndex()))) then
        return createActionReloadOrExitWar(sceneWarFileName, action.playerAccount, getLocalizedText(81, "OutOfSync"))
    end

    local revealedTiles, revealedUnits = getRevealedTilesAndUnitsData(sceneWarFileName, translatedPath, focusModelUnit, false)
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
end

--------------------------------------------------------------------------------
-- The public functions.
--------------------------------------------------------------------------------
function ActionTranslator.translate(action)
    local actionCode = action.actionCode
    if (not actionCode) then
        return {
            actionName = "Message",
            message    = getLocalizedText(81, "CorruptedAction"),
        }
    end

    if (actionCode == ACTION_CODES.NetworkHeartbeat) then return translateNetworkHeartbeat(action)
    end

    local actionName = action.actionName
    if     (actionName == "DownloadReplayData") then return translateDownloadReplayData(action)
    elseif (actionName == "GetReplayList")      then return translateGetReplayList(     action)
    elseif (actionName == "Login")              then return translateLogin(             action)
    elseif (actionName == "NetworkHeartbeat")   then return translateNetworkHeartbeat(  action)
    elseif (actionName == "Register")           then return translateRegister(          action)
    end

    local playerAccount = action.playerAccount
    if (not PlayerProfileManager.isAccountAndPasswordValid(playerAccount, action.playerPassword)) then
        return {
            actionName = "Logout",
            message    = getLocalizedText(81, "InvalidPassword"),
        }
    end

    if     (actionName == "NewWar")                then return translateNewWar(               action)
    elseif (actionName == "GetOngoingWarList")     then return translateGetOngoingWarList(    action)
    elseif (actionName == "GetSceneWarActionId")   then return translateGetSceneWarActionId(  action)
    elseif (actionName == "GetSceneWarData")       then return translateGetSceneWarData(      action)
    elseif (actionName == "GetJoinableWarList")    then return translateGetJoinableWarList(   action)
    elseif (actionName == "JoinWar")               then return translateJoinWar(              action)
    elseif (actionName == "GetSkillConfiguration") then return translateGetSkillConfiguration(action)
    elseif (actionName == "ReloadSceneWar")        then return translateReloadSceneWar(       action)
    elseif (actionName == "SetSkillConfiguration") then return translateSetSkillConfiguration(action)
    end

    local sceneWarFileName   = action.sceneWarFileName
    local modelSceneWar, err = SceneWarManager.getOngoingModelSceneWar(sceneWarFileName)
    if ((not modelSceneWar)                                                   or
        (not SceneWarManager.isPlayerInTurn(sceneWarFileName, playerAccount)) or
        (modelSceneWar:getActionId() + 1 ~= action.actionID))                 then
        return createActionReloadOrExitWar(sceneWarFileName, playerAccount, getLocalizedText(81, "OutOfSync"))
    end

    if     (actionName == "ActivateSkillGroup")     then return translateActivateSkillGroup(    action, modelSceneWar)
    elseif (actionName == "Attack")                 then return translateAttack(                action, modelSceneWar)
    elseif (actionName == "BeginTurn")              then return translateBeginTurn(             action, modelSceneWar)
    elseif (actionName == "BuildModelTile")         then return translateBuildModelTile(        action, modelSceneWar)
    elseif (actionName == "CaptureModelTile")       then return translateCaptureModelTile(      action, modelSceneWar)
    elseif (actionName == "Dive")                   then return translateDive(                  action, modelSceneWar)
    elseif (actionName == "DropModelUnit")          then return translateDropModelUnit(         action, modelSceneWar)
    elseif (actionName == "EndTurn")                then return translateEndTurn(               action, modelSceneWar)
    elseif (actionName == "JoinModelUnit")          then return translateJoinModelUnit(         action, modelSceneWar)
    elseif (actionName == "LaunchFlare")            then return translateLaunchFlare(           action, modelSceneWar)
    elseif (actionName == "LaunchSilo")             then return translateLaunchSilo(            action, modelSceneWar)
    elseif (actionName == "LoadModelUnit")          then return translateLoadModelUnit(         action, modelSceneWar)
    elseif (actionName == "ProduceModelUnitOnTile") then return translateProduceModelUnitOnTile(action, modelSceneWar)
    elseif (actionName == "ProduceModelUnitOnUnit") then return translateProduceModelUnitOnUnit(action, modelSceneWar)
    elseif (actionName == "SupplyModelUnit")        then return translateSupplyModelUnit(       action, modelSceneWar)
    elseif (actionName == "Surface")                then return translateSurface(               action, modelSceneWar)
    elseif (actionName == "Surrender")              then return translateSurrender(             action, modelSceneWar)
    elseif (actionName == "Wait")                   then return translateWait(                  action, modelSceneWar)
    else    return createActionReloadOrExitWar(sceneWarFileName, playerAccount, getLocalizedText(81, "OutOfSync", actionName))
    end
end

return ActionTranslator
