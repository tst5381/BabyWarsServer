
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
-- The private functions that create actions for publish.
--------------------------------------------------------------------------------
local creators = {}
creators.createActionForProduceModelUnitOnTile = function(action, playerIndex)
    -- 生产了新部队后，生产者自己可能会发现隐藏的敌方部队，但这对生产者以外的玩家都是不可知的，因此广播的action必须删除这些数据。
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
