
--[[--------------------------------------------------------------------------------
-- ModelUnitMap是战场上的ModelUnit组成的矩阵，类似于ModelTileMap与ModelTile的关系。
--
-- 主要职责和使用场景举例：
--   构造unit矩阵，维护相关数值，提供接口给外界访问
--
-- 其他：
--   - ModelUnitMap的数据文件
--     与ModelTileMap不同，对于ModelUnitMap而言，数据文件中的“模板”的用处相对较小。
--     这是因为所有种类的ModelUnit都具有“非模板”的属性，所以即使使用了模板，数据文件也还是要配上大量的instantialData才能描述整个ModelUnitMap。
--     但模板也并非完全无用。考虑某些地图一开始就已经为对战各方配置了满状态的unit，那么这时候，模板就可以派上用场了。
--
--     综上，ModelUnitMap在构造还是会读入模板数据，但保存为数据文件时时就不保留模板数据了，而只保存instantialData。
--
--   - ModelUnitMap中，其他的许多概念都和ModelTileMap很相似，直接参照ModelTileMap即可。
--]]--------------------------------------------------------------------------------

local ModelUnitMap = require("src.global.functions.class")("ModelUnitMap")

local Destroyers             = require("src.app.utilities.Destroyers")
local GridIndexFunctions     = require("src.app.utilities.GridIndexFunctions")
local SingletonGetters       = require("src.app.utilities.SingletonGetters")
local SkillModifierFunctions = require("src.app.utilities.SkillModifierFunctions")
local Actor                  = require("src.global.actors.Actor")

local getScriptEventDispatcher = SingletonGetters.getScriptEventDispatcher

local TEMPLATE_WAR_FIELD_PATH = "res.data.templateWarField."

--------------------------------------------------------------------------------
-- The util functions.
--------------------------------------------------------------------------------
local function getActorUnit(self, gridIndex)
    assert(GridIndexFunctions.isWithinMap(gridIndex, self:getMapSize()),
        "ModelUnitMap-getActorUnit() the param gridIndex is not within the map.")

    return self.m_ActorUnitsMap[gridIndex.x][gridIndex.y]
end

local function getActorUnitLoaded(self, unitID)
    return self.m_LoadedActorUnits[unitID]
end

