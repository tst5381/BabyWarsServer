
local ActionPublisher = {}

local ActionCodeFunctions   = requireBW("src.app.utilities.ActionCodeFunctions")
local GameConstantFunctions = requireBW("src.app.utilities.GameConstantFunctions")
local GridIndexFunctions    = requireBW("src.app.utilities.GridIndexFunctions")
local SingletonGetters      = requireBW("src.app.utilities.SingletonGetters")
local TableFunctions        = requireBW("src.app.utilities.TableFunctions")
local VisibilityFunctions   = requireBW("src.app.utilities.VisibilityFunctions")

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
local ACTION_CODE_CHAT            = ActionCodeFunctions.getActionCode("ActionChat")
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
    local beginningGridIndex = action.path.pathNodes[1]
    local targetGridIndex    = action.targetGridIndex
    local modelUnitMap       = getModelUnitMap(modelSceneWar)
    local modelUnit          = modelUnitMap:getModelUnit(beginningGridIndex)
    local targetModelUnit    = modelUnitMap:getModelUnit(targetGridIndex)

    local actingUnitsData
    if (not isUnitVisible(modelSceneWar, beginningGridIndex, modelUnit:getUnitType(), isModelUnitDiving(modelUnit), modelUnit:getPlayerIndex(), targetPlayerIndex)) then
        actingUnitsData = TableFunctions.union(actingUnitsData, generateUnitsDataForPublish(modelSceneWar, modelUnit))
    end
    if ((targetModelUnit)                                                                                                                                                            and
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
    local pathNodes          = action.path.pathNodes
    local beginningGridIndex = pathNodes[1]
    local endingGridIndex    = pathNodes[#pathNodes]
    local modelUnit          = getModelUnitMap(modelSceneWar):getModelUnit(beginningGridIndex)

    local actionForPublish   = TableFunctions.clone(action, IGNORED_KEYS_FOR_PUBLISHING)
    if (not isTileVisible(modelSceneWar, endingGridIndex, targetPlayerIndex)) then
        local modelTileMap = getModelTileMap(modelSceneWar)
        actionForPublish.actingTilesData = generateTilesDataForPublish(modelTileMap:getModelTile(endingGridIndex), modelTileMap:getMapSize())
    end
    if (not isUnitVisible(modelSceneWar, beginningGridIndex, modelUnit:getUnitType(), isModelUnitDiving(modelUnit), modelUnit:getPlayerIndex(), targetPlayerIndex)) then
        actionForPublish.actingUnitsData = generateUnitsDataForPublish(modelSceneWar, modelUnit)
    end

    return actionForPublish
end

creators.createForActionCaptureModelTile = function(action, targetPlayerIndex, modelSceneWar)
    local pathNodes          = action.path.pathNodes
    local beginningGridIndex = pathNodes[1]
    local endingGridIndex    = pathNodes[#pathNodes]
    local modelUnit          = getModelUnitMap(modelSceneWar):getModelUnit(beginningGridIndex)

    local actionForPublish   = TableFunctions.clone(action, IGNORED_KEYS_FOR_PUBLISHING)
    if (not isTileVisible(modelSceneWar, endingGridIndex, targetPlayerIndex)) then
        local modelTileMap = getModelTileMap(modelSceneWar)
        actionForPublish.actingTilesData = generateTilesDataForPublish(modelTileMap:getModelTile(endingGridIndex), modelTileMap:getMapSize())
    end
    if (not isUnitVisible(modelSceneWar, beginningGridIndex, modelUnit:getUnitType(), isModelUnitDiving(modelUnit), modelUnit:getPlayerIndex(), targetPlayerIndex)) then
        actionForPublish.actingUnitsData = generateUnitsDataForPublish(modelSceneWar, modelUnit)
    end

    return actionForPublish
end

creators.createForActionChat = function(action, targetPlayerIndex, modelSceneWar)
    local channelID = action.channelID
    if ((not channelID)                                                                                                                                or
        (SingletonGetters.getModelChatManager(modelSceneWar):getChannelIdWithPlayerIndices(action.senderPlayerIndex, targetPlayerIndex) == channelID)) then
        return action
    else
        return nil
    end
end

creators.createForActionDestroyOwnedModelUnit = function(action, targetPlayerIndex, modelSceneWar)
    local gridIndex = action.gridIndex
    local modelUnit = getModelUnitMap(modelSceneWar):getModelUnit(gridIndex)

    local actionForPublish = TableFunctions.clone(action, IGNORED_KEYS_FOR_PUBLISHING)
    if (not isUnitVisible(modelSceneWar, gridIndex, modelUnit:getUnitType(), isModelUnitDiving(modelUnit), modelUnit:getPlayerIndex(), targetPlayerIndex)) then
        actionForPublish.gridIndex = nil
    end

    return actionForPublish
end

creators.createForActionDive = function(action, targetPlayerIndex, modelSceneWar)
    local beginningGridIndex = action.path.pathNodes[1]
    local modelUnit          = getModelUnitMap(modelSceneWar):getModelUnit(beginningGridIndex)

    local actionForPublish   = TableFunctions.clone(action, IGNORED_KEYS_FOR_PUBLISHING)
    if (not isUnitVisible(modelSceneWar, beginningGridIndex, modelUnit:getUnitType(), isModelUnitDiving(modelUnit), modelUnit:getPlayerIndex(), targetPlayerIndex)) then
        actionForPublish.actingUnitsData = generateUnitsDataForPublish(modelSceneWar, modelUnit)
    end

    return actionForPublish
end

creators.createForActionDropModelUnit = function(action, targetPlayerIndex, modelSceneWar)
    local beginningGridIndex = action.path.pathNodes[1]
    local modelUnit          = getModelUnitMap(modelSceneWar):getModelUnit(beginningGridIndex)

    local actionForPublish   = TableFunctions.clone(action, IGNORED_KEYS_FOR_PUBLISHING)
    if (not isUnitVisible(modelSceneWar, beginningGridIndex, modelUnit:getUnitType(), isModelUnitDiving(modelUnit), modelUnit:getPlayerIndex(), targetPlayerIndex)) then
        actionForPublish.actingUnitsData = generateUnitsDataForPublish(modelSceneWar, modelUnit)
    end

    return actionForPublish
end

creators.createForActionEndTurn = function(action, targetPlayerIndex, modelSceneWar)
    return action
end

creators.createForActionJoinModelUnit = function(action, targetPlayerIndex, modelSceneWar)
    local pathNodes          = action.path.pathNodes
    local beginningGridIndex = pathNodes[1]
    local endingGridIndex    = pathNodes[#pathNodes]
    local modelUnitMap       = getModelUnitMap(modelSceneWar)
    local modelUnit          = modelUnitMap:getModelUnit(beginningGridIndex)
    local joiningModelUnit   = modelUnitMap:getModelUnit(endingGridIndex)
    local unitPlayerIndex    = modelUnit:getPlayerIndex()

    local actingUnitsData
    if (not isUnitVisible(modelSceneWar, beginningGridIndex, modelUnit:getUnitType(), isModelUnitDiving(modelUnit), unitPlayerIndex, targetPlayerIndex)) then
        actingUnitsData = TableFunctions.union(actingUnitsData, generateUnitsDataForPublish(modelSceneWar, modelUnit))
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
    local modelUnit          = getModelUnitMap(modelSceneWar):getModelUnit(beginningGridIndex)

    local actionForPublish           = TableFunctions.clone(action, IGNORED_KEYS_FOR_PUBLISHING)
    actionForPublish.actionCode      = ACTION_CODES.ActionWait
    actionForPublish.targetGridIndex = nil
    if (not isUnitVisible(modelSceneWar, beginningGridIndex, modelUnit:getUnitType(), isModelUnitDiving(modelUnit), modelUnit:getPlayerIndex(), targetPlayerIndex)) then
        actionForPublish.actingUnitsData = generateUnitsDataForPublish(modelSceneWar, modelUnit)
    end

    return actionForPublish
end

creators.createForActionLaunchSilo = function(action, targetPlayerIndex, modelSceneWar)
    local beginningGridIndex = action.path.pathNodes[1]
    local modelUnit          = getModelUnitMap(modelSceneWar):getModelUnit(beginningGridIndex)

    local actionForPublish   = TableFunctions.clone(action, IGNORED_KEYS_FOR_PUBLISHING)
    if (not isUnitVisible(modelSceneWar, beginningGridIndex, modelUnit:getUnitType(), isModelUnitDiving(modelUnit), modelUnit:getPlayerIndex(), targetPlayerIndex)) then
        actionForPublish.actingUnitsData = generateUnitsDataForPublish(modelSceneWar, modelUnit)
    end

    return actionForPublish
end

creators.createForActionLoadModelUnit = function(action, targetPlayerIndex, modelSceneWar)
    local pathNodes          = action.path.pathNodes
    local modelUnitMap       = getModelUnitMap(modelSceneWar)
    local endingGridIndex    = pathNodes[#pathNodes]
    local loaderModelUnit    = modelUnitMap:getModelUnit(endingGridIndex)
    local playerIndex        = loaderModelUnit:getPlayerIndex()
    local beginningGridIndex = pathNodes[1]
    local modelUnit          = modelUnitMap:getModelUnit(beginningGridIndex)

    local actingUnitsData
    if (not isUnitVisible(modelSceneWar, beginningGridIndex, modelUnit:getUnitType(), isModelUnitDiving(modelUnit), playerIndex, targetPlayerIndex)) then
        actingUnitsData = TableFunctions.union(actingUnitsData, generateUnitsDataForPublish(modelSceneWar, modelUnit))
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
            actionCode = ACTION_CODES.ActionProduceModelUnitOnTile,
            actionID   = action.actionID,
            warID      = action.warID,
            cost       = action.cost,
        }
    end
end

creators.createForActionProduceModelUnitOnUnit = function(action, targetPlayerIndex, modelSceneWar)
    local beginningGridIndex = action.path.pathNodes[1]
    local modelUnit          = getModelUnitMap(modelSceneWar):getModelUnit(beginningGridIndex)

    local actionForPublish   = TableFunctions.clone(action, IGNORED_KEYS_FOR_PUBLISHING)
    if (not isUnitVisible(modelSceneWar, beginningGridIndex, modelUnit:getUnitType(), isModelUnitDiving(modelUnit), modelUnit:getPlayerIndex(), targetPlayerIndex)) then
        actionForPublish.actingUnitsData = generateUnitsDataForPublish(modelSceneWar, modelUnit)
    end

    return actionForPublish
end

creators.createForActionSupplyModelUnit = function(action, targetPlayerIndex, modelSceneWar)
    local beginningGridIndex = action.path.pathNodes[1]
    local modelUnit          = getModelUnitMap(modelSceneWar):getModelUnit(beginningGridIndex)

    local actionForPublish   = TableFunctions.clone(action, IGNORED_KEYS_FOR_PUBLISHING)
    if (not isUnitVisible(modelSceneWar, beginningGridIndex, modelUnit:getUnitType(), isModelUnitDiving(modelUnit), modelUnit:getPlayerIndex(), targetPlayerIndex)) then
        actionForPublish.actingUnitsData = generateUnitsDataForPublish(modelSceneWar, modelUnit)
    end

    return actionForPublish
end

creators.createForActionSurface = function(action, targetPlayerIndex, modelSceneWar)
    local beginningGridIndex = action.path.pathNodes[1]
    local modelUnit          = getModelUnitMap(modelSceneWar):getModelUnit(beginningGridIndex)

    local actionForPublish   = TableFunctions.clone(action, IGNORED_KEYS_FOR_PUBLISHING)
    if (not isUnitVisible(modelSceneWar, beginningGridIndex, modelUnit:getUnitType(), isModelUnitDiving(modelUnit), modelUnit:getPlayerIndex(), targetPlayerIndex)) then
        actionForPublish.actingUnitsData = generateUnitsDataForPublish(modelSceneWar, modelUnit)
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
    local beginningGridIndex = action.path.pathNodes[1]
    local modelUnit          = getModelUnitMap(modelSceneWar):getModelUnit(beginningGridIndex)

    local actionForPublish   = TableFunctions.clone(action, IGNORED_KEYS_FOR_PUBLISHING)
    if (not isUnitVisible(modelSceneWar, beginningGridIndex, modelUnit:getUnitType(), isModelUnitDiving(modelUnit), modelUnit:getPlayerIndex(), targetPlayerIndex)) then
        actionForPublish.actingUnitsData = generateUnitsDataForPublish(modelSceneWar, modelUnit)
    end

    return actionForPublish
end

--------------------------------------------------------------------------------
-- The public functions.
--------------------------------------------------------------------------------
function ActionPublisher.createActionsForPublish(action, modelSceneWar)
    local actionCode        = action.actionCode
    local playerIndexActing = (actionCode == ACTION_CODE_CHAT) and (action.senderPlayerIndex) or (getModelTurnManager(modelSceneWar):getPlayerIndex())
    local generator         = creators["createFor" .. ActionCodeFunctions.getActionName(actionCode)]

    local actionsForPublish  = {}
    getModelPlayerManager(modelSceneWar):forEachModelPlayer(function(modelPlayer, playerIndex)
        if ((playerIndex ~= playerIndexActing) and
            (modelPlayer:isAlive()))           then
            actionsForPublish[modelPlayer:getAccount()] = generator(action, playerIndex, modelSceneWar)
        end
    end)

    return actionsForPublish
end

return ActionPublisher
