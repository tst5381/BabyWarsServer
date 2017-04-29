
local ActionPublisher = {}

local ActionCodeFunctions   = requireFW("src.app.utilities.ActionCodeFunctions")
local GameConstantFunctions = requireFW("src.app.utilities.GameConstantFunctions")
local GridIndexFunctions    = requireFW("src.app.utilities.GridIndexFunctions")
local SingletonGetters      = requireFW("src.app.utilities.SingletonGetters")
local TableFunctions        = requireFW("src.app.utilities.TableFunctions")
local VisibilityFunctions   = requireFW("src.app.utilities.VisibilityFunctions")

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

local function generateTilesDataForPublish(modelTile, mapSize, ignoredTilesData)
    local gridIndex     = modelTile:getGridIndex()
    local positionIndex = (gridIndex.x - 1) * mapSize.height + gridIndex.y
    if ((ignoredTilesData) and (ignoredTilesData[positionIndex])) then
        return nil
    else
        local data = modelTile:toSerializableTable()
        if (not data) then
            return nil
        else
            return {[positionIndex] = data}
        end
    end
end

local function generateSingleUnitDataForPublish(modelUnitMap, modelUnit)
    local data    = modelUnit:toSerializableTable()
    data.isLoaded = modelUnitMap:getLoadedModelUnitWithUnitId(modelUnit:getUnitId()) ~= nil

    return data
end

local function generateUnitsDataForPublish(modelWar, modelUnit)
    local modelUnitMap = getModelUnitMap(modelWar)
    local data         = {[modelUnit:getUnitId()] = generateSingleUnitDataForPublish(modelUnitMap, modelUnit)}
    for _, loadedModelUnit in pairs(modelUnitMap:getLoadedModelUnitsWithLoader(modelUnit, true) or {}) do
        data[loadedModelUnit:getUnitId()] = generateSingleUnitDataForPublish(modelUnitMap, loadedModelUnit)
    end

    return data
end

local function generateOnMapData(modelWar, rawOnMapData, targetPlayerIndex)
    if (not rawOnMapData) then
        return nil
    else
        local modelUnitMap = getModelUnitMap(modelWar)
        local onMapData    = TableFunctions.clone(rawOnMapData)
        for unitID, data in pairs(onMapData) do
            local gridIndex = data.gridIndex
            local modelUnit = modelUnitMap:getModelUnit(gridIndex)
            if (not isUnitVisible(modelWar, gridIndex, modelUnit:getUnitType(), isModelUnitDiving(modelUnit), modelUnit:getPlayerIndex(), targetPlayerIndex)) then
                onMapData[unitID] = nil
            end
        end

        return (next(onMapData)) and (onMapData) or (nil)
    end
end

local function generateLoadedData(modelWar, rawLoadedData, targetPlayerIndex)
    if (not rawLoadedData) then
        return nil
    else
        local modelUnitMap = getModelUnitMap(modelWar)
        local loadedData   = TableFunctions.clone(rawLoadedData)
        for unitID, data in pairs(loadedData) do
            local gridIndex = modelUnitMap:getLoadedModelUnitWithUnitId(unitID):getGridIndex()
            local modelUnit = modelUnitMap:getModelUnit(gridIndex)
            if (not isUnitVisible(modelWar, gridIndex, modelUnit:getUnitType(), isModelUnitDiving(modelUnit), modelUnit:getPlayerIndex(), targetPlayerIndex)) then
                loadedData[unitID] = nil
            end
        end

        return (next(loadedData)) and (loadedData) or (nil)
    end
end

local function generateRepairDataForActionBeginTurn(action, targetPlayerIndex, modelWar)
    local rawRepairData = action.repairData
    if (not rawRepairData) then
        return nil
    else
        return {
            onMapData     = generateOnMapData( modelWar, rawRepairData.onMapData,  targetPlayerIndex),
            loadedData    = generateLoadedData(modelWar, rawRepairData.loadedData, targetPlayerIndex),
            remainingFund = rawRepairData.remainingFund,
        }
    end
end

local function generateSupplyDataForActionBeginTurn(action, targetPlayerIndex, modelWar)
    local rawSupplyData = action.supplyData
    if (not rawSupplyData) then
        return nil
    else
        local supplyData = {
            onMapData  = generateOnMapData( modelWar, rawSupplyData.onMapData,  targetPlayerIndex),
            loadedData = generateLoadedData(modelWar, rawSupplyData.loadedData, targetPlayerIndex),
        }
        return (next(supplyData)) and (supplyData) or (nil)
    end