local function getSupplyTargetModelUnits(self, supplier)
    local targets = {}
    for _, gridIndex in pairs(GridIndexFunctions.getAdjacentGrids(supplier:getGridIndex(), self:getMapSize())) do
        local target = self:getModelUnit(gridIndex)
        if ((target) and (supplier:canSupplyModelUnit(target))) then
            targets[#targets + 1] = target
        end
    end

    return targets
end

local function moveActorUnitOnAction(self, action)
    local launchUnitID = action.launchUnitID
    local path         = action.path
    local beginningGridIndex, endingGridIndex = path[1], path[#path]

    if (launchUnitID) then
        self:getModelUnit(beginningGridIndex):doActionLaunchModelUnit(action)
        self:setActorUnitUnloaded(launchUnitID, endingGridIndex)
    else
        self:swapActorUnit(beginningGridIndex, endingGridIndex)
    end
end

local function createEmptyMap(width)
    local map = {}
    for x = 1, width do
        map[x] = {}
    end

    return map
end

local function createActorUnit(tiledID, unitID, gridIndex)
    local actorData = {
        tiledID       = tiledID,
        unitID        = unitID,
        GridIndexable = {gridIndex = gridIndex},
    }

    return Actor.createWithModelAndViewName("sceneWar.ModelUnit", actorData, "sceneWar.ViewUnit", actorData)
end

local function promoteModelUnitOnProduce(self, modelUnit)
    local modelPlayer = SingletonGetters.getModelPlayerManager(self.m_SceneWarFileName):getModelPlayer(modelUnit:getPlayerIndex())
    local modifier = SkillModifierFunctions.getPassivePromotionModifier(modelPlayer:getModelSkillConfiguration())
    if ((modifier > 0) and (modelUnit.setCurrentPromotion)) then
        modelUnit:setCurrentPromotion(modifier)
    end
end

--------------------------------------------------------------------------------
-- The private callback functions on script events.
--------------------------------------------------------------------------------
local function onEvtTurnPhaseResetUnitState(self, event)
    local playerIndex = event.playerIndex
    local func = function(modelUnit)
        if (modelUnit:getPlayerIndex() == playerIndex) then
            modelUnit:setStateIdle()
                :updateView()
        end
    end

    self:forEachModelUnitOnMap( func)
        :forEachModelUnitLoaded(func)
end

local function onEvtTurnPhaseSupplyUnit(self, event)
    local playerIndex = event.playerIndex
    local dispatcher  = SingletonGetters.getScriptEventDispatcher(self.m_SceneWarFileName)

    local dispatchEvtSupplyViewUnit = function(gridIndex)
        dispatcher:dispatchEvent({
            name      = "EvtSupplyViewUnit",
            gridIndex = gridIndex,
        })
    end

    local supply = function(modelUnit)
        local hasSupplied = false
        local maxFuel = modelUnit:getMaxFuel()
        if (modelUnit:getCurrentFuel() < maxFuel) then
            modelUnit:setCurrentFuel(maxFuel)
            hasSupplied = true
        end

        if ((modelUnit.hasPrimaryWeapon) and (modelUnit:hasPrimaryWeapon())) then
            local maxAmmo = modelUnit:getPrimaryWeaponMaxAmmo()
            if (modelUnit:getPrimaryWeaponCurrentAmmo() < maxAmmo) then
                modelUnit:setPrimaryWeaponCurrentAmmo(maxAmmo)
                hasSupplied = true
            end
        end

        if (hasSupplied) then
            modelUnit:updateView()
        end

        return hasSupplied
    end

    local supplyLoadedModelUnits = function(modelUnit)
        if ((modelUnit:getPlayerIndex() == playerIndex) and
            (modelUnit.canSupplyLoadedModelUnit)        and
            (modelUnit:canSupplyLoadedModelUnit())      and
            (not modelUnit:canRepairLoadedModelUnit())) then

            local hasSupplied = false
            for _, unitID in pairs(modelUnit:getLoadUnitIdList()) do
                hasSupplied = supply(self:getLoadedModelUnitWithUnitId(unitID)) or hasSupplied
            end
            if (hasSupplied) then
                dispatchEvtSupplyViewUnit(modelUnit:getGridIndex())
            end
        end
    end

    local supplyAdjacentModelUnits = function(modelUnit)
        if ((modelUnit:getPlayerIndex() == playerIndex) and
            (modelUnit.canSupplyModelUnit))             then

            for _, target in pairs(getSupplyTargetModelUnits(self, modelUnit)) do
                if (supply(target)) then
                    target:updateView()
                    dispatchEvtSupplyViewUnit(target:getGridIndex())
                end
            end
        end
    end

    self:forEachModelUnitOnMap( supplyAdjacentModelUnits)
        :forEachModelUnitOnMap( supplyLoadedModelUnits)
        :forEachModelUnitLoaded(supplyLoadedModelUnits)
end

local function onEvtSkillGroupActivated(self, event)
    if (self.m_View) then
        local playerIndex  = event.playerIndex
        local skillGroupID = event.skillGroupID
        self:forEachModelUnitOnMap(function(modelUnit)
                if (modelUnit:getPlayerIndex() == playerIndex) then
                    modelUnit:setActivatingSkillGroupId(skillGroupID)
                end
            end)
            :forEachModelUnitLoaded(function(modelUnit)
                if (modelUnit:getPlayerIndex() == playerIndex) then
                    modelUnit:setActivatingSkillGroupId(skillGroupID)
                end
            end)
    end
end

--------------------------------------------------------------------------------
-- The unit actors map.
--------------------------------------------------------------------------------
local function createActorUnitsMapWithTemplate(mapData)
    local layer               = require(TEMPLATE_WAR_FIELD_PATH .. mapData.template).layers[3]
    local data, width, height = layer.data, layer.width, layer.height
    local map                 = createEmptyMap(width)
    local availableUnitId     = 1

    for x = 1, width do
        for y = 1, height do
            local tiledID = data[x + (height - y) * width]
            if (tiledID > 0) then
                map[x][y]       = createActorUnit(tiledID, availableUnitId, {x = x, y = y})
                availableUnitId = availableUnitId + 1
            end
        end
    end

    return map, {width = width, height = height}, availableUnitId, {}
end

local function createActorUnitsMapWithoutTemplate(mapData)
    -- If the map is created without template, then we build the map with mapData.grids only.
    local mapSize = mapData.mapSize
    local map     = createEmptyMap(mapSize.width)
    for _, gridData in pairs(mapData.grids) do
        local gridIndex = gridData.GridIndexable.gridIndex
        assert(GridIndexFunctions.isWithinMap(gridIndex, mapSize), "ModelUnitMap-createActorUnitsMapWithoutTemplate() the gridIndex is invalid.")

        map[gridIndex.x][gridIndex.y] = Actor.createWithModelAndViewName("sceneWar.ModelUnit", gridData, "sceneWar.ViewUnit", gridData)
    end

    local loadedActorUnits = {}
    for unitID, unitData in pairs(mapData.loaded or {}) do
        loadedActorUnits[unitID] = Actor.createWithModelAndViewName("sceneWar.ModelUnit", unitData, "sceneWar.ViewUnit", unitData)
    end

    return map, mapSize, mapData.availableUnitId, loadedActorUnits
end

local function initActorUnitsMap(self, mapData)
    if (mapData.template) then
        self.m_ActorUnitsMap, self.m_MapSize, self.m_AvailableUnitID, self.m_LoadedActorUnits = createActorUnitsMapWithTemplate(mapData)
    else
        self.m_ActorUnitsMap, self.m_MapSize, self.m_AvailableUnitID, self.m_LoadedActorUnits = createActorUnitsMapWithoutTemplate(mapData)
    end
end

--------------------------------------------------------------------------------
-- The constructor and initializers.
--------------------------------------------------------------------------------
function ModelUnitMap:ctor(mapData)
    initActorUnitsMap(self, mapData)

    if (self.m_View) then
        self:initView()
    end

    return self
end

function ModelUnitMap:initView()
    local view = self.m_View
    assert(view, "ModelUnitMap:initView() there's no view attached to the owner actor of the model.")

    local mapSize = self:getMapSize()
    view:setMapSize(mapSize)

    local actorUnitsMap = self.m_ActorUnitsMap
    for y = mapSize.height, 1, -1 do
        for x = mapSize.width, 1, -1 do
            local actorUnit = actorUnitsMap[x][y]
            if (actorUnit) then
                view:addViewUnit(actorUnit:getView(), actorUnit:getModel())
            end
        end
    end

    for unitID, actorUnit in pairs(self.m_LoadedActorUnits) do
        view:addViewUnit(actorUnit:getView(), actorUnit:getModel())
    end

    return self
end

--------------------------------------------------------------------------------
-- The function for serialization.
--------------------------------------------------------------------------------
function ModelUnitMap:toSerializableTable()
    local grids = {}
    self:forEachModelUnitOnMap(function(modelUnit)
        grids[modelUnit:getUnitId()] = modelUnit:toSerializableTable()
    end)

    local loaded = {}
    self:forEachModelUnitLoaded(function(modelUnit)
        loaded[modelUnit:getUnitId()] = modelUnit:toSerializableTable()
    end)

    return {
        mapSize         = self:getMapSize(),
        availableUnitId = self.m_AvailableUnitID,
        grids           = grids,
        loaded          = loaded,
    }
end

--------------------------------------------------------------------------------
-- The callback functions on start running/script events.
--------------------------------------------------------------------------------
function ModelUnitMap:onStartRunning(sceneWarFileName)
    self.m_SceneWarFileName = sceneWarFileName
    local func = function(modelUnit)
        modelUnit:onStartRunning(sceneWarFileName)
    end
    self:forEachModelUnitOnMap( func)
        :forEachModelUnitLoaded(func)

    getScriptEventDispatcher(sceneWarFileName)
        :addEventListener("EvtTurnPhaseResetUnitState",  self)
        :addEventListener("EvtTurnPhaseSupplyUnit",      self)
        :addEventListener("EvtSkillGroupActivated",      self)

    return self
end

function ModelUnitMap:onEvent(event)
    local name = event.name
    if     (name == "EvtTurnPhaseResetUnitState")  then onEvtTurnPhaseResetUnitState( self, event)
    elseif (name == "EvtTurnPhaseSupplyUnit")      then onEvtTurnPhaseSupplyUnit(     self, event)
    elseif (name == "EvtSkillGroupActivated")      then onEvtSkillGroupActivated(     self, event)
    end

    return self
end

--------------------------------------------------------------------------------
-- The public functions for doing actions.
--------------------------------------------------------------------------------
function ModelUnitMap:doActionAttack(action, attackTarget, callbackOnAttackAnimationEnded)
    local focusModelUnit = self:getFocusModelUnit(action.path[1], action.launchUnitID)
    focusModelUnit:doActionMoveModelUnit(action, self:getLoadedModelUnitsWithLoader(focusModelUnit, true))
    moveActorUnitOnAction(self, action)
    focusModelUnit:doActionAttack(action, attackTarget, callbackOnAttackAnimationEnded)

    getScriptEventDispatcher(self.m_SceneWarFileName):dispatchEvent({name = "EvtModelUnitMapUpdated"})

    return self
end

function ModelUnitMap:doActionCaptureModelTile(action, target, callbackOnCaptureAnimationEnded)
    local capturer = self:getFocusModelUnit(action.path[1], action.launchUnitID)
    capturer:doActionMoveModelUnit(action, self:getLoadedModelUnitsWithLoader(capturer, true))
    moveActorUnitOnAction(self, action)
    capturer:doActionCaptureModelTile(action, target, callbackOnCaptureAnimationEnded)

    getScriptEventDispatcher(self.m_SceneWarFileName):dispatchEvent({name = "EvtModelUnitMapUpdated"})

    return self
end

--------------------------------------------------------------------------------
-- The public functions.
--------------------------------------------------------------------------------
function ModelUnitMap:getMapSize()
    return self.m_MapSize
end

function ModelUnitMap:getAvailableUnitId()
    return self.m_AvailableUnitID
end

function ModelUnitMap:setAvailableUnitId(unitID)
    assert((unitID >= 0) and (math.floor(unitID) == unitID), "ModelUnitMap:setAvailableUnitId() invalid unitID: " .. (unitID or ""))
    self.m_AvailableUnitID = unitID

    return self
end

function ModelUnitMap:getFocusModelUnit(gridIndex, launchUnitID)
    return (launchUnitID)                                 and
        (self:getLoadedModelUnitWithUnitId(launchUnitID)) or
        (self:getModelUnit(gridIndex))
end

function ModelUnitMap:getModelUnit(gridIndex)
    local actorUnit = getActorUnit(self, gridIndex)
    return (actorUnit) and (actorUnit:getModel()) or (nil)
end

function ModelUnitMap:getLoadedModelUnitWithUnitId(unitID)
    local actorUnit = getActorUnitLoaded(self, unitID)
    return (actorUnit) and (actorUnit:getModel()) or (nil)
end

function ModelUnitMap:getLoadedModelUnitsWithLoader(loaderModelUnit, isRecursive)
    if (not loaderModelUnit.getLoadUnitIdList) then
        return nil
    else
        local list = {}
        for _, unitID in ipairs(loaderModelUnit:getLoadUnitIdList()) do
            list[#list + 1] = self:getLoadedModelUnitWithUnitId(unitID)
        end
        assert(#list == loaderModelUnit:getCurrentLoadCount())

        if (isRecursive) then
            for _, loader in ipairs(list) do
                local subList = self:getLoadedModelUnitsWithLoader(loader, true)
                if (subList) then
                    for _, subItem in ipairs(subList) do
                        list[#list + 1] = subItem
                    end
                end
            end
        end

        return list
    end
end

function ModelUnitMap:swapActorUnit(gridIndex1, gridIndex2)
    if (GridIndexFunctions.isEqual(gridIndex1, gridIndex2)) then
        return
    end

    local x1, y1 = gridIndex1.x, gridIndex1.y
    local x2, y2 = gridIndex2.x, gridIndex2.y
    local map    = self.m_ActorUnitsMap
    map[x1][y1], map[x2][y2] = map[x2][y2], map[x1][y1]

    local view = self.m_View
    if (view) then
        if (map[x1][y1]) then view:adjustViewUnitZOrder(map[x1][y1]:getView(), gridIndex1) end
        if (map[x2][y2]) then view:adjustViewUnitZOrder(map[x2][y2]:getView(), gridIndex2) end
    end
end

function ModelUnitMap:setActorUnitLoaded(gridIndex)
    local loaded = self.m_LoadedActorUnits
    local map    = self.m_ActorUnitsMap
    local x, y   = gridIndex.x, gridIndex.y
    local unitID = map[x][y]:getModel():getUnitId()
    assert(loaded[unitID] == nil, "ModelUnitMap:setActorUnitLoaded() the focus unit has been loaded already.")

    loaded[unitID], map[x][y] = map[x][y], loaded[unitID]

    return self
end

function ModelUnitMap:setActorUnitUnloaded(unitID, gridIndex)
    local loaded = self.m_LoadedActorUnits
    local map    = self.m_ActorUnitsMap
    local x, y   = gridIndex.x, gridIndex.y
    assert(loaded[unitID], "ModelUnitMap-setActorUnitUnloaded() the focus unit is not loaded.")
    assert(map[x][y] == nil, "ModelUnitMap-setActorUnitUnloaded() another unit is occupying the destination.")

    loaded[unitID], map[x][y] = map[x][y], loaded[unitID]

    if (self.m_View) then
        self.m_View:adjustViewUnitZOrder(map[x][y]:getView(), gridIndex)
    end

    return self
end

function ModelUnitMap:addActorUnitOnMap(actorUnit)
    local modelUnit = actorUnit:getModel()
    local gridIndex = modelUnit:getGridIndex()
    self.m_ActorUnitsMap[gridIndex.x][gridIndex.y] = actorUnit

    if (self.m_View) then
        self.m_View:addViewUnit(actorUnit:getView(), modelUnit)
    end

    return self
end

function ModelUnitMap:removeActorUnitOnMap(gridIndex)
    self.m_ActorUnitsMap[gridIndex.x][gridIndex.y] = nil

    return self
end

function ModelUnitMap:addActorUnitLoaded(actorUnit)
    local modelUnit = actorUnit:getModel()
    self.m_LoadedActorUnits[modelUnit:getUnitId()] = actorUnit

    if (self.m_View) then
        self.m_View:addViewUnit(actorUnit:getView(), modelUnit)
    end

    return self
end

function ModelUnitMap:removeActorUnitLoaded(unitID)
    local loadedModelUnit = self:getLoadedModelUnitWithUnitId(unitID)
    assert(loadedModelUnit, "ModelUnitMap:removeActorUnitLoaded() the unit that the unitID refers to is not loaded: " .. (unitID or ""))

    loadedModelUnit:removeViewFromParent()
    self.m_LoadedActorUnits[unitID] = nil

    return self
end

function ModelUnitMap:forEachModelUnitOnMap(func)
    local mapSize = self:getMapSize()
    for x = 1, mapSize.width do
        for y = 1, mapSize.height do
            local actorUnit = self.m_ActorUnitsMap[x][y]
            if (actorUnit) then
                func(actorUnit:getModel())
            end
        end
    end

    return self
end

function ModelUnitMap:forEachModelUnitLoaded(func)
    for _, actorUnit in pairs(self.m_LoadedActorUnits) do
        func(actorUnit:getModel())
    end

    return self
end

function ModelUnitMap:setPreviewLaunchUnit(modelUnit, gridIndex)
    if (self.m_View) then
        self.m_View:setPreviewLaunchUnit(modelUnit, gridIndex)
    end

    return self
end

function ModelUnitMap:setPreviewLaunchUnitVisible(visible)
    if (self.m_View) then
        self.m_View:setPreviewLaunchUnitVisible(visible)
    end

    return self
end

return ModelUnitMap
