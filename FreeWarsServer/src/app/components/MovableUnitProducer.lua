
local MovableUnitProducer = requireFW("src.global.functions.class")("MovableUnitProducer")

local Producible            = requireFW("src.app.components.Producible")
local GameConstantFunctions = requireFW("src.app.utilities.GameConstantFunctions")
local SingletonGetters      = requireFW("src.app.utilities.SingletonGetters")
local ComponentManager      = requireFW("src.global.components.ComponentManager")

MovableUnitProducer.EXPORTED_METHODS = {
    "getMovableProductionCost",
    "getMovableProductionTiledId",
}

--------------------------------------------------------------------------------
-- The constructor and initializers.
--------------------------------------------------------------------------------
function MovableUnitProducer:ctor(param)
    self:loadTemplate(param.template)

    return self
end

function MovableUnitProducer:loadTemplate(template)
    self.m_Template = template

    return self
end

--------------------------------------------------------------------------------
-- The public callback function on start running.
--------------------------------------------------------------------------------
function MovableUnitProducer:onStartRunning(modelSceneWar)
    self.m_ModelSceneWar = modelSceneWar

    return self
end

--------------------------------------------------------------------------------
-- The exported functions.
--------------------------------------------------------------------------------
function MovableUnitProducer:getMovableProductionCost()
    return Producible.getProductionCostWithTiledId(self:getMovableProductionTiledId(), SingletonGetters.getModelPlayerManager(self.m_ModelSceneWar))
end

function MovableUnitProducer:getMovableProductionTiledId()
    return GameConstantFunctions.getTiledIdWithTileOrUnitName(self.m_Template.targetType, self.m_Owner:getPlayerIndex())
end

return MovableUnitProducer
