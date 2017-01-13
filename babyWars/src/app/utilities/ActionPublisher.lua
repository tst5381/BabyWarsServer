
local ActionPublisher = {}

local ActionCodeFunctions   = require("src.app.utilities.ActionCodeFunctions")
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
local isTileVisible             = VisibilityFunctions.isTileVisibleToPlayerIndex
local isUnitVisible             = VisibilityFunctions.isUnitOnMapVisibleToPlayerIndex
local next, pairs               = next, pairs

local ACTION_CODES                = ActionCodeFunctions.getFullList()
local IGNORED_KEYS_FOR_PUBLISHING = {"revealedTiles", "revealedUnits"}

--------------------------------------------------------------------------------
-- The util functions.
--------------------------------------------------------------------------------
local function isModelUnitDiving(modelUnit)
    return (modelUnit.isDiving) and (modelUnit:isDiving())
end

local function generateTilesDataForPublish(modelTile, mapSize)
    local data = modelTile:toSerializableTable()
    if (not data) then
        return nil
    else
        local gridIndex = modelTile:getGridIndex()
        return {[(gridIndex.x - 1) * mapSize.height + gridIndex.y] = data}
    end
end

local function generateSingleUnitDataForPublish(modelUnitMap, modelUnit)
    local data    = modelUnit:toSerializableTable()
    data.isLoaded = modelUnitMap:getLoadedModelUnitWithUnitId(modelUnit:getUnitId()) ~= nil

    return data
end

local function generateUnitsDataForPublish(modelSceneWar, modelUnit)
    local modelUnitMap = getModelUnitMap(modelSceneWar)
    local data         = {[modelUnit:getUnitId()] = generateSingleUnitDataForPublish(modelUnitMap, modelUnit)}
    for _, loadedModelUnit in pairs(modelUnitMap:getLoadedModelUnitsWithLoader(modelUnit, true) or {}) do
        data[loadedModelUnit:getUnitId()] = generateSingleUnitDataForPublish(modelUnitMap, loadedModelUnit)
    end

    return data
end

local function generateOnMapData(modelSceneWar, rawOnMapData, targetPlayerIndex)
    if (not rawOnMapData) then
        return nil
    else
        local modelUnitMap = getModelUnitMap(modelSceneWar)
        local onMapData    = TableFunctions.clone(rawOnMapData)
        for unitID, data in pairs(onMapData) do
            local gridIndex = data.gridIndex
            local modelUnit = modelUnitMap:getModelUnit(gridIndex)
            if (not isUnitVisible(modelSceneWar, gridIndex, modelUnit:getUnitType(), isModelUnitDiving(modelUnit), modelUnit:getPlayerIndex(), targetPlayerIndex)) then
                onMapData[unitID] = nil
            end
        end

        return (next(onMapData)) and (onMapData) or (nil)
    end
end

local function generateLoadedData(modelSceneWar, rawLoadedData, targetPlayerIndex)
    if (not rawLoadedData) then
        return nil
    else
        local modelUnitMap = getModelUnitMap(modelSceneWar)
        local loadedData   = TableFunctions.clone(rawLoadedData)
        for unitID, data in pairs(loadedData) do
            local gridIndex = modelUnitMap:getLoadedModelUnitWithUnitId(unitID):getGridIndex()
            local modelUnit = modelUnitMap:getModelUnit(gridIndex)
            if (not isUnitVisible(modelSceneWar, gridIndex, modelUnit:getUnitType(), isModelUnitDiving(modelUnit), modelUnit:getPlayerIndex(), targetPlayerIndex)) then
                loadedData[unitID] = nil
            end
        end

        return (next(loadedData)) and (loadedData) or (nil)
    end
end

local function generateRepairDataForActionBeginTurn(action, targetPlayerIndex, modelSceneWar)
    local rawRepairData = action.repairData
    if (not rawRepairData) then
        return nil
    else
        return {
            onMapData     = generateOnMapData( modelSceneWar, rawRepairData.onMapData,  targetPlayerIndex),
            loadedData    = generateLoadedData(modelSceneWar, rawRepairData.loadedData, targetPlayerIndex),
            remainingFund = rawRepairData.remainingFund,
        }
    end