end

local function cloneActionForPublish(modelWar, action, playerIndexActing, targetPlayerIndex)
    if (getModelPlayerManager(modelWar):isSameTeamIndex(playerIndexActing, targetPlayerIndex)) then
        return TableFunctions.clone(action)
    else
        return TableFunctions.clone(action, IGNORED_KEYS_FOR_PUBLISHING)
    end
end

--------------------------------------------------------------------------------
-- The private functions that create actions for publish.
--------------------------------------------------------------------------------
local creators = {}
creators.createForActionActivateSkill = function(action, playerIndexActing, targetPlayerIndex, modelWar)
    return cloneActionForPublish(modelWar, action, playerIndexActing, targetPlayerIndex)
end

creators.createForActionAttack = function(action, playerIndexActing, targetPlayerIndex, modelWar)
    local beginningGridIndex = action.path.pathNodes[1]
    local targetGridIndex    = action.targetGridIndex
    local modelUnitMap       = getModelUnitMap(modelWar)
    local modelUnit          = modelUnitMap:getModelUnit(beginningGridIndex)
    local targetModelUnit    = modelUnitMap:getModelUnit(targetGridIndex)

    local actingUnitsData
    if (not isUnitVisible(modelWar, beginningGridIndex, modelUnit:getUnitType(), isModelUnitDiving(modelUnit), modelUnit:getPlayerIndex(), targetPlayerIndex)) then
        actingUnitsData = TableFunctions.union(actingUnitsData, generateUnitsDataForPublish(modelWar, modelUnit))
    end
    if ((targetModelUnit)                                                                                                                                                            and
        (not isUnitVisible(modelWar, targetGridIndex, targetModelUnit:getUnitType(), isModelUnitDiving(targetModelUnit), targetModelUnit:getPlayerIndex(), targetPlayerIndex))) then
        actingUnitsData = TableFunctions.union(actingUnitsData, generateUnitsDataForPublish(modelWar, targetModelUnit))
    end

    local actionForPublish = cloneActionForPublish(modelWar, action, playerIndexActing, targetPlayerIndex)
    actionForPublish.actingUnitsData = actingUnitsData

    return actionForPublish
end

creators.createForActionBeginTurn = function(action, playerIndexActing, targetPlayerIndex, modelWar)
    local actionForPublish      = cloneActionForPublish(modelWar, action, playerIndexActing, targetPlayerIndex)
    actionForPublish.repairData = generateRepairDataForActionBeginTurn(action, targetPlayerIndex, modelWar)
    actionForPublish.supplyData = generateSupplyDataForActionBeginTurn(action, targetPlayerIndex, modelWar)

    return actionForPublish
end

