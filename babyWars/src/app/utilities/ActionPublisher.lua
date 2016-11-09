
local ActionPublisher = {}

local GameConstantFunctions = require("src.app.utilities.GameConstantFunctions")
local GridIndexFunctions    = require("src.app.utilities.GridIndexFunctions")
local SingletonGetters      = require("src.app.utilities.SingletonGetters")
local TableFunctions        = require("src.app.utilities.TableFunctions")
local VisibilityFunctions   = require("src.app.utilities.VisibilityFunctions")

local getAdjacentGrids          = GridIndexFunctions.getAdjacentGrids
local getModelPlayerManager     = SingletonGetters.getModelPlayerManager
local getModelTileMap           = SingletonGetters.getModelTileMap
local getModelTurnManager       = SingletonGetters.getModelTurnManager
local getModelUnitMap           = SingletonGetters.getModelUnitMap
local getPlayerIndexWithTiledId = GameConstantFunctions.getPlayerIndexWithTiledId
local getUnitTypeWithTiledId    = GameConstantFunctions.getUnitTypeWithTiledId
local isUnitVisible             = VisibilityFunctions.isUnitOnMapVisibleToPlayerIndex

local IGNORED_KEYS_IN_PUBLISHING = {"revealedTiles", "revealedUnits"}

--------------------------------------------------------------------------------
-- The util functions.
--------------------------------------------------------------------------------
local function isModelUnitDiving(modelUnit)
    return (modelUnit.isDiving) and (modelUnit:isDiving())
end

local function generateSingleUnitDataForPublish(modelUnitMap, modelUnit)
    local data    = modelUnit:toSerializableTable()
    data.isLoaded = modelUnitMap:getLoadedModelUnitWithUnitId(modelUnit:getUnitId()) ~= nil

    return data
end

local function generateUnitsDataForPublish(sceneWarFileName, modelUnit)
    local modelUnitMap = getModelUnitMap(sceneWarFileName)
    local data         = {[modelUnit:getUnitId()] = generateSingleUnitDataForPublish(modelUnitMap, modelUnit)}
    for _, loadedModelUnit in pairs(modelUnitMap:getLoadedModelUnitsWithLoader(modelUnit, true) or {}) do
        data[loadedModelUnit:getUnitId()] = generateSingleUnitDataForPublish(modelUnitMap, loadedModelUnit)
    end

    return data
end

--------------------------------------------------------------------------------
-- The private functions that create actions for publish.
--------------------------------------------------------------------------------
local creators = {}
creators.createActionForActivateSkillGroup = function(action, targetPlayerIndex)
    return TableFunctions.clone(action, {"revealedUnits"})
end

creators.createActionForAttack = function(action, targetPlayerIndex)
    -- 为简单起见，目前的代码实现会把移动路线，包括合流的两个部队的数据完整广播到目标客户端（不管对目标玩家是否可见）。客户端自行判断在移动过程中是否隐藏该部队。
    -- 这种实现存在被破解作弊的可能。完美防作弊的实现需要对移动路线以及单位的数据也做出适当的删除，同时需要计算相关结果数据一并传送（如合流收入）。
    -- 行动玩家在移动后，可能会发现隐藏的敌方部队revealedUnits。这对于目标玩家不可见，因此广播的action须删除这些数据。

    local sceneWarFileName   = action.fileName
    local beginningGridIndex = action.path[1]
    local targetGridIndex    = action.targetGridIndex
    local modelUnitMap       = getModelUnitMap(sceneWarFileName)
    local focusModelUnit     = modelUnitMap:getFocusModelUnit(beginningGridIndex, action.launchUnitID)
    local targetModelUnit    = modelUnitMap:getModelUnit(targetGridIndex)

    local actingUnitsData
    if (not isUnitVisible(sceneWarFileName, beginningGridIndex, focusModelUnit:getUnitType(), isModelUnitDiving(focusModelUnit), focusModelUnit:getPlayerIndex(), targetPlayerIndex)) then
        actingUnitsData = TableFunctions.union(actingUnitsData, generateUnitsDataForPublish(sceneWarFileName, focusModelUnit))
    end
    if ((targetModelUnit)                                                                                                                                and
        (not isUnitVisible(sceneWarFileName, targetGridIndex, targetModelUnit:getUnitType(), isModelUnitDiving(targetModelUnit), targetModelUnit:getPlayerIndex(), targetPlayerIndex))) then
        actingUnitsData = TableFunctions.union(actingUnitsData, generateUnitsDataForPublish(sceneWarFileName, targetModelUnit))
    end

    local actionForPublish = TableFunctions.clone(action, {"revealedUnits"})
    actionForPublish.actingUnitsData = actingUnitsData

    return actionForPublish