end

local function generateSupplyDataForActionBeginTurn(action, targetPlayerIndex, modelSceneWar)
    local rawSupplyData = action.supplyData
    if (not rawSupplyData) then
        return nil
    else
        local supplyData = {
            onMapData  = generateOnMapData( modelSceneWar, rawSupplyData.onMapData,  targetPlayerIndex),
            loadedData = generateLoadedData(modelSceneWar, rawSupplyData.loadedData, targetPlayerIndex),
        }
        return (next(supplyData)) and (supplyData) or (nil)
    end
end

--------------------------------------------------------------------------------
-- The private functions that create actions for publish.
--------------------------------------------------------------------------------
local creators = {}
creators.createForActionActivateSkillGroup = function(action, targetPlayerIndex, modelSceneWar)
    return TableFunctions.clone(action, IGNORED_KEYS_FOR_PUBLISHING)
end

creators.createForActionAttack = function(action, targetPlayerIndex, modelSceneWar)
    -- 为简单起见，目前的代码实现会把移动路线，包括合流的两个部队的数据完整广播到目标客户端（不管对目标玩家是否可见）。客户端自行判断在移动过程中是否隐藏该部队。
    -- 这种实现存在被破解作弊的可能。完美防作弊的实现需要对移动路线以及单位的数据也做出适当的删除，同时需要计算相关结果数据一并传送（如合流收入）。
    -- 行动玩家在移动后，可能会发现隐藏的敌方部队revealedUnits。这对于目标玩家不可见，因此广播的action须删除这些数据。

    local beginningGridIndex = action.path.pathNodes[1]
    local targetGridIndex    = action.targetGridIndex
    local modelUnitMap       = getModelUnitMap(modelSceneWar)
    local focusModelUnit     = modelUnitMap:getFocusModelUnit(beginningGridIndex, action.launchUnitID)
    local targetModelUnit    = modelUnitMap:getModelUnit(targetGridIndex)

    local actingUnitsData
    if (not isUnitVisible(modelSceneWar, beginningGridIndex, focusModelUnit:getUnitType(), isModelUnitDiving(focusModelUnit), focusModelUnit:getPlayerIndex(), targetPlayerIndex)) then
        actingUnitsData = TableFunctions.union(actingUnitsData, generateUnitsDataForPublish(modelSceneWar, focusModelUnit))
    end
    if ((targetModelUnit)                                                                                                                                                               and
        (not isUnitVisible(modelSceneWar, targetGridIndex, targetModelUnit:getUnitType(), isModelUnitDiving(targetModelUnit), targetModelUnit:getPlayerIndex(), targetPlayerIndex))) then
        actingUnitsData = TableFunctions.union(actingUnitsData, generateUnitsDataForPublish(modelSceneWar, targetModelUnit))
    end

    local actionForPublish = TableFunctions.clone(action, IGNORED_KEYS_FOR_PUBLISHING)
    actionForPublish.actingUnitsData = actingUnitsData

    return actionForPublish
end

creators.createForActionBeginTurn = function(action, targetPlayerIndex, modelSceneWar)
    local actionForPublish      = TableFunctions.clone(action, IGNORED_KEYS_FOR_PUBLISHING)
    actionForPublish.repairData = generateRepairDataForActionBeginTurn(action, targetPlayerIndex, modelSceneWar)
    actionForPublish.supplyData = generateSupplyDataForActionBeginTurn(action, targetPlayerIndex, modelSceneWar)

    return actionForPublish
end