creators.createForActionBuildModelTile = function(action, playerIndexActing, targetPlayerIndex, modelWar)
    local pathNodes          = action.path.pathNodes
    local beginningGridIndex = pathNodes[1]
    local endingGridIndex    = pathNodes[#pathNodes]
    local modelUnit          = getModelUnitMap(modelWar):getModelUnit(beginningGridIndex)

    local actionForPublish   = cloneActionForPublish(modelWar, action, playerIndexActing, targetPlayerIndex)
    if (not isTileVisible(modelWar, endingGridIndex, targetPlayerIndex)) then
        local modelTileMap = getModelTileMap(modelWar)
        actionForPublish.actingTilesData = generateTilesDataForPublish(modelTileMap:getModelTile(endingGridIndex), modelTileMap:getMapSize(), actionForPublish.revealedTiles)
    end
    if (not isUnitVisible(modelWar, beginningGridIndex, modelUnit:getUnitType(), isModelUnitDiving(modelUnit), modelUnit:getPlayerIndex(), targetPlayerIndex)) then
        actionForPublish.actingUnitsData = generateUnitsDataForPublish(modelWar, modelUnit)
    end

    return actionForPublish
end

creators.createForActionCaptureModelTile = function(action, playerIndexActing, targetPlayerIndex, modelWar)
    local pathNodes          = action.path.pathNodes
    local beginningGridIndex = pathNodes[1]
    local endingGridIndex    = pathNodes[#pathNodes]
    local modelUnit          = getModelUnitMap(modelWar):getModelUnit(beginningGridIndex)

    local actionForPublish   = cloneActionForPublish(modelWar, action, playerIndexActing, targetPlayerIndex)
    if (not isTileVisible(modelWar, endingGridIndex, targetPlayerIndex)) then
        local modelTileMap = getModelTileMap(modelWar)
        actionForPublish.actingTilesData = generateTilesDataForPublish(modelTileMap:getModelTile(endingGridIndex), modelTileMap:getMapSize(), actionForPublish.revealedTiles)
    end
    if (not isUnitVisible(modelWar, beginningGridIndex, modelUnit:getUnitType(), isModelUnitDiving(modelUnit), modelUnit:getPlayerIndex(), targetPlayerIndex)) then
        actionForPublish.actingUnitsData = generateUnitsDataForPublish(modelWar, modelUnit)
    end

    return actionForPublish
end

creators.createForActionChat = function(action, playerIndexActing, targetPlayerIndex, modelWar)
    local channelID = action.channelID
    if ((not channelID)                                                                                                                                or
        (SingletonGetters.getModelChatManager(modelWar):getChannelIdWithPlayerIndices(action.senderPlayerIndex, targetPlayerIndex) == channelID)) then
        return action
    else
        return nil
    end
end

creators.createForActionDestroyOwnedModelUnit = function(action, playerIndexActing, targetPlayerIndex, modelWar)
    local gridIndex = action.gridIndex
    local modelUnit = getModelUnitMap(modelWar):getModelUnit(gridIndex)

    local actionForPublish = cloneActionForPublish(modelWar, action, playerIndexActing, targetPlayerIndex)
    if (not isUnitVisible(modelWar, gridIndex, modelUnit:getUnitType(), isModelUnitDiving(modelUnit), modelUnit:getPlayerIndex(), targetPlayerIndex)) then
        actionForPublish.gridIndex = nil
    end

    return actionForPublish
end

creators.createForActionDive = function(action, playerIndexActing, targetPlayerIndex, modelWar)
    local beginningGridIndex = action.path.pathNodes[1]
    local modelUnit          = getModelUnitMap(modelWar):getModelUnit(beginningGridIndex)

    local actionForPublish   = cloneActionForPublish(modelWar, action, playerIndexActing, targetPlayerIndex)
    if (not isUnitVisible(modelWar, beginningGridIndex, modelUnit:getUnitType(), isModelUnitDiving(modelUnit), modelUnit:getPlayerIndex(), targetPlayerIndex)) then
        actionForPublish.actingUnitsData = generateUnitsDataForPublish(modelWar, modelUnit)
    end

    return actionForPublish
end

creators.createForActionDropModelUnit = function(action, playerIndexActing, targetPlayerIndex, modelWar)
    local beginningGridIndex = action.path.pathNodes[1]
    local modelUnit          = getModelUnitMap(modelWar):getModelUnit(beginningGridIndex)

    local actionForPublish   = cloneActionForPublish(modelWar, action, playerIndexActing, targetPlayerIndex)
    if (not isUnitVisible(modelWar, beginningGridIndex, modelUnit:getUnitType(), isModelUnitDiving(modelUnit), modelUnit:getPlayerIndex(), targetPlayerIndex)) then
        actionForPublish.actingUnitsData = generateUnitsDataForPublish(modelWar, modelUnit)
    end

    return actionForPublish
end

creators.createForActionEndTurn = function(action, playerIndexActing, targetPlayerIndex, modelWar)
    return action
end

creators.createForActionJoinModelUnit = function(action, playerIndexActing, targetPlayerIndex, modelWar)
    local pathNodes          = action.path.pathNodes
    local beginningGridIndex = pathNodes[1]
    local endingGridIndex    = pathNodes[#pathNodes]
    local modelUnitMap       = getModelUnitMap(modelWar)
    local modelUnit          = modelUnitMap:getModelUnit(beginningGridIndex)
    local joiningModelUnit   = modelUnitMap:getModelUnit(endingGridIndex)
    local unitPlayerIndex    = modelUnit:getPlayerIndex()

    local actingUnitsData
    if (not isUnitVisible(modelWar, beginningGridIndex, modelUnit:getUnitType(), isModelUnitDiving(modelUnit), unitPlayerIndex, targetPlayerIndex)) then
        actingUnitsData = TableFunctions.union(actingUnitsData, generateUnitsDataForPublish(modelWar, modelUnit))
    end
    if (not isUnitVisible(modelWar, endingGridIndex, joiningModelUnit:getUnitType(), isModelUnitDiving(joiningModelUnit), unitPlayerIndex, targetPlayerIndex)) then
        actingUnitsData = TableFunctions.union(actingUnitsData, generateUnitsDataForPublish(modelWar, joiningModelUnit))
    end

    local actionForPublish = cloneActionForPublish(modelWar, action, playerIndexActing, targetPlayerIndex)
    actionForPublish.actingUnitsData = actingUnitsData

    return actionForPublish
end

creators.createForActionLaunchFlare = function(action, playerIndexActing, targetPlayerIndex, modelWar)
    local beginningGridIndex = action.path.pathNodes[1]
    local modelUnit          = getModelUnitMap(modelWar):getModelUnit(beginningGridIndex)

    local actionForPublish           = cloneActionForPublish(modelWar, action, playerIndexActing, targetPlayerIndex)
    actionForPublish.actionCode      = ACTION_CODES.ActionWait
    actionForPublish.targetGridIndex = nil
    if (not isUnitVisible(modelWar, beginningGridIndex, modelUnit:getUnitType(), isModelUnitDiving(modelUnit), modelUnit:getPlayerIndex(), targetPlayerIndex)) then
        actionForPublish.actingUnitsData = generateUnitsDataForPublish(modelWar, modelUnit)
    end

    return actionForPublish
end

creators.createForActionLaunchSilo = function(action, playerIndexActing, targetPlayerIndex, modelWar)
    local beginningGridIndex = action.path.pathNodes[1]
    local modelUnit          = getModelUnitMap(modelWar):getModelUnit(beginningGridIndex)

    local actionForPublish   = cloneActionForPublish(modelWar, action, playerIndexActing, targetPlayerIndex)
    if (not isUnitVisible(modelWar, beginningGridIndex, modelUnit:getUnitType(), isModelUnitDiving(modelUnit), modelUnit:getPlayerIndex(), targetPlayerIndex)) then
        actionForPublish.actingUnitsData = generateUnitsDataForPublish(modelWar, modelUnit)
    end

    return actionForPublish
end

creators.createForActionLoadModelUnit = function(action, playerIndexActing, targetPlayerIndex, modelWar)
    local pathNodes          = action.path.pathNodes
    local modelUnitMap       = getModelUnitMap(modelWar)
    local endingGridIndex    = pathNodes[#pathNodes]
    local loaderModelUnit    = modelUnitMap:getModelUnit(endingGridIndex)
    local playerIndex        = loaderModelUnit:getPlayerIndex()
    local beginningGridIndex = pathNodes[1]
    local modelUnit          = modelUnitMap:getModelUnit(beginningGridIndex)

    local actingUnitsData
    if (not isUnitVisible(modelWar, beginningGridIndex, modelUnit:getUnitType(), isModelUnitDiving(modelUnit), playerIndex, targetPlayerIndex)) then
        actingUnitsData = TableFunctions.union(actingUnitsData, generateUnitsDataForPublish(modelWar, modelUnit))
    end
    if (not isUnitVisible(modelWar, endingGridIndex, loaderModelUnit:getUnitType(), isModelUnitDiving(loaderModelUnit), playerIndex, targetPlayerIndex)) then
        actingUnitsData = TableFunctions.union(actingUnitsData, generateUnitsDataForPublish(modelWar, loaderModelUnit))
    end

    local actionForPublish = cloneActionForPublish(modelWar, action, playerIndexActing, targetPlayerIndex)
    actionForPublish.actingUnitsData = actingUnitsData

    return actionForPublish
end

creators.createForActionProduceModelUnitOnTile = function(action, playerIndexActing, targetPlayerIndex, modelWar)
    local tiledID  = action.tiledID
    local unitType = getUnitTypeWithTiledId(tiledID)
    if (isUnitVisible(modelWar, action.gridIndex, unitType, unitType == "Submarine", getPlayerIndexWithTiledId(tiledID), targetPlayerIndex)) then
        return cloneActionForPublish(modelWar, action, playerIndexActing, targetPlayerIndex)
    else
        return {
            actionCode = ACTION_CODES.ActionProduceModelUnitOnTile,
            actionID   = action.actionID,
            warID      = action.warID,
            cost       = action.cost,
        }
    end
end

creators.createForActionProduceModelUnitOnUnit = function(action, playerIndexActing, targetPlayerIndex, modelWar)
    local beginningGridIndex = action.path.pathNodes[1]
    local modelUnit          = getModelUnitMap(modelWar):getModelUnit(beginningGridIndex)

    local actionForPublish   = cloneActionForPublish(modelWar, action, playerIndexActing, targetPlayerIndex)
    if (not isUnitVisible(modelWar, beginningGridIndex, modelUnit:getUnitType(), isModelUnitDiving(modelUnit), modelUnit:getPlayerIndex(), targetPlayerIndex)) then
        actionForPublish.actingUnitsData = generateUnitsDataForPublish(modelWar, modelUnit)
    end

    return actionForPublish
end

creators.createForActionResearchPassiveSkill = function(action, playerIndexActing, targetPlayerIndex, modelWar)
    return cloneActionForPublish(modelWar, action, playerIndexActing, targetPlayerIndex)
end

creators.createForActionSupplyModelUnit = function(action, playerIndexActing, targetPlayerIndex, modelWar)
    local beginningGridIndex = action.path.pathNodes[1]
    local modelUnit          = getModelUnitMap(modelWar):getModelUnit(beginningGridIndex)

    local actionForPublish   = cloneActionForPublish(modelWar, action, playerIndexActing, targetPlayerIndex)
    if (not isUnitVisible(modelWar, beginningGridIndex, modelUnit:getUnitType(), isModelUnitDiving(modelUnit), modelUnit:getPlayerIndex(), targetPlayerIndex)) then
        actionForPublish.actingUnitsData = generateUnitsDataForPublish(modelWar, modelUnit)
    end

    return actionForPublish
end

creators.createForActionSurface = function(action, playerIndexActing, targetPlayerIndex, modelWar)
    local beginningGridIndex = action.path.pathNodes[1]
    local modelUnit          = getModelUnitMap(modelWar):getModelUnit(beginningGridIndex)

    local actionForPublish   = cloneActionForPublish(modelWar, action, playerIndexActing, targetPlayerIndex)
    if (not isUnitVisible(modelWar, beginningGridIndex, modelUnit:getUnitType(), isModelUnitDiving(modelUnit), modelUnit:getPlayerIndex(), targetPlayerIndex)) then
        actionForPublish.actingUnitsData = generateUnitsDataForPublish(modelWar, modelUnit)
    end

    return actionForPublish
end

creators.createForActionSurrender = function(action, playerIndexActing, targetPlayerIndex, modelWar)
    return action
end

creators.createForActionVoteForDraw = function(action, playerIndexActing, targetPlayerIndex, modelWar)
    return action
end

creators.createForActionWait = function(action, playerIndexActing, targetPlayerIndex, modelWar)
    local beginningGridIndex = action.path.pathNodes[1]
    local modelUnit          = getModelUnitMap(modelWar):getModelUnit(beginningGridIndex)

    local actionForPublish   = cloneActionForPublish(modelWar, action, playerIndexActing, targetPlayerIndex)
    if (not isUnitVisible(modelWar, beginningGridIndex, modelUnit:getUnitType(), isModelUnitDiving(modelUnit), modelUnit:getPlayerIndex(), targetPlayerIndex)) then
        actionForPublish.actingUnitsData = generateUnitsDataForPublish(modelWar, modelUnit)
    end

    return actionForPublish
end

--------------------------------------------------------------------------------
-- The public functions.
--------------------------------------------------------------------------------
function ActionPublisher.createActionsForPublish(action, modelWar)
    local actionCode        = action.actionCode
    local playerIndexActing = (actionCode == ACTION_CODE_CHAT) and (action.senderPlayerIndex) or (getModelTurnManager(modelWar):getPlayerIndex())
    local generator         = creators["createFor" .. ActionCodeFunctions.getActionName(actionCode)]
    local actionsForPublish = {}
    getModelPlayerManager(modelWar):forEachModelPlayer(function(modelPlayer, playerIndex)
        if ((playerIndex ~= playerIndexActing) and
            (modelPlayer:isAlive()))           then
            actionsForPublish[modelPlayer:getAccount()] = generator(action, playerIndexActing, playerIndex, modelWar)
        end
    end)

    return actionsForPublish
end

return ActionPublisher
