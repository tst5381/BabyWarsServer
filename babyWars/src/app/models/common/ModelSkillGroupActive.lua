
local ModelSkillGroupActive = require("src.global.functions.class")("ModelSkillGroupActive")

local GameConstantFunctions = require("src.app.utilities.GameConstantFunctions")
local LocalizationFunctions = require("src.app.utilities.LocalizationFunctions")

local getSkillModifier = GameConstantFunctions.getSkillModifier
local getSkillPoints   = GameConstantFunctions.getSkillPoints
local getLocalizedText = LocalizationFunctions.getLocalizedText

local SLOTS_COUNT                         = GameConstantFunctions.getActiveSkillSlotsCount()
local SKILL_POINTS_PER_ENERGY_REQUIREMENT = GameConstantFunctions.getSkillPointsPerEnergyRequirement()

--------------------------------------------------------------------------------
-- The util functions.
--------------------------------------------------------------------------------
local function getDescriptionForSingleSkill(id, level, points, modifier)
    return string.format("%s  %s: %d  %s: %.2f  %s: %s%%\n%s",
        getLocalizedText(5, id),
        getLocalizedText(3, "Level"),
        level,
        getLocalizedText(3, "SkillPoints"),
        points,
        getLocalizedText(3, "Modifier"),
        (modifier) and ("" .. modifier) or ("--"),
        getLocalizedText(4, id)
    )
end

local function initSlots(self, param)
    local slots = {}
    if ((self.m_IsEnabled) and (param)) then
        for i = 1, SLOTS_COUNT do
            slots[#slots + 1] = param[i]
        end
    end

    self.m_Slots = slots
end

--------------------------------------------------------------------------------
-- The constructor and initializer.
--------------------------------------------------------------------------------
function ModelSkillGroupActive:ctor(param)
    self.m_IsEnabled = (param) and (param.isEnabled) or (false)
    initSlots(self, param)
    self:setEnergyRequirement((param) and (param.energyRequirement) or (0))

    return self
end

--------------------------------------------------------------------------------
-- The functions for serialization.
--------------------------------------------------------------------------------
function ModelSkillGroupActive:toSerializableTable()
    local t = {
        isEnabled         = self.m_IsEnabled         or false,
        energyRequirement = self.m_EnergyRequirement or 0,
    }

    local slots = self.m_Slots
    for i = 1, SLOTS_COUNT do
        local skill = slots[i]
        if (skill) then
            t[#t + 1] = {
                id    = skill.id,
                level = skill.level,
            }
        end
    end

    return t
end

--------------------------------------------------------------------------------
-- The public functions.
--------------------------------------------------------------------------------
function ModelSkillGroupActive:setEnabled(enabled)
    self.m_IsEnabled = enabled
    if (not enabled) then
        self.m_Slots = {}
        self:setEnergyRequirement(0)
    end

    return self
end

function ModelSkillGroupActive:isEnabled()
    return self.m_IsEnabled
end

function ModelSkillGroupActive:isValid()
    if (not self:isEnabled()) then
        return true
    end

    local slots       = self.m_Slots
    local totalPoints = 0
    for i = 1, SLOTS_COUNT do
        local skill = slots[i]
        if (skill) then
            local id = skill.id
            totalPoints = totalPoints + getSkillPoints(id, skill.level)

            for j = i + 1, SLOTS_COUNT do
                if ((slots[j]) and (slots[j].id == id)) then
                    return false
                end
            end
        end
    end

    return totalPoints <= self:getMaxSkillPoints()
end

function ModelSkillGroupActive:setEnergyRequirement(requirement)
    assert((requirement >= 0) and (math.floor(requirement) == requirement))
    self.m_EnergyRequirement = requirement

    return self
end

function ModelSkillGroupActive:getEnergyRequirement()
    return self.m_EnergyRequirement
end

function ModelSkillGroupActive:getSkillPoints()
    local totalPoints = 0
    local slots       = self.m_Slots
    for i = 1, SLOTS_COUNT do
        local skill = slots[i]
        if (skill) then
            totalPoints = totalPoints + getSkillPoints(skill.id, skill.level)
        end
    end

    return totalPoints
end

function ModelSkillGroupActive:getMaxSkillPoints()
    return self:getEnergyRequirement() * SKILL_POINTS_PER_ENERGY_REQUIREMENT
end

function ModelSkillGroupActive:getDescription()
    if (not self:isEnabled()) then
        return string.format("%s : %s", getLocalizedText(3, "ActiveSkill"), getLocalizedText(3, "Disabled"))
    end

    local descriptions = {
        string.format("%s (%s: %.2f  %s: %.2f)\n%s: %d",
            getLocalizedText(3, "ActiveSkill"),
            getLocalizedText(3, "TotalPoints"),       self:getSkillPoints(),
            getLocalizedText(3, "MaxPoints"),         self:getMaxSkillPoints(),
            getLocalizedText(3, "EnergyRequirement"), self:getEnergyRequirement()
        )
    }

    local slots = self.m_Slots
    for i = 1, SLOTS_COUNT do
        local skill = slots[i]
        if (skill) then
            local id, level = skill.id, skill.level
            local modifier  = getSkillModifier(id, level)
            local points    = getSkillPoints(  id, level)
            descriptions[#descriptions + 1] = string.format("%d. %s", i, getDescriptionForSingleSkill(id, level, points, modifier))
        else
            descriptions[#descriptions + 1] = string.format("%d. %s", i, getLocalizedText(3, "None"))
        end
    end

    return table.concat(descriptions, "\n")
end

function ModelSkillGroupActive:setSkill(slotIndex, skillID, skillLevel)
    assert((slotIndex > 0) and (slotIndex <= SLOTS_COUNT) and (slotIndex == math.floor(slotIndex)),
        "ModelSkillGroupActive:setSkill() the param slotIndex is invalid.")

    self.m_Slots[slotIndex] = {
        id    = skillID,
        level = skillLevel,
    }

    return self
end

function ModelSkillGroupActive:clearSkill(slotIndex)
    assert((slotIndex > 0) and (slotIndex <= SLOTS_COUNT) and (slotIndex == math.floor(slotIndex)),
        "ModelSkillGroupActive:clearSkill() the param slotIndex is invalid.")
    self.m_Slots[slotIndex] = nil

    return self
end

function ModelSkillGroupActive:getProductionCostModifier(tiledID)
    local slots    = self.m_Slots
    local modifier = 0

    for i = 1, SLOTS_COUNT do
        local skill = slots[i]
        if ((skill)          and
            (skill.id == 3)) then
            modifier = modifier + getSkillModifier(skill.id, skill.level)
        end
    end

    return modifier
end

function ModelSkillGroupActive:getAttackModifier(attacker, attackerGridIndex, target, targetGridIndex, modelTileMap, modelWeatherManager)
    local slots    = self.m_Slots
    local modifier = 0

    for i = 1, SLOTS_COUNT do
        local skill = slots[i]
        if ((skill)          and
            (skill.id == 1)) then
            modifier = modifier + getSkillModifier(skill.id, skill.level)
        end
    end

    return modifier
end

function ModelSkillGroupActive:getDefenseModifier(attacker, attackerGridIndex, target, targetGridIndex, modelTileMap, modelWeatherManager)
    local slots    = self.m_Slots
    local modifier = 0

    for i = 1, SLOTS_COUNT do
        local skill = slots[i]
        if ((skill)          and
            (skill.id == 2)) then
            modifier = modifier + getSkillModifier(skill.id, skill.level)
        end
    end

    return modifier
end

return ModelSkillGroupActive