creators.createForActionBuildModelTile = function(action, targetPlayerIndex, modelSceneWar)
    -- 为简单起见，目前的代码实现会把移动路线及相关单位数据完整广播到目标客户端。客户端自行判断在移动过程中是否隐藏该部队。
    -- 这种实现存在被破解作弊的可能。完美防作弊的实现需要对移动路线以及单位的数据也做出适当的删除。
    -- 行动玩家在移动后，可能会发现隐藏的敌方部队revealedUnits。这对于目标玩家不可见，因此广播的action须删除这些数据。

    local pathNodes          = action.path.pathNodes
    local beginningGridIndex = pathNodes[1]
    local endingGridIndex    = pathNodes[#pathNodes]
    local focusModelUnit     = getModelUnitMap(modelSceneWar):getFocusModelUnit(beginningGridIndex, action.launchUnitID)
    local actionForPublish   = TableFunctions.clone(action, IGNORED_KEYS_FOR_PUBLISHING)

    if (not isTileVisible(modelSceneWar, endingGridIndex, targetPlayerIndex)) then
        local modelTileMap = getModelTileMap(modelSceneWar)
        actionForPublish.actingTilesData = generateTilesDataForPublish(modelTileMap:getModelTile(endingGridIndex), modelTileMap:getMapSize())
    end
    if (not isUnitVisible(modelSceneWar, beginningGridIndex, focusModelUnit:getUnitType(), isModelUnitDiving(focusModelUnit), focusModelUnit:getPlayerIndex(), targetPlayerIndex)) then
        actionForPublish.actingUnitsData = generateUnitsDataForPublish(modelSceneWar, focusModelUnit)
    end

    return actionForPublish
end

creators.createForActionCaptureModelTile = function(action, targetPlayerIndex, modelSceneWar)
    -- 为简单起见，目前的代码实现会把移动路线及相关单位数据完整广播到目标客户端。客户端自行判断在移动过程中是否隐藏该部队。
    -- 这种实现存在被破解作弊的可能。完美防作弊的实现需要对移动路线以及单位的数据也做出适当的删除。
    -- 行动玩家在移动后，可能会发现隐藏的敌方部队revealedUnits。这对于目标玩家不可见，因此广播的action须删除这些数据。

    local pathNodes          = action.path.pathNodes
    local beginningGridIndex = pathNodes[1]
    local endingGridIndex    = pathNodes[#pathNodes]
    local focusModelUnit     = getModelUnitMap(modelSceneWar):getFocusModelUnit(beginningGridIndex, action.launchUnitID)
    local actionForPublish   = TableFunctions.clone(action, IGNORED_KEYS_FOR_PUBLISHING)

    if (not isTileVisible(modelSceneWar, endingGridIndex, targetPlayerIndex)) then
        local modelTileMap = getModelTileMap(modelSceneWar)
        actionForPublish.actingTilesData = generateTilesDataForPublish(modelTileMap:getModelTile(endingGridIndex), modelTileMap:getMapSize())
    end
    if (not isUnitVisible(modelSceneWar, beginningGridIndex, focusModelUnit:getUnitType(), isModelUnitDiving(focusModelUnit), focusModelUnit:getPlayerIndex(), targetPlayerIndex)) then
        actionForPublish.actingUnitsData = generateUnitsDataForPublish(modelSceneWar, focusModelUnit)
    end

    return actionForPublish
end

creators.createForActionDestroyOwnedModelUnit = function(action, targetPlayerIndex, modelSceneWar)
    local gridIndex        = action.gridIndex
    local focusModelUnit   = getModelUnitMap(modelSceneWar):getModelUnit(gridIndex)
    local actionForPublish = TableFunctions.clone(action, IGNORED_KEYS_FOR_PUBLISHING)
    if (not isUnitVisible(modelSceneWar, gridIndex, focusModelUnit:getUnitType(), isModelUnitDiving(focusModelUnit), focusModelUnit:getPlayerIndex(), targetPlayerIndex)) then
        actionForPublish.gridIndex = nil
    end

    return actionForPublish
end

creators.createForActionDive = function(action, targetPlayerIndex, modelSceneWar)
    -- 为简单起见，目前的代码实现会把移动路线及相关单位数据完整广播到目标客户端。客户端自行判断在移动过程中是否隐藏该部队。
    -- 这种实现存在被破解作弊的可能。完美防作弊的实现需要对移动路线以及单位的数据也做出适当的删除。
    -- 行动玩家在移动后，可能会发现隐藏的敌方部队revealedUnits。这对于目标玩家不可见，因此广播的action须删除这些数据。

    local beginningGridIndex = action.path.pathNodes[1]
    local focusModelUnit     = getModelUnitMap(modelSceneWar):getFocusModelUnit(beginningGridIndex, action.launchUnitID)

    local actionForPublish   = TableFunctions.clone(action, IGNORED_KEYS_FOR_PUBLISHING)
    if (not isUnitVisible(modelSceneWar, beginningGridIndex, focusModelUnit:getUnitType(), isModelUnitDiving(focusModelUnit), focusModelUnit:getPlayerIndex(), targetPlayerIndex)) then
        actionForPublish.actingUnitsData = generateUnitsDataForPublish(modelSceneWar, focusModelUnit)
    end

    return actionForPublish
end

creators.createForActionDropModelUnit = function(action, targetPlayerIndex, modelSceneWar)
    -- 为简单起见，目前的代码实现会把移动路线及相关单位数据完整广播到目标客户端。客户端自行判断在移动过程中是否隐藏该部队。
    -- 这种实现存在被破解作弊的可能。完美防作弊的实现需要对移动路线以及单位的数据也做出适当的删除。
    -- 行动玩家在移动后，可能会发现隐藏的敌方部队revealedUnits。这对于目标玩家不可见，因此广播的action须删除这些数据。

    local beginningGridIndex = action.path.pathNodes[1]
    local focusModelUnit     = getModelUnitMap(modelSceneWar):getFocusModelUnit(beginningGridIndex, action.launchUnitID)

    local actionForPublish   = TableFunctions.clone(action, IGNORED_KEYS_FOR_PUBLISHING)
    if (not isUnitVisible(modelSceneWar, beginningGridIndex, focusModelUnit:getUnitType(), isModelUnitDiving(focusModelUnit), focusModelUnit:getPlayerIndex(), targetPlayerIndex)) then
        actionForPublish.actingUnitsData = generateUnitsDataForPublish(modelSceneWar, focusModelUnit)
    end

    return actionForPublish
end

creators.createForActionEndTurn = function(action, targetPlayerIndex, modelSceneWar)
    return action
end

creators.createForActionJoinModelUnit = function(action, targetPlayerIndex, modelSceneWar)
    -- 为简单起见，目前的代码实现会把移动路线，包括合流的两个部队的数据完整广播到目标客户端（不管对目标玩家是否可见）。客户端自行判断在移动过程中是否隐藏该部队。
    -- 这种实现存在被破解作弊的可能。完美防作弊的实现需要对移动路线以及单位的数据也做出适当的删除，同时需要计算相关结果数据一并传送（如合流收入）。
    -- 行动玩家在移动后，可能会发现隐藏的敌方部队revealedUnits。这对于目标玩家不可见，因此广播的action须删除这些数据。

    local pathNodes           = action.path.pathNodes
    local beginningGridIndex  = pathNodes[1]
    local endingGridIndex     = pathNodes[#pathNodes]
    local modelUnitMap        = getModelUnitMap(modelSceneWar)
    local focusModelUnit      = modelUnitMap:getFocusModelUnit(beginningGridIndex, action.launchUnitID)
    local joiningModelUnit    = modelUnitMap:getModelUnit(endingGridIndex)
    local unitPlayerIndex     = focusModelUnit:getPlayerIndex()

    local actingUnitsData
    if (not isUnitVisible(modelSceneWar, beginningGridIndex, focusModelUnit:getUnitType(), isModelUnitDiving(focusModelUnit), unitPlayerIndex, targetPlayerIndex)) then
        actingUnitsData = TableFunctions.union(actingUnitsData, generateUnitsDataForPublish(modelSceneWar, focusModelUnit))
    end
    if (not isUnitVisible(modelSceneWar, endingGridIndex, joiningModelUnit:getUnitType(), isModelUnitDiving(joiningModelUnit), unitPlayerIndex, targetPlayerIndex)) then
        actingUnitsData = TableFunctions.union(actingUnitsData, generateUnitsDataForPublish(modelSceneWar, joiningModelUnit))
    end

    local actionForPublish = TableFunctions.clone(action, IGNORED_KEYS_FOR_PUBLISHING)
    actionForPublish.actingUnitsData = actingUnitsData

    return actionForPublish
end

creators.createForActionLaunchFlare = function(action, targetPlayerIndex, modelSceneWar)
    local beginningGridIndex = action.path.pathNodes[1]
    local focusModelUnit     = getModelUnitMap(modelSceneWar):getFocusModelUnit(beginningGridIndex, action.launchUnitID)
    local actionForPublish   = TableFunctions.clone(action, IGNORED_KEYS_FOR_PUBLISHING)
    actionForPublish.actionCode      = ACTION_CODES.ActionWait
    actionForPublish.targetGridIndex = nil

    if (not isUnitVisible(modelSceneWar, beginningGridIndex, focusModelUnit:getUnitType(), isModelUnitDiving(focusModelUnit), focusModelUnit:getPlayerIndex(), targetPlayerIndex)) then
        actionForPublish.actingUnitsData = generateUnitsDataForPublish(modelSceneWar, focusModelUnit)
    end

    return actionForPublish
end

creators.createForActionLaunchSilo = function(action, targetPlayerIndex, modelSceneWar)
    -- 为简单起见，目前的代码实现会把移动路线及相关单位数据完整广播到目标客户端。客户端自行判断在移动过程中是否隐藏该部队。
    -- 这种实现存在被破解作弊的可能。完美防作弊的实现需要对移动路线以及单位的数据也做出适当的删除。
    -- 行动玩家在移动后，可能会发现隐藏的敌方部队revealedUnits。这对于目标玩家不可见，因此广播的action须删除这些数据。

    local beginningGridIndex = action.path.pathNodes[1]
    local focusModelUnit     = getModelUnitMap(modelSceneWar):getFocusModelUnit(beginningGridIndex, action.launchUnitID)

    local actionForPublish   = TableFunctions.clone(action, IGNORED_KEYS_FOR_PUBLISHING)
    if (not isUnitVisible(modelSceneWar, beginningGridIndex, focusModelUnit:getUnitType(), isModelUnitDiving(focusModelUnit), focusModelUnit:getPlayerIndex(), targetPlayerIndex)) then
        actionForPublish.actingUnitsData = generateUnitsDataForPublish(modelSceneWar, focusModelUnit)
    end

    return actionForPublish
end

creators.createForActionLoadModelUnit = function(action, targetPlayerIndex, modelSceneWar)
    -- 为简单起见，目前的代码实现会把移动路线完整广播到目标客户端（除非移动前后都对目标玩家不可见）。客户端自行判断在移动过程中是否隐藏该部队。
    -- 这种实现存在被破解作弊的可能。完美防作弊的实现需要对移动路线以及单位的数据也做出适当的删除。
    -- 行动玩家在移动后，可能会发现隐藏的敌方部队revealedUnits。这对于目标玩家不可见，因此广播的action须删除这些数据。

    local pathNodes          = action.path.pathNodes
    local modelUnitMap       = getModelUnitMap(modelSceneWar)
    local endingGridIndex    = pathNodes[#pathNodes]
    local loaderModelUnit    = modelUnitMap:getModelUnit(endingGridIndex)
    local playerIndex        = loaderModelUnit:getPlayerIndex()
    local beginningGridIndex = pathNodes[1]
    local focusModelUnit     = modelUnitMap:getFocusModelUnit(beginningGridIndex, action.launchUnitID)

    local actingUnitsData
    if (not isUnitVisible(modelSceneWar, beginningGridIndex, focusModelUnit:getUnitType(), isModelUnitDiving(focusModelUnit), playerIndex, targetPlayerIndex)) then
        actingUnitsData = TableFunctions.union(actingUnitsData, generateUnitsDataForPublish(modelSceneWar, focusModelUnit))
    end
    if (not isUnitVisible(modelSceneWar, endingGridIndex, loaderModelUnit:getUnitType(), isModelUnitDiving(loaderModelUnit), playerIndex, targetPlayerIndex)) then
        actingUnitsData = TableFunctions.union(actingUnitsData, generateUnitsDataForPublish(modelSceneWar, loaderModelUnit))
    end

    local actionForPublish = TableFunctions.clone(action, IGNORED_KEYS_FOR_PUBLISHING)
    actionForPublish.actingUnitsData = actingUnitsData

    return actionForPublish
end

creators.createForActionProduceModelUnitOnTile = function(action, targetPlayerIndex, modelSceneWar)
    local tiledID  = action.tiledID
    local unitType = getUnitTypeWithTiledId(tiledID)
    if (isUnitVisible(modelSceneWar, action.gridIndex, unitType, unitType == "Submarine", getPlayerIndexWithTiledId(tiledID), targetPlayerIndex)) then
        return TableFunctions.clone(action, IGNORED_KEYS_FOR_PUBLISHING)
    else
        return {
            actionCode       = ACTION_CODES.ActionProduceModelUnitOnTile,
            actionID         = action.actionID,
            sceneWarFileName = action.sceneWarFileName,
            cost             = action.cost,
        }
    end
end

creators.createForActionProduceModelUnitOnUnit = function(action, targetPlayerIndex, modelSceneWar)
    -- 为简单起见，目前的代码实现会把移动路线完整广播到目标客户端（除非移动前后都对目标玩家不可见）。客户端自行判断在移动过程中是否隐藏该部队。
    -- 这种实现存在被破解作弊的可能。完美防作弊的实现需要对移动路线以及单位的数据也做出适当的删除。
    -- 行动玩家在移动后，可能会发现隐藏的敌方部队revealedUnits。这对于目标玩家不可见，因此广播的action须删除这些数据。

    local beginningGridIndex = action.path.pathNodes[1]
    local focusModelUnit     = getModelUnitMap(modelSceneWar):getFocusModelUnit(beginningGridIndex, action.launchUnitID)

    local actionForPublish   = TableFunctions.clone(action, IGNORED_KEYS_FOR_PUBLISHING)
    if (not isUnitVisible(modelSceneWar, beginningGridIndex, focusModelUnit:getUnitType(), isModelUnitDiving(focusModelUnit), focusModelUnit:getPlayerIndex(), targetPlayerIndex)) then
        actionForPublish.actingUnitsData = generateUnitsDataForPublish(modelSceneWar, focusModelUnit)
    end

    return actionForPublish
end

creators.createForActionSupplyModelUnit = function(action, targetPlayerIndex, modelSceneWar)
    -- 为简单起见，目前的代码实现会把移动路线完整广播到目标客户端（除非移动前后都对目标玩家不可见）。客户端自行判断在移动过程中是否隐藏该部队。
    -- 这种实现存在被破解作弊的可能。完美防作弊的实现需要对移动路线以及单位的数据也做出适当的删除。
    -- 行动玩家在移动后，可能会发现隐藏的敌方部队revealedUnits。这对于目标玩家不可见，因此广播的action须删除这些数据。

    local beginningGridIndex = action.path.pathNodes[1]
    local focusModelUnit     = getModelUnitMap(modelSceneWar):getFocusModelUnit(beginningGridIndex, action.launchUnitID)

    local actionForPublish   = TableFunctions.clone(action, IGNORED_KEYS_FOR_PUBLISHING)
    if (not isUnitVisible(modelSceneWar, beginningGridIndex, focusModelUnit:getUnitType(), isModelUnitDiving(focusModelUnit), focusModelUnit:getPlayerIndex(), targetPlayerIndex)) then
        actionForPublish.actingUnitsData = generateUnitsDataForPublish(modelSceneWar, focusModelUnit)
    end

    return actionForPublish
end

creators.createForActionSurface = function(action, targetPlayerIndex, modelSceneWar)
    -- 为简单起见，目前的代码实现会把移动路线及相关单位数据完整广播到目标客户端。客户端自行判断在移动过程中是否隐藏该部队。
    -- 这种实现存在被破解作弊的可能。完美防作弊的实现需要对移动路线以及单位的数据也做出适当的删除。
    -- 行动玩家在移动后，可能会发现隐藏的敌方部队revealedUnits。这对于目标玩家不可见，因此广播的action须删除这些数据。

    local beginningGridIndex = action.path.pathNodes[1]
    local focusModelUnit     = getModelUnitMap(modelSceneWar):getFocusModelUnit(beginningGridIndex, action.launchUnitID)

    local actionForPublish   = TableFunctions.clone(action, IGNORED_KEYS_FOR_PUBLISHING)
    if (not isUnitVisible(modelSceneWar, beginningGridIndex, focusModelUnit:getUnitType(), isModelUnitDiving(focusModelUnit), focusModelUnit:getPlayerIndex(), targetPlayerIndex)) then
        actionForPublish.actingUnitsData = generateUnitsDataForPublish(modelSceneWar, focusModelUnit)
    end

    return actionForPublish
end

creators.createForActionSurrender = function(action, targetPlayerIndex, modelSceneWar)
    return action
end

creators.createForActionVoteForDraw = function(action, targetPlayerIndex, modelSceneWar)
    return action
end

creators.createForActionWait = function(action, targetPlayerIndex, modelSceneWar)
    -- 为简单起见，目前的代码实现会把移动路线完整广播到目标客户端（除非移动前后都对目标玩家不可见）。客户端自行判断在移动过程中是否隐藏该部队。
    -- 这种实现存在被破解作弊的可能。完美防作弊的实现需要对移动路线以及单位的数据也做出适当的删除。
    -- 行动玩家在移动后，可能会发现隐藏的敌方部队revealedUnits。这对于目标玩家不可见，因此广播的action须删除这些数据。

    local beginningGridIndex = action.path.pathNodes[1]
    local focusModelUnit     = getModelUnitMap(modelSceneWar):getFocusModelUnit(beginningGridIndex, action.launchUnitID)

    local actionForPublish   = TableFunctions.clone(action, IGNORED_KEYS_FOR_PUBLISHING)
    if (not isUnitVisible(modelSceneWar, beginningGridIndex, focusModelUnit:getUnitType(), isModelUnitDiving(focusModelUnit), focusModelUnit:getPlayerIndex(), targetPlayerIndex)) then
        actionForPublish.actingUnitsData = generateUnitsDataForPublish(modelSceneWar, focusModelUnit)
    end

    return actionForPublish
end

--------------------------------------------------------------------------------
-- The public functions.
--------------------------------------------------------------------------------
function ActionPublisher.createActionsForPublish(action, modelSceneWar)
    local playerIndexInTurn  = getModelTurnManager(modelSceneWar):getPlayerIndex()
    local modelPlayerManager = getModelPlayerManager(modelSceneWar)
    local generator          = creators["createFor" .. ActionCodeFunctions.getActionName(action.actionCode)]

    local actionsForPublish  = {}
    modelPlayerManager:forEachModelPlayer(function(modelPlayer, playerIndex)
        if ((playerIndex ~= playerIndexInTurn) and
            (modelPlayer:isAlive()))           then
            actionsForPublish[modelPlayer:getAccount()] = generator(action, playerIndex, modelSceneWar)
        end
    end)

    return actionsForPublish
end

return ActionPublisher
