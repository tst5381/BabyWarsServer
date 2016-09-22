
--[[--------------------------------------------------------------------------------
-- ModelSceneWar是战局场景，同时也是游戏中最重要的场景。
--
-- 主要职责和使用场景举例：
--   维护战局中的所有信息
--
-- 其他：
--  - ModelSceneWar功能很多，因此分成多个不同的子actor来共同工作。目前这些子actor包括：
--    - SceneWarHUD
--    - WarField
--    - PlayerManager
--    - TurnManager
--    - WeatherManager
--
--  - ModelSceneWar要正确处理服务器传来的事件消息。目前，是使用doActionXXX系列函数来处理的。
--    由于ModelSceneWar本身是由许多子actor组成，所以这些系列函数通常只是把服务器事件分发给合适的子actor再行处理。
--
--  - model和view的“时间差”
--    在目前的设计中，一旦收到事件，model将即时完成所有相关计算，而view将随后跨帧显示相应效果。
--    考虑服务器传来“某unit A按某路线移动后对unit B发起攻击”的事件的情况。这种情况下，在model中，unit的新的数值将马上完成结算（如hp，弹药量，消灭与否，等级等都会有更新），
--    但在view不可能立刻按model的新状态进行呈现（否则，玩家就会看到unit发生了瞬移，或是突然消失了），而必须跨帧逐步更新。
--    采取model先行结算的方式可以避免很多问题，所以后续开发应该遵守同样的规范。
--
--  - 目前，ModelSceneWar还简单地模拟把玩家操作（也就是EvtPlayerRequestDoAction）传送到服务器，再接收服务器传回的操作（EvtSystemRequestDoAction）的过程（参见ActionTranslator）。
--    这本不应该是ModelSceneWar的工作，等以后实现了网络模块，就应该把相关代码移除。
--]]--------------------------------------------------------------------------------

local ModelSceneWar = require("src.global.functions.class")("ModelSceneWar")

local ActionExecutor       = require("src.app.utilities.ActionExecutor")
local Destroyers           = require("src.app.utilities.Destroyers")
local InstantSkillExecutor = require("src.app.utilities.InstantSkillExecutor")
local Actor                = require("src.global.actors.Actor")
local EventDispatcher      = require("src.global.events.EventDispatcher")

local IS_SERVER = require("src.app.utilities.GameConstantFunctions").isServer()

--------------------------------------------------------------------------------
-- The util functions.
--------------------------------------------------------------------------------
local function getAliveModelUnitsCount(modelUnitMap, playerIndex)
    local count = 0
    modelUnitMap:forEachModelUnitOnMap(function(modelUnit)
        if (modelUnit:getPlayerIndex() == playerIndex) then
            count = count + 1
        end
    end)

    return count
end

--------------------------------------------------------------------------------
-- The functions that do the actions the system requested.
--------------------------------------------------------------------------------
local function doActionAttack(self, action)
    local modelUnitMap        = self:getModelWarField():getModelUnitMap()
    local attackerPlayerIndex = modelUnitMap:getModelUnit(action.path[1]):getPlayerIndex()
    local targetModelUnit     = modelUnitMap:getModelUnit(action.targetGridIndex)
    local targetPlayerIndex   = (targetModelUnit) and (targetModelUnit:getPlayerIndex()) or (nil)

    self:getModelWarField():doActionAttack(action)

    if (getAliveModelUnitsCount(modelUnitMap, attackerPlayerIndex) == 0) then
        Destroyers.destroyPlayerForce(self:getFileName(), attackerPlayerIndex)
        self:getModelTurnManager():endTurn()
    elseif ((targetPlayerIndex) and (getAliveModelUnitsCount(modelUnitMap, targetPlayerIndex) == 0)) then
        Destroyers.destroyPlayerForce(self:getFileName(), targetPlayerIndex)
    end

    if (self:getModelPlayerManager():getAlivePlayersCount() <= 1) then
        self.m_IsWarEnded = true
    end
end

