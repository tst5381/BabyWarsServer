
--[[--------------------------------------------------------------------------------
-- ModelUnitMapForOnline是战场上的ModelUnit组成的矩阵，类似于ModelTileMap与ModelTile的关系。
--
-- 主要职责和使用场景举例：
--   构造unit矩阵，维护相关数值，提供接口给外界访问
--
-- 其他：
--   - ModelUnitMapForOnline的数据文件
--     与ModelTileMap不同，对于ModelUnitMapForOnline而言，数据文件中的“模板”的用处相对较小。
--     这是因为所有种类的ModelUnit都具有“非模板”的属性，所以即使使用了模板，数据文件也还是要配上大量的instantialData才能描述整个ModelUnitMapForOnline。
--     但模板也并非完全无用。考虑某些地图一开始就已经为对战各方配置了满状态的unit，那么这时候，模板就可以派上用场了。
--
--     综上，ModelUnitMapForOnline在构造还是会读入模板数据，但保存为数据文件时时就不保留模板数据了，而只保存instantialData。
--
--   - ModelUnitMapForOnline中，其他的许多概念都和ModelTileMap很相似，直接参照ModelTileMap即可。
--]]--------------------------------------------------------------------------------

local ModelUnitMapForOnline = requireFW("src.global.functions.class")("ModelUnitMapForOnline")

local Destroyers             = requireFW("src.app.utilities.Destroyers")
local GridIndexFunctions     = requireFW("src.app.utilities.GridIndexFunctions")
local VisibilityFunctions    = requireFW("src.app.utilities.VisibilityFunctions")
local WarFieldManager        = requireFW("src.app.utilities.WarFieldManager")
local Actor                  = requireFW("src.global.actors.Actor")

local isUnitOnMapVisibleToPlayerIndex = VisibilityFunctions.isUnitOnMapVisibleToPlayerIndex

--------------------------------------------------------------------------------
-- The util functions.
--------------------------------------------------------------------------------
local function getActorUnit(self, gridIndex)
    assert(GridIndexFunctions.isWithinMap(gridIndex, self:getMapSize()),
        "ModelUnitMapForOnline-getActorUnit() the param gridIndex is not within the map.")

    return self.m_ActorUnitsMap[gridIndex.x][gridIndex.y]
end

local function getActorUnitLoaded(self, unitID)
    return self.m_LoadedActorUnits[unitID]
end

local function createEmptyMap(width)
    local map = {}
    for x = 1, width do
        map[x] = {}
    end

    return map
end

local function createActorUnit(tiledID, unitID, x, y)
    local actorData = {
        tiledID       = tiledID,
        unitID        = unitID,
        GridIndexable = {x = x, y = y},
    }

    return Actor.createWithModelAndViewName("warOnline.ModelUnitForOnline", actorData, "common.ViewUnit")
end

--------------------------------------------------------------------------------
-- The unit actors map.
--------------------------------------------------------------------------------
local function createActorUnitsMapWithWarFieldFileName(warFieldFileName)
    local layer               = WarFieldManager.getWarFieldData(warFieldFileName).layers[3]
    local data, width, height = layer.data, layer.width, layer.height
    local actorUnitsMap       = createEmptyMap(width)
    local availableUnitID     = 1

    for x = 1, width do
        for y = 1, height do
            local tiledID = data[x + (height - y) * width]
            if (tiledID > 0) then
                actorUnitsMap[x][y] = createActorUnit(tiledID, availableUnitID, x, y)
                availableUnitID     = availableUnitID + 1
            end
        end
    end

    return actorUnitsMap, {width = width, height = height}, availableUnitID, {}
end

local function createActorUnitsMapWithUnitMapData(unitMapData, warFieldFileName)
    local layer         = WarFieldManager.getWarFieldData(warFieldFileName).layers[3]
    local width, height = layer.width, layer.height
    local mapSize       = {width = width, height = height}

    local actorUnitsMap = createEmptyMap(width)
    for _, unitData in pairs(unitMapData.unitsOnMap) do
        local gridIndex = unitData.GridIndexable
        assert(GridIndexFunctions.isWithinMap(gridIndex, mapSize), "ModelUnitMapForOnline-createActorUnitsMapWithUnitMapData() the gridIndex is invalid.")

        actorUnitsMap[gridIndex.x][gridIndex.y] = Actor.createWithModelAndViewName("warOnline.ModelUnitForOnline", unitData, "common.ViewUnit")
    end

    local loadedActorUnits = {}
    for unitID, unitData in pairs(unitMapData.unitsLoaded or {}) do
        loadedActorUnits[unitID] = Actor.createWithModelAndViewName("warOnline.ModelUnitForOnline", unitData, "common.ViewUnit")
    end

    return actorUnitsMap, mapSize, unitMapData.availableUnitID, loadedActorUnits