end

creators.createActionForBeginTurn = function(action, targetPlayerIndex)
    local repairData = action.repairData
    if (not repairData) then
        return action
    end

    local sceneWarFileName    = action.fileName
    local modelUnitMap        = getModelUnitMap(sceneWarFileName)
    local ignoredUnitIDsOnMap = {}
    for unitID, data in pairs(repairData.onMapData) do
        local gridIndex = data.gridIndex
        local modelUnit = modelUnitMap:getModelUnit(gridIndex)
        if (not isUnitVisible(sceneWarFileName, gridIndex, modelUnit:getUnitType(), isModelUnitDiving(modelUnit), modelUnit:getPlayerIndex(), targetPlayerIndex)) then
            ignoredUnitIDsOnMap[#ignoredUnitIDsOnMap + 1] = unitID
        end
    end

    local ignoredUnitIDsLoaded = {}
    for unitID, data in pairs(repairData.loadedData) do
        local gridIndex = modelUnitMap:getLoadedModelUnitWithUnitId(unitID)
        local modelUnit = modelUnitMap:getModelUnit(gridIndex)
        if (not isUnitVisible(sceneWarFileName, gridIndex, modelUnit:getUnitType(), isModelUnitDiving(modelUnit), modelUnit:getPlayerIndex(), targetPlayerIndex)) then
            ignoredUnitIDsLoaded[#ignoredUnitIDsLoaded + 1] = unitID
        end
    end

    local actionForPublish = TableFunctions.clone(action)
    actionForPublish.repairData = {
        onMapData     = TableFunctions.clone(repairData.onMapData,  ignoredUnitIDsOnMap),
        loadedData    = TableFunctions.clone(repairData.loadedData, ignoredUnitIDsLoaded),
        remainingFund = repairData.remainingFund,
    }
    return actionForPublish
end

creators.createActionForBuildModelTile = function(action, targetPlayerIndex)
    -- 为简单起见，目前的代码实现会把移动路线及相关单位数据完整广播到目标客户端。客户端自行判断在移动过程中是否隐藏该部队。
    -- 这种实现存在被破解作弊的可能。完美防作弊的实现需要对移动路线以及单位的数据也做出适当的删除。
    -- 行动玩家在移动后，可能会发现隐藏的敌方部队revealedUnits。这对于目标玩家不可见，因此广播的action须删除这些数据。

    local sceneWarFileName   = action.fileName
    local beginningGridIndex = action.path[1]
    local focusModelUnit     = getModelUnitMap(sceneWarFileName):getFocusModelUnit(beginningGridIndex, action.launchUnitID)
    local actionForPublish   = TableFunctions.clone(action, {"revealedUnits"})

    if (not isUnitVisible(sceneWarFileName, beginningGridIndex, focusModelUnit:getUnitType(), isModelUnitDiving(focusModelUnit), focusModelUnit:getPlayerIndex(), targetPlayerIndex)) then
        actionForPublish.actingUnitsData = generateUnitsDataForPublish(sceneWarFileName, focusModelUnit)
    end

    return actionForPublish
end

creators.createActionForCaptureModelTile = function(action, targetPlayerIndex)
    -- 为简单起见，目前的代码实现会把移动路线及相关单位数据完整广播到目标客户端。客户端自行判断在移动过程中是否隐藏该部队。
    -- 这种实现存在被破解作弊的可能。完美防作弊的实现需要对移动路线以及单位的数据也做出适当的删除。
    -- 行动玩家在移动后，可能会发现隐藏的敌方部队revealedUnits。这对于目标玩家不可见，因此广播的action须删除这些数据。

    local sceneWarFileName   = action.fileName
    local beginningGridIndex = action.path[1]
    local focusModelUnit     = getModelUnitMap(sceneWarFileName):getFocusModelUnit(beginningGridIndex, action.launchUnitID)
    local actionForPublish   = TableFunctions.clone(action, {"revealedUnits"})

    if (not isUnitVisible(sceneWarFileName, beginningGridIndex, focusModelUnit:getUnitType(), isModelUnitDiving(focusModelUnit), focusModelUnit:getPlayerIndex(), targetPlayerIndex)) then
        actionForPublish.actingUnitsData = generateUnitsDataForPublish(sceneWarFileName, focusModelUnit)
    end

    return actionForPublish
end

creators.createActionForDive = function(action, targetPlayerIndex)
    -- 为简单起见，目前的代码实现会把移动路线及相关单位数据完整广播到目标客户端。客户端自行判断在移动过程中是否隐藏该部队。
    -- 这种实现存在被破解作弊的可能。完美防作弊的实现需要对移动路线以及单位的数据也做出适当的删除。
    -- 行动玩家在移动后，可能会发现隐藏的敌方部队revealedUnits。这对于目标玩家不可见，因此广播的action须删除这些数据。

    local sceneWarFileName   = action.fileName
    local beginningGridIndex = action.path[1]
    local focusModelUnit     = getModelUnitMap(sceneWarFileName):getFocusModelUnit(beginningGridIndex, action.launchUnitID)
    local actionForPublish   = TableFunctions.clone(action, {"revealedUnits"})

    if (not isUnitVisible(sceneWarFileName, beginningGridIndex, focusModelUnit:getUnitType(), isModelUnitDiving(focusModelUnit), focusModelUnit:getPlayerIndex(), targetPlayerIndex)) then
        actionForPublish.actingUnitsData = generateUnitsDataForPublish(sceneWarFileName, focusModelUnit)
    end

    return actionForPublish
end

creators.createActionForDropModelUnit = function(action, targetPlayerIndex)
    -- 为简单起见，目前的代码实现会把移动路线及相关单位数据完整广播到目标客户端。客户端自行判断在移动过程中是否隐藏该部队。
    -- 这种实现存在被破解作弊的可能。完美防作弊的实现需要对移动路线以及单位的数据也做出适当的删除。
    -- 行动玩家在移动后，可能会发现隐藏的敌方部队revealedUnits。这对于目标玩家不可见，因此广播的action须删除这些数据。

    local sceneWarFileName   = action.fileName
    local beginningGridIndex = action.path[1]
    local focusModelUnit     = getModelUnitMap(sceneWarFileName):getFocusModelUnit(beginningGridIndex, action.launchUnitID)
    local actionForPublish   = TableFunctions.clone(action, {"revealedUnits"})

    if (not isUnitVisible(sceneWarFileName, beginningGridIndex, focusModelUnit:getUnitType(), isModelUnitDiving(focusModelUnit), focusModelUnit:getPlayerIndex(), targetPlayerIndex)) then
        actionForPublish.actingUnitsData = generateUnitsDataForPublish(sceneWarFileName, focusModelUnit)
    end

    return actionForPublish
end

creators.createActionForEndTurn = function(action, targetPlayerIndex)
    return action
end

creators.createActionForJoinModelUnit = function(action, targetPlayerIndex)
    -- 为简单起见，目前的代码实现会把移动路线，包括合流的两个部队的数据完整广播到目标客户端（不管对目标玩家是否可见）。客户端自行判断在移动过程中是否隐藏该部队。
    -- 这种实现存在被破解作弊的可能。完美防作弊的实现需要对移动路线以及单位的数据也做出适当的删除，同时需要计算相关结果数据一并传送（如合流收入）。
    -- 行动玩家在移动后，可能会发现隐藏的敌方部队revealedUnits。这对于目标玩家不可见，因此广播的action须删除这些数据。

    local sceneWarFileName    = action.fileName
    local path                = action.path
    local beginningGridIndex  = path[1]
    local endingGridIndex     = path[#path]
    local modelUnitMap        = getModelUnitMap(sceneWarFileName)
    local focusModelUnit      = modelUnitMap:getFocusModelUnit(beginningGridIndex, action.launchUnitID)
    local joiningModelUnit    = modelUnitMap:getModelUnit(endingGridIndex)
    local unitPlayerIndex     = focusModelUnit:getPlayerIndex()

    local actingUnitsData
    if (not isUnitVisible(sceneWarFileName, beginningGridIndex, focusModelUnit:getUnitType(), isModelUnitDiving(focusModelUnit), unitPlayerIndex, targetPlayerIndex)) then
        actingUnitsData = TableFunctions.union(actingUnitsData, generateUnitsDataForPublish(sceneWarFileName, focusModelUnit))
    end
    if (not isUnitVisible(sceneWarFileName, endingGridIndex, joiningModelUnit:getUnitType(), isModelUnitDiving(joiningModelUnit), unitPlayerIndex, targetPlayerIndex)) then
        actingUnitsData = TableFunctions.union(actingUnitsData, generateUnitsDataForPublish(sceneWarFileName, joiningModelUnit))
    end

    local actionForPublish = TableFunctions.clone(action, {"revealedUnits"})
    actionForPublish.actingUnitsData = actingUnitsData

    return actionForPublish
end

creators.createActionForLaunchSilo = function(action, targetPlayerIndex)
    -- 为简单起见，目前的代码实现会把移动路线及相关单位数据完整广播到目标客户端。客户端自行判断在移动过程中是否隐藏该部队。
    -- 这种实现存在被破解作弊的可能。完美防作弊的实现需要对移动路线以及单位的数据也做出适当的删除。
    -- 行动玩家在移动后，可能会发现隐藏的敌方部队revealedUnits。这对于目标玩家不可见，因此广播的action须删除这些数据。

    local sceneWarFileName   = action.fileName
    local beginningGridIndex = action.path[1]
    local focusModelUnit     = getModelUnitMap(sceneWarFileName):getFocusModelUnit(beginningGridIndex, action.launchUnitID)
    local actionForPublish   = TableFunctions.clone(action, {"revealedUnits"})

    if (not isUnitVisible(sceneWarFileName, beginningGridIndex, focusModelUnit:getUnitType(), isModelUnitDiving(focusModelUnit), focusModelUnit:getPlayerIndex(), targetPlayerIndex)) then
        actionForPublish.actingUnitsData = generateUnitsDataForPublish(sceneWarFileName, focusModelUnit)
    end

    return actionForPublish
end

creators.createActionForLoadModelUnit = function(action, targetPlayerIndex)
    -- 为简单起见，目前的代码实现会把移动路线完整广播到目标客户端（除非移动前后都对目标玩家不可见）。客户端自行判断在移动过程中是否隐藏该部队。
    -- 这种实现存在被破解作弊的可能。完美防作弊的实现需要对移动路线以及单位的数据也做出适当的删除。
    -- 行动玩家在移动后，可能会发现隐藏的敌方部队revealedUnits。这对于目标玩家不可见，因此广播的action须删除这些数据。

    local sceneWarFileName   = action.fileName
    local beginningGridIndex = action.path[1]
    local focusModelUnit     = getModelUnitMap(sceneWarFileName):getFocusModelUnit(beginningGridIndex, action.launchUnitID)

    local actionForPublish = TableFunctions.clone(action, {"revealedUnits"})
    if (not isUnitVisible(sceneWarFileName, beginningGridIndex, focusModelUnit:getUnitType(), isModelUnitDiving(focusModelUnit), focusModelUnit:getPlayerIndex(), targetPlayerIndex)) then
        actionForPublish.actingUnitsData = generateUnitsDataForPublish(sceneWarFileName, focusModelUnit)
    end

    return actionForPublish
end

creators.createActionForProduceModelUnitOnTile = function(action, playerIndex)
    -- 生产了新部队后，生产者自己可能会发现隐藏的敌方部队revealedUnits，但这对生产者以外的玩家都是不可知的，因此广播的action必须删除这些数据。
    local isDiving        = (getUnitTypeWithTiledId(action.tiledID) == "Submarine")
    local unitPlayerIndex = getPlayerIndexWithTiledId(action.tiledID)
    if (isUnitVisible(action.fileName, action.gridIndex, "Submarine", isDiving, unitPlayerIndex, playerIndex)) then
        return TableFunctions.clone(action, {"revealedUnits"})
    else
        -- 其他玩家没有部队能够看到潜艇，那么要隐藏潜艇数据。
        return {
            actionName = "ProduceModelUnitOnTile",
            actionID   = action.actionID,
            fileName   = action.fileName,
            cost       = action.cost,
        }
    end
end

creators.createActionForProduceModelUnitOnUnit = function(action, playerIndex)
    -- 本action不涉及移动、发现新部队，明战下生产者也必定是对其他玩家可见的，因此不需要隐藏数据。
    return action
end

creators.createActionForSupplyModelUnit = function(action, targetPlayerIndex)
    -- 为简单起见，目前的代码实现会把移动路线完整广播到目标客户端（除非移动前后都对目标玩家不可见）。客户端自行判断在移动过程中是否隐藏该部队。
    -- 这种实现存在被破解作弊的可能。完美防作弊的实现需要对移动路线以及单位的数据也做出适当的删除。
    -- 行动玩家在移动后，可能会发现隐藏的敌方部队revealedUnits。这对于目标玩家不可见，因此广播的action须删除这些数据。

    local sceneWarFileName   = action.fileName
    local beginningGridIndex = action.path[1]
    local focusModelUnit     = getModelUnitMap(sceneWarFileName):getFocusModelUnit(beginningGridIndex, action.launchUnitID)

    local actionForPublish   = TableFunctions.clone(action, IGNORED_KEYS_IN_PUBLISHING)
    if (not isUnitVisible(sceneWarFileName, beginningGridIndex, focusModelUnit:getUnitType(), isModelUnitDiving(focusModelUnit), focusModelUnit:getPlayerIndex(), targetPlayerIndex)) then
        actionForPublish.actingUnitsData = generateUnitsDataForPublish(sceneWarFileName, focusModelUnit)
    end

    return actionForPublish
end

creators.createActionForSurface = function(action, targetPlayerIndex)
    -- 为简单起见，目前的代码实现会把移动路线及相关单位数据完整广播到目标客户端。客户端自行判断在移动过程中是否隐藏该部队。
    -- 这种实现存在被破解作弊的可能。完美防作弊的实现需要对移动路线以及单位的数据也做出适当的删除。
    -- 行动玩家在移动后，可能会发现隐藏的敌方部队revealedUnits。这对于目标玩家不可见，因此广播的action须删除这些数据。

    local sceneWarFileName   = action.fileName
    local beginningGridIndex = action.path[1]
    local focusModelUnit     = getModelUnitMap(sceneWarFileName):getFocusModelUnit(beginningGridIndex, action.launchUnitID)

    local actionForPublish   = TableFunctions.clone(action, IGNORED_KEYS_IN_PUBLISHING)
    if (not isUnitVisible(sceneWarFileName, beginningGridIndex, focusModelUnit:getUnitType(), isModelUnitDiving(focusModelUnit), focusModelUnit:getPlayerIndex(), targetPlayerIndex)) then
        actionForPublish.actingUnitsData = generateUnitsDataForPublish(sceneWarFileName, focusModelUnit)
    end

    return actionForPublish
end

creators.createActionForSurrender = function(action, targetPlayerIndex)
    return action
end

creators.createActionForWait = function(action, targetPlayerIndex)
    -- 为简单起见，目前的代码实现会把移动路线完整广播到目标客户端（除非移动前后都对目标玩家不可见）。客户端自行判断在移动过程中是否隐藏该部队。
    -- 这种实现存在被破解作弊的可能。完美防作弊的实现需要对移动路线以及单位的数据也做出适当的删除。
    -- 行动玩家在移动后，可能会发现隐藏的敌方部队revealedUnits。这对于目标玩家不可见，因此广播的action须删除这些数据。

    local sceneWarFileName   = action.fileName
    local beginningGridIndex = action.path[1]
    local focusModelUnit     = getModelUnitMap(sceneWarFileName):getFocusModelUnit(beginningGridIndex, action.launchUnitID)

    local actionForPublish   = TableFunctions.clone(action, IGNORED_KEYS_IN_PUBLISHING)
    if (not isUnitVisible(sceneWarFileName, beginningGridIndex, focusModelUnit:getUnitType(), isModelUnitDiving(focusModelUnit), focusModelUnit:getPlayerIndex(), targetPlayerIndex)) then
        actionForPublish.actingUnitsData = generateUnitsDataForPublish(sceneWarFileName, focusModelUnit)
    end

    return actionForPublish
end

--------------------------------------------------------------------------------
-- The public functions.
--------------------------------------------------------------------------------
function ActionPublisher.createActionsForPublish(action)
    local sceneWarFileName   = action.fileName
    local playerIndexInTurn  = getModelTurnManager(sceneWarFileName):getPlayerIndex()
    local modelPlayerManager = getModelPlayerManager(sceneWarFileName)
    local generator          = creators["createActionFor" .. action.actionName]

    local actionsForPublish  = {}
    modelPlayerManager:forEachModelPlayer(function(modelPlayer, playerIndex)
        if ((playerIndex ~= playerIndexInTurn) and
            (modelPlayer:isAlive()))           then
            actionsForPublish[modelPlayer:getAccount()] = generator(action, playerIndex)
        end
    end)

    return actionsForPublish
end

return ActionPublisher
