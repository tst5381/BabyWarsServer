
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

--------------------------------------------------------------------------------
-- The util functions.
--------------------------------------------------------------------------------
local function isModelUnitDiving(modelUnit)
    return (modelUnit.isDiving) and (modelUnit:isDiving())
end

--------------------------------------------------------------------------------
-- The private functions that create actions for publish.
--------------------------------------------------------------------------------
local creators = {}
creators.createActionForActivateSkillGroup = function(action, targetPlayerIndex)
    return TableFunctions.clone(action, {"revealedUnits"})
end

creators.createActionForDive = function(action, targetPlayerIndex)
    -- 为简单起见，目前的代码实现会把移动路线完整广播到目标客户端（除非移动前后都对目标玩家不可见）。客户端自行判断在移动过程中是否隐藏该部队。
    -- 这种实现存在被破解作弊的可能。完美防作弊的实现需要对移动路线以及单位的数据也做出适当的删除。
    -- 行动玩家在移动后，可能会发现隐藏的敌方部队revealedUnits。这对于目标玩家不可见，因此广播的action须删除这些数据。

    local sceneWarFileName   = action.fileName
    local path               = action.path
    local beginningGridIndex = path[1]
    local focusModelUnit     = getModelUnitMap(sceneWarFileName):getFocusModelUnit(beginningGridIndex, action.launchUnitID)
    local unitPlayerIndex    = focusModelUnit:getPlayerIndex()

    if (isUnitVisible(sceneWarFileName, beginningGridIndex, false, unitPlayerIndex, targetPlayerIndex)) then
        -- 行动单位在移动前对目标玩家可见，那么不需要传送该单位的数据给客户端。
        -- 移动后，该单位可能会从目标玩家的视野中消失，但服务器无法干涉，只能由客户端自行删除相应内存数据。
        return TableFunctions.clone(action, {"revealedUnits"})
    else
        -- 行动单位在移动前对目标玩家不可见。
        if (not isUnitVisible(sceneWarFileName, path[#path], true, unitPlayerIndex, targetPlayerIndex)) then
            -- 移动后依然不可见，只需要广播一条TickActionId消息即可。
            return {
                actionName = "TickActionId",
                actionID   = action.actionID,
                fileName   = sceneWarFileName,
            }
        else
            -- 移动后可见，那么需要发送行动单位的数据给客户端。
            local actionForPublish = TableFunctions.clone(action, {"revealedUnits"})
            actionForPublish.focusUnitData = focusModelUnit:toSerializableTable()
            return actionForPublish
        end
    end
end

creators.createActionForJoinModelUnit = function(action, targetPlayerIndex)
    -- 为简单起见，目前的代码实现会把移动路线，包括合流的两个部队的数据完整广播到目标客户端（不管对目标玩家是否可见）。客户端自行判断在移动过程中是否隐藏该部队。
    -- 这种实现存在被破解作弊的可能。完美防作弊的实现需要对移动路线以及单位的数据也做出适当的删除，同时需要计算相关结果数据一并传送（如合流收入）。
    -- 行动玩家在移动后，可能会发现隐藏的敌方部队revealedUnits。这对于目标玩家不可见，因此广播的action须删除这些数据。

    local sceneWarFileName    = action.fileName
    local path                = action.path
    local modelUnitMap        = getModelUnitMap(sceneWarFileName)
    local beginningGridIndex  = path[1]
    local endingGridIndex     = path[#path]
    local focusModelUnit      = modelUnitMap:getFocusModelUnit(beginningGridIndex, action.launchUnitID)
    local joiningModelUnit    = modelUnitMap:getModelUnit(endingGridIndex)
    local unitPlayerIndex     = focusModelUnit:getPlayerIndex()

    local actionForPublish = TableFunctions.clone(action, {"revealedUnits"})
    if (not isUnitVisible(sceneWarFileName, beginningGridIndex, isModelUnitDiving(focusModelUnit), unitPlayerIndex, targetPlayerIndex)) then
        actionForPublish.focusUnitData = focusModelUnit:toSerializableTable()
    end
    if (not isUnitVisible(sceneWarFileName, endingGridIndex, isModelUnitDiving(joiningModelUnit), unitPlayerIndex, targetPlayerIndex)) then
        actionForPublish.joiningUnitData = joiningModelUnit:toSerializableTable()
    end
    return actionForPublish
end

creators.createActionForProduceModelUnitOnTile = function(action, playerIndex)
    -- 生产了新部队后，生产者自己可能会发现隐藏的敌方部队revealedUnits，但这对生产者以外的玩家都是不可知的，因此广播的action必须删除这些数据。
    local isDiving        = (getUnitTypeWithTiledId(action.tiledID) == "Submarine")
    local unitPlayerIndex = getPlayerIndexWithTiledId(action.tiledID)
    if (isUnitVisible(action.fileName, action.gridIndex, isDiving, unitPlayerIndex, playerIndex)) then
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
    local path               = action.path
    local beginningGridIndex = path[1]
    local endingGridIndex    = path[#path]
    local modelUnitMap       = getModelUnitMap(sceneWarFileName)
    local focusModelUnit     = modelUnitMap:getFocusModelUnit(beginningGridIndex, action.launchUnitID)
    local unitPlayerIndex    = focusModelUnit:getPlayerIndex()
    local isDiving           = (focusModelUnit.isDiving) and (focusModelUnit:isDiving())

    if (isUnitVisible(sceneWarFileName, beginningGridIndex, isDiving, unitPlayerIndex, targetPlayerIndex)) then
        -- 行动单位在移动前对目标玩家可见，那么不需要传送该单位的数据给客户端。
        -- 移动后，该单位可能会从目标玩家的视野中消失，但服务器无法干涉，只能由客户端自行删除相应内存数据。
        return TableFunctions.clone(action, {"revealedUnits"})
    else
        -- 行动单位在移动前对目标玩家不可见。
        if (isUnitVisible(sceneWarFileName, endingGridIndex, isDiving, unitPlayerIndex, targetPlayerIndex)) then
            -- 移动后可见，那么需要发送行动单位的数据给客户端。
            local actionForPublish = TableFunctions.clone(action, {"revealedUnits"})
            actionForPublish.focusUnitData = focusModelUnit:toSerializableTable()
            return actionForPublish
        else
            -- 移动后依然不可见，那么需要判断接受补给的单位对目标玩家是否可见。
            for _, adjacentGridIndex in pairs(getAdjacentGrids(endingGridIndex, modelUnitMap:getMapSize())) do
                local adjacentModelUnit = modelUnitMap:getModelUnit(adjacentGridIndex)
                if ((adjacentModelUnit)                                                                                                                                and
                    (focusModelUnit:canSupplyModelUnit(adjacentModelUnit))                                                                                             and
                    (isUnitVisible(sceneWarFileName, adjacentGridIndex, isModelUnitDiving(adjacentModelUnit), adjacentModelUnit:getPlayerIndex(), targetPlayerIndex))) then
                    --如果有至少一个可见，那么返回补给action，但隐藏行动单位的数据。
                    return {
                        actionName        = "SupplyModelUnit",
                        actionID          = action.actionID,
                        launchUnitID      = action.launchUnitID,
                        fileName          = sceneWarFileName,
                        supplierGridIndex = endingGridIndex,
                    }
                end
            end

            -- 所有接受补给的单位对目标玩家都不可见，则只广播TickActionId。
            return {
                actionName = "TickActionId",
                actionID   = action.actionID,
                fileName   = sceneWarFileName,
            }
        end
    end
end

creators.createActionForSurface = function(action, targetPlayerIndex)
    -- 为简单起见，目前的代码实现会把移动路线完整广播到目标客户端（除非移动前后都对目标玩家不可见）。客户端自行判断在移动过程中是否隐藏该部队。
    -- 这种实现存在被破解作弊的可能。完美防作弊的实现需要对移动路线以及单位的数据也做出适当的删除。
    -- 行动玩家在移动后，可能会发现隐藏的敌方部队revealedUnits。这对于目标玩家不可见，因此广播的action须删除这些数据。

    local sceneWarFileName   = action.fileName
    local path               = action.path
    local beginningGridIndex = path[1]
    local focusModelUnit     = getModelUnitMap(sceneWarFileName):getFocusModelUnit(beginningGridIndex, action.launchUnitID)
    local unitPlayerIndex    = focusModelUnit:getPlayerIndex()

    if (isUnitVisible(sceneWarFileName, beginningGridIndex, true, unitPlayerIndex, targetPlayerIndex)) then
        -- 行动单位在移动前对目标玩家可见，那么不需要传送该单位的数据给客户端。
        -- 移动后，该单位可能会从目标玩家的视野中消失，但服务器无法干涉，只能由客户端自行删除相应内存数据。
        return TableFunctions.clone(action, {"revealedUnits"})
    else
        -- 行动单位在移动前对目标玩家不可见。
        if (not isUnitVisible(sceneWarFileName, path[#path], false, unitPlayerIndex, targetPlayerIndex)) then
            -- 移动后依然不可见，只需要广播一条TickActionId消息即可。
            return {
                actionName = "TickActionId",
                actionID   = action.actionID,
                fileName   = sceneWarFileName,
            }
        else
            -- 移动后可见，那么需要发送行动单位的数据给客户端。
            local actionForPublish = TableFunctions.clone(action, {"revealedUnits"})
            actionForPublish.focusUnitData = focusModelUnit:toSerializableTable()
            return actionForPublish
        end
    end
end

creators.createActionForWait = function(action, targetPlayerIndex)
    -- 为简单起见，目前的代码实现会把移动路线完整广播到目标客户端（除非移动前后都对目标玩家不可见）。客户端自行判断在移动过程中是否隐藏该部队。
    -- 这种实现存在被破解作弊的可能。完美防作弊的实现需要对移动路线以及单位的数据也做出适当的删除。
    -- 行动玩家在移动后，可能会发现隐藏的敌方部队revealedUnits。这对于目标玩家不可见，因此广播的action须删除这些数据。

    local sceneWarFileName   = action.fileName
    local path               = action.path
    local beginningGridIndex = path[1]
    local focusModelUnit     = getModelUnitMap(sceneWarFileName):getFocusModelUnit(beginningGridIndex, action.launchUnitID)
    local unitPlayerIndex    = focusModelUnit:getPlayerIndex()
    local isDiving           = (focusModelUnit.isDiving) and (focusModelUnit:isDiving())

    if (isUnitVisible(sceneWarFileName, beginningGridIndex, isDiving, unitPlayerIndex, targetPlayerIndex)) then
        -- 行动单位在移动前对目标玩家可见，那么不需要传送该单位的数据给客户端。
        -- 移动后，该单位可能会从目标玩家的视野中消失，但服务器无法干涉，只能由客户端自行删除相应内存数据。
        return TableFunctions.clone(action, {"revealedUnits"})
    else
        -- 行动单位在移动前对目标玩家不可见。
        if (not isUnitVisible(sceneWarFileName, path[#path], isDiving, unitPlayerIndex, targetPlayerIndex)) then
            -- 移动后依然不可见，只需要广播一条TickActionId消息即可。
            return {
                actionName = "TickActionId",
                actionID   = action.actionID,
                fileName   = sceneWarFileName,
            }
        else
            -- 移动后可见，那么需要发送行动单位的数据给客户端。
            local actionForPublish = TableFunctions.clone(action, {"revealedUnits"})
            actionForPublish.focusUnitData = focusModelUnit:toSerializableTable()
            return actionForPublish
        end
    end
end

creators.createActionForOthers = function(action, playerIndex)
    return action
end

--------------------------------------------------------------------------------
-- The public functions.
--------------------------------------------------------------------------------
function ActionPublisher.createActionsForPublish(action)
    local sceneWarFileName   = action.fileName
    local playerIndexInTurn  = getModelTurnManager(sceneWarFileName):getPlayerIndex()
    local modelPlayerManager = getModelPlayerManager(sceneWarFileName)
    local generator          = creators["createActionFor" .. action.actionName] or creators.createActionForOthers

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