end

--------------------------------------------------------------------------------
-- The constructor and initializers.
--------------------------------------------------------------------------------
function ModelUnitMapForOnline:ctor(unitMapData, warFieldFileName)
    if (unitMapData) then
        self.m_ActorUnitsMap, self.m_MapSize, self.m_AvailableUnitID, self.m_LoadedActorUnits = createActorUnitsMapWithUnitMapData(unitMapData, warFieldFileName)
    else
        self.m_ActorUnitsMap, self.m_MapSize, self.m_AvailableUnitID, self.m_LoadedActorUnits = createActorUnitsMapWithWarFieldFileName(warFieldFileName)
    end

    if (self.m_View) then
        self:initView()
    end

    return self
end

function ModelUnitMapForOnline:initView()
    local view = self.m_View
    assert(view, "ModelUnitMapForOnline:initView() there's no view attached to the owner actor of the model.")

    local mapSize = self:getMapSize()
    view:setMapSize(mapSize)
        :removeAllViewUnits()

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
function ModelUnitMapForOnline:toSerializableTable()
    local unitsOnMap = {}
    self:forEachModelUnitOnMap(function(modelUnit)
        unitsOnMap[modelUnit:getUnitId()] = modelUnit:toSerializableTable()
    end)

    local unitsLoaded = {}
    self:forEachModelUnitLoaded(function(modelUnit)
        unitsLoaded[modelUnit:getUnitId()] = modelUnit:toSerializableTable()
    end)

    return {
        availableUnitID = self.m_AvailableUnitID,
        unitsOnMap      = unitsOnMap,
        unitsLoaded     = unitsLoaded,
    }
end

function ModelUnitMapForOnline:toSerializableTableForPlayerIndex(playerIndex)
    local modelSceneWar           = self.m_ModelSceneWar
    local unitsOnMap, unitsLoaded = {}, {}
    self:forEachModelUnitOnMap(function(modelUnit)
        if (isUnitOnMapVisibleToPlayerIndex(modelSceneWar, modelUnit:getGridIndex(), modelUnit:getUnitType(), (modelUnit.isDiving) and (modelUnit:isDiving()), modelUnit:getPlayerIndex(), playerIndex)) then
            unitsOnMap[modelUnit:getUnitId()] = modelUnit:toSerializableTable()

            for _, loadedModelUnit in pairs(self:getLoadedModelUnitsWithLoader(modelUnit, true) or {}) do
                unitsLoaded[loadedModelUnit:getUnitId()] = loadedModelUnit:toSerializableTable()
            end
        end
    end)

    return {
        availableUnitID = self:getAvailableUnitId(),
        unitsOnMap      = unitsOnMap,
        unitsLoaded     = unitsLoaded,
    }
end

--------------------------------------------------------------------------------
-- The callback functions on start running/script events.
--------------------------------------------------------------------------------
function ModelUnitMapForOnline:onStartRunning(modelSceneWar)
    self.m_ModelSceneWar    = modelSceneWar
    local func = function(modelUnit)
        modelUnit:onStartRunning(modelSceneWar)
    end
    self:forEachModelUnitOnMap( func)
        :forEachModelUnitLoaded(func)

    return self
end

--------------------------------------------------------------------------------
-- The public functions.
--------------------------------------------------------------------------------
function ModelUnitMapForOnline:getMapSize()
    return self.m_MapSize
end

function ModelUnitMapForOnline:getAvailableUnitId()
    return self.m_AvailableUnitID
end

function ModelUnitMapForOnline:setAvailableUnitId(unitID)
    assert((unitID >= 0) and (math.floor(unitID) == unitID), "ModelUnitMapForOnline:setAvailableUnitId() invalid unitID: " .. (unitID or ""))
    self.m_AvailableUnitID = unitID

    return self
end

function ModelUnitMapForOnline:getFocusModelUnit(gridIndex, launchUnitID)
    return (launchUnitID)                                 and
        (self:getLoadedModelUnitWithUnitId(launchUnitID)) or
        (self:getModelUnit(gridIndex))
end

function ModelUnitMapForOnline:getModelUnit(gridIndex)
    local actorUnit = getActorUnit(self, gridIndex)
    return (actorUnit) and (actorUnit:getModel()) or (nil)
end

