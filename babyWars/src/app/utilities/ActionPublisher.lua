
local ActionPublisher = {}

local GameConstantFunctions = require("src.app.utilities.GameConstantFunctions")
local GridIndexFunctions    = require("src.app.utilities.GridIndexFunctions")
local SingletonGetters      = require("src.app.utilities.SingletonGetters")
local TableFunctions        = require("src.app.utilities.TableFunctions")

local getAdjacentGrids       = GridIndexFunctions.getAdjacentGrids
local getModelPlayerManager  = SingletonGetters.getModelPlayerManager
local getModelTileMap        = SingletonGetters.getModelTileMap
local getModelTurnManager    = SingletonGetters.getModelTurnManager
local getModelUnitMap        = SingletonGetters.getModelUnitMap
local getUnitTypeWithTiledId = GameConstantFunctions.getUnitTypeWithTiledId

--------------------------------------------------------------------------------
-- The private functions that create actions for publish.
--------------------------------------------------------------------------------
local creators = {}
creators.createActionForProduceModelUnitOnTile = function(action, playerIndex)
    -- 生产了新部队后，生产者自己可能会发现隐藏的敌方部队，但这对生产者以外的玩家都是不可知的，因此广播的action必须删除这些数据。

    if (getUnitTypeWithTiledId(action.tiledID) ~= "Submarine") then
        -- 生产的部队不是潜艇，因此需要告诉其他玩家生产了什么东西。
        return TableFunctions.clone(action, {"revealedUnits"})
    else
        -- 生产的部队是潜艇，那么对于其他玩家而言，如果他正好有部队能够看到这个潜艇，那么就需要把潜艇数据发送给该敌方玩家。
        local modelUnitMap = getModelUnitMap(action.fileName)
        for _, adjacentGridIndex in ipairs(getAdjacentGrids(action.gridIndex, modelUnitMap:getMapSize())) do
            local modelUnit = modelUnitMap:getModelUnit(adjacentGridIndex)
            if ((modelUnit) and (modelUnit:getPlayerIndex() == playerIndex)) then
                return TableFunctions.clone(action, {"revealedUnits"})
            end
        end

        -- 其他玩家没有部队能够看到潜艇，那么要隐藏潜艇数据。
        return {
            actionName = "ProduceModelUnitOnTile",
            actionID   = action.actionID,
            fileName   = action.fileName,
            cost       = action.cost,
        }
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