local function doActionCaptureModelTile(self, action)
    local modelWarField     = self:getModelWarField()
    local targetModelTile   = modelWarField:getModelTileMap():getModelTile(action.path[#action.path])
    local targetPlayerIndex = targetModelTile:getPlayerIndex()
    local isDefeatOnCapture = targetModelTile:isDefeatOnCapture()

    modelWarField:doActionCaptureModelTile(action)

    if ((isDefeatOnCapture) and (targetModelTile:getPlayerIndex() ~= targetPlayerIndex)) then
        Destroyers.destroyPlayerForce(self:getFileName(), targetPlayerIndex)
        if (self:getModelPlayerManager():getAlivePlayersCount() <= 1) then
            self.m_IsWarEnded = true
        end
    end
end

--------------------------------------------------------------------------------
-- The composition elements.
--------------------------------------------------------------------------------
local function initScriptEventDispatcher(self)
    local dispatcher = EventDispatcher:create()

    self.m_ScriptEventDispatcher = dispatcher
end

local function initActorPlayerManager(self, playersData)
    local actor = Actor.createWithModelAndViewName("sceneWar.ModelPlayerManager", playersData)

    self.m_ActorPlayerManager = actor
end

local function initActorWeatherManager(self, weatherData)
    local actor = Actor.createWithModelAndViewName("sceneWar.ModelWeatherManager", weatherData)

    self.m_ActorWeatherManager = actor
end

local function initActorWarField(self, warFieldData)
    local actor = Actor.createWithModelAndViewName("sceneWar.ModelWarField", warFieldData)

    self.m_ActorWarField = actor
end

local function initActorTurnManager(self, turnData)
    local actor = Actor.createWithModelAndViewName("sceneWar.ModelTurnManager", turnData)

    self.m_ActorTurnManager = actor
end

--------------------------------------------------------------------------------
-- The constructor and initializers.
--------------------------------------------------------------------------------
function ModelSceneWar:ctor(sceneData)
    self.m_FileName       = sceneData.fileName
    self.m_WarPassword    = sceneData.warPassword
    self.m_IsWarEnded     = sceneData.isEnded
    self.m_ActionID       = sceneData.actionID
    self.m_MaxSkillPoints = sceneData.maxSkillPoints

    initScriptEventDispatcher(self)
    initActorPlayerManager(   self, sceneData.players)
    initActorWeatherManager(  self, sceneData.weather)
    initActorWarField(        self, sceneData.warField)
    initActorTurnManager(     self, sceneData.turn)

    return self
end

--------------------------------------------------------------------------------
-- The functions for serialization.
--------------------------------------------------------------------------------
function ModelSceneWar:toSerializableTable()
    return {
        fileName       = self.m_FileName,
        warPassword    = self.m_WarPassword,
        isEnded        = self.m_IsWarEnded,
        actionID       = self.m_ActionID,
        maxSkillPoints = self.m_MaxSkillPoints,
        warField       = self:getModelWarField()      :toSerializableTable(),
        turn           = self:getModelTurnManager()   :toSerializableTable(),
        players        = self:getModelPlayerManager() :toSerializableTable(),
        weather        = self:getModelWeatherManager():toSerializableTable(),
    }
end

--------------------------------------------------------------------------------
-- The callback functions on start/stop running and script events.
--------------------------------------------------------------------------------
function ModelSceneWar:onStartRunning()
    local sceneWarFileName = self:getFileName()
    self:getModelTurnManager()  :onStartRunning(sceneWarFileName)
    self:getModelPlayerManager():onStartRunning(sceneWarFileName)
    self:getModelWarField()     :onStartRunning(sceneWarFileName)

    self:getScriptEventDispatcher():dispatchEvent({
            name         = "EvtModelWeatherUpdated",
            modelWeather = self:getModelWeatherManager():getCurrentWeather()
        })
        :dispatchEvent({
            name = "EvtSceneWarStarted",
        })
        :dispatchEvent({
            name        = "EvtPlayerIndexUpdated",
            playerIndex = playerIndex,
            modelPlayer = self:getModelPlayerManager():getModelPlayer(playerIndex),
        })

    self:getModelTurnManager():runTurn()

    return self
end

function ModelSceneWar:onStopRunning()
    return self
end

--------------------------------------------------------------------------------
-- The public functions.
--------------------------------------------------------------------------------
function ModelSceneWar:doSystemAction(action)
    local actionName = action.actionName
    if ((actionName == "ActivateSkillGroup")     or
        (actionName == "BeginTurn")              or
        (actionName == "BuildModelTile")         or
        (actionName == "DropModelUnit")          or
        (actionName == "EndTurn")                or
        (actionName == "JoinModelUnit")          or
        (actionName == "LaunchSilo")             or
        (actionName == "LoadModelUnit")          or
        (actionName == "ProduceModelUnitOnTile") or
        (actionName == "ProduceModelUnitOnUnit") or
        (actionName == "SupplyModelUnit")        or
        (actionName == "Surrender")              or
        (actionName == "Wait"))                  then
        ActionExecutor.execute(action)
        return self
    end

    assert(self.m_ActionID + 1 == action.actionID)
    self.m_ActionID = action.actionID

    if     (actionName == "Attack")                 then doActionAttack(                self, action)
    elseif (actionName == "CaptureModelTile")       then doActionCaptureModelTile(      self, action)
    else                                                 error("ModelSceneWar:doSystemAction() unrecognized action.")
    end

    return self
end

function ModelSceneWar:getFileName()
    return self.m_FileName
end

function ModelSceneWar:isEnded()
    return self.m_IsWarEnded
end

function ModelSceneWar:setEnded(ended)
    self.m_IsWarEnded = ended

    return self
end

function ModelSceneWar:getActionId()
    return self.m_ActionID
end

function ModelSceneWar:setActionId(actionID)
    self.m_ActionID = actionID

    return self
end

function ModelSceneWar:getModelTurnManager()
    return self.m_ActorTurnManager:getModel()
end

function ModelSceneWar:getModelPlayerManager()
    return self.m_ActorPlayerManager:getModel()
end

function ModelSceneWar:getModelWeatherManager()
    return self.m_ActorWeatherManager:getModel()
end

function ModelSceneWar:getModelWarField()
    return self.m_ActorWarField:getModel()
end

function ModelSceneWar:getScriptEventDispatcher()
    return self.m_ScriptEventDispatcher
end

function ModelSceneWar:showEffectSurrender(callback)
    assert(not IS_SERVER, "ModelSceneWar:showEffectSurrender() should not be invoked on the server.")
    self.m_View:showEffectSurrender(callback)

    return self
end

function ModelSceneWar:showEffectWin(callback)
    assert(not IS_SERVER, "ModelSceneWar:showEffectWin() should not be invoked on the server.")
    self.m_View:showEffectWin(callback)

    return self
end

return ModelSceneWar