function ModelUnitMapForOnline:getLoadedModelUnitWithUnitId(unitID)
    local actorUnit = getActorUnitLoaded(self, unitID)
    return (actorUnit) and (actorUnit:getModel()) or (nil)
end

function ModelUnitMapForOnline:getLoadedModelUnitsWithLoader(loaderModelUnit, isRecursive)
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

function ModelUnitMapForOnline:swapActorUnit(gridIndex1, gridIndex2)
    if (GridIndexFunctions.isEqual(gridIndex1, gridIndex2)) then
        return self
    end

    local x1, y1 = gridIndex1.x, gridIndex1.y
    local x2, y2 = gridIndex2.x, gridIndex2.y
    local map    = self.m_ActorUnitsMap
    map[x1][y1], map[x2][y2] = map[x2][y2], map[x1][y1]

    return self
end

function ModelUnitMapForOnline:setActorUnitLoaded(gridIndex)
    local loaded = self.m_LoadedActorUnits
    local map    = self.m_ActorUnitsMap
    local x, y   = gridIndex.x, gridIndex.y
    local unitID = map[x][y]:getModel():getUnitId()
    assert(loaded[unitID] == nil, "ModelUnitMapForOnline:setActorUnitLoaded() the focus unit has been loaded already.")

    loaded[unitID], map[x][y] = map[x][y], loaded[unitID]

    return self
end

function ModelUnitMapForOnline:setActorUnitUnloaded(unitID, gridIndex)
    local loaded = self.m_LoadedActorUnits
    local map    = self.m_ActorUnitsMap
    local x, y   = gridIndex.x, gridIndex.y
    assert(loaded[unitID], "ModelUnitMapForOnline-setActorUnitUnloaded() the focus unit is not loaded.")
    assert(map[x][y] == nil, "ModelUnitMapForOnline-setActorUnitUnloaded() another unit is occupying the destination.")

    loaded[unitID], map[x][y] = map[x][y], loaded[unitID]

    return self
end

function ModelUnitMapForOnline:addActorUnitOnMap(actorUnit)
    local modelUnit = actorUnit:getModel()
    local gridIndex = modelUnit:getGridIndex()
    local x, y      = gridIndex.x, gridIndex.y
    assert(not self.m_ActorUnitsMap[x][y], "ModelUnitMapForOnline:addActorUnitOnMap() there's another unit on the grid: " .. x .. " " .. y)
    self.m_ActorUnitsMap[x][y] = actorUnit

    if (self.m_View) then
        self.m_View:addViewUnit(actorUnit:getView(), modelUnit)
    end

    return self
end

function ModelUnitMapForOnline:removeActorUnitOnMap(gridIndex)
    local x, y = gridIndex.x, gridIndex.y
    assert(self.m_ActorUnitsMap[x][y], "ModelUnitMapForOnline:removeActorUnitOnMap() there's no unit on the grid: " .. x .. " " .. y)
    self.m_ActorUnitsMap[x][y] = nil

    return self
end

function ModelUnitMapForOnline:addActorUnitLoaded(actorUnit)
    local modelUnit = actorUnit:getModel()
    local unitID    = modelUnit:getUnitId()
    assert(self.m_LoadedActorUnits[unitID] == nil, "ModelUnitMapForOnline:addActorUnitLoaded() the unit id is loaded already: " .. unitID)
    self.m_LoadedActorUnits[unitID] = actorUnit

    if (self.m_View) then
        self.m_View:addViewUnit(actorUnit:getView(), modelUnit)
    end

    return self
end

function ModelUnitMapForOnline:removeActorUnitLoaded(unitID)
    local loadedModelUnit = self:getLoadedModelUnitWithUnitId(unitID)
    assert(loadedModelUnit, "ModelUnitMapForOnline:removeActorUnitLoaded() the unit that the unitID refers to is not loaded: " .. (unitID or ""))
    self.m_LoadedActorUnits[unitID] = nil

    return self
end

function ModelUnitMapForOnline:forEachModelUnitOnMap(func)
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

function ModelUnitMapForOnline:forEachModelUnitLoaded(func)
    for _, actorUnit in pairs(self.m_LoadedActorUnits) do
        func(actorUnit:getModel())
    end

    return self
end

function ModelUnitMapForOnline:setPreviewLaunchUnit(modelUnit, gridIndex)
    if (self.m_View) then
        self.m_View:setPreviewLaunchUnit(modelUnit, gridIndex)
    end

    return self
end

function ModelUnitMapForOnline:setPreviewLaunchUnitVisible(visible)
    if (self.m_View) then
        self.m_View:setPreviewLaunchUnitVisible(visible)
    end

    return self
end

return ModelUnitMapForOnline
