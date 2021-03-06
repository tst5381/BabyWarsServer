
--[[--------------------------------------------------------------------------------
-- GridIndexable是ModelUnit/ModelTile可用的组件。只有绑定了本组件，宿主才具有“在地图上的坐标”的属性。
-- 主要职责：
--   维护相关数值并提供必要接口给外界访问
-- 使用场景举例：
--   宿主初始化时，根据自身属性来绑定和初始化本组件（所有ModelUnit/ModelTile都需要绑定，但具体由GameConstant决定）
--   移动、攻击、占领等绝大多数单位操作都会用到本组件
-- 其他：
--   GridIndex即坐标（实在想不到名字），其中的x和y都应当是整数
--   - 游戏中，一个格子上最多只能有一个ModelUnit和一个ModelTile。代码利用了这一点，使用GridIndex对unit和tile进行快速索引
--     此外，客户端发送给服务器的操作消息也都用GridIndex来指代特定的unit或tile
--]]--------------------------------------------------------------------------------

local GridIndexable = requireFW("src.global.functions.class")("GridIndexable")

local ComponentManager   = requireFW("src.global.components.ComponentManager")
local GridIndexFunctions = requireFW("src.app.utilities.GridIndexFunctions")

GridIndexable.EXPORTED_METHODS = {
    "getGridIndex",
    "setGridIndex",
    "setViewPositionWithGridIndex"
}

--------------------------------------------------------------------------------
-- The constructor and initializers.
--------------------------------------------------------------------------------
function GridIndexable:ctor(param)
    self.m_GridIndex = {x = 0, y = 0}
    self:loadInstantialData(param.instantialData)

    return self
end

function GridIndexable:loadInstantialData(data)
    local gridIndex = self.m_GridIndex
    gridIndex.x = data.x or gridIndex.x
    gridIndex.y = data.y or gridIndex.y

    return self
end

--------------------------------------------------------------------------------
-- The function for serialization.
--------------------------------------------------------------------------------
function GridIndexable:toSerializableTable()
    return {
        x = self.m_GridIndex.x,
        y = self.m_GridIndex.y,
    }
end

function GridIndexable:toSerializableTableWithFog()
    return self:toSerializableTable()
end

--------------------------------------------------------------------------------
-- The exported functions.
--------------------------------------------------------------------------------
function GridIndexable:getGridIndex()
    return self.m_GridIndex
end

function GridIndexable:setGridIndex(gridIndex, shouldMoveView)
    self.m_GridIndex.x, self.m_GridIndex.y = gridIndex.x, gridIndex.y

    if (shouldMoveView ~= false) then
        self:setViewPositionWithGridIndex(self.m_GridIndex)
    end

    return self.m_Owner
end

-- The param gridIndex may be nil. If so, the function set the position of view with self.m_GridIndex .
function GridIndexable:setViewPositionWithGridIndex(gridIndex)
    local view = self.m_Owner and self.m_Owner.m_View or nil
    if (view) then
        view:setPosition(GridIndexFunctions.toPosition(gridIndex or self.m_GridIndex))
    end

    return self.m_Owner
end

return GridIndexable
