-- Require this library if you see any use for it
-- Library for custom and original dota buildings
-- Custom buildings must have npc_dota_creature BaseClass if you want them hidden in the fog of war
-- Custom building must have "ConsideredHero" "1" in their kv file if you want them to be unaffected by most game-breaking spells.

-- Modifiers mostly used for buildings
LinkLuaModifier("modifier_building_construction", "libraries/buildings.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_building_hide_on_minimap", "libraries/buildings.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_building_health", "libraries/buildings.lua", LUA_MODIFIER_MOTION_NONE)

-- Returns bool; Is this unit a custom building?
function CDOTA_BaseNPC:IsCustomBuilding()
	if self:IsConsideredHero() then
		-- Example how to find custom buildings: through their unit name
		local name = self:GetUnitName()
		if string.find(name, "tower_") or string.find(name, "wall_segment") then
			return true
		end
	end

	return false
end

-- Returns a table; Finds custom buildings within a radius.
function FindCustomBuildingsInRadius(position, radius)
	local candidates = Entities:FindAllByClassnameWithin("npc_dota_creature", position, radius)

	local custom_buildings = {}

	for _,creature in pairs(candidates) do
		if creature:IsCustomBuilding() then
			table.insert(custom_buildings, creature)
		end
	end

	return custom_buildings
end

-- Returns a table; Finds DOTA buildings within a radius.
function FindAllBuildingsInRadius(position, radius)
	return FindUnitsInRadius(DOTA_TEAM_NEUTRALS, position, nil, radius, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_BUILDING, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)
end

-- Returns void; Check and fix units that have been assigned a position inside a building (custom or not)
function PreventGettingStuck(building, position)
	local radius = building:GetHullRadius()

	if building:IsBuilding() or building.GetInvulnCount then
		ResolveNPCPositions(position, radius)
	elseif building:IsCustomBuilding() then
		local target_type = bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC)
		local target_flags = bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_INVULNERABLE)
		local units = FindUnitsInRadius(DOTA_TEAM_NEUTRALS, position, nil, radius, DOTA_UNIT_TARGET_TEAM_BOTH, target_type, target_flags, FIND_ANY_ORDER, false)
		for _,unit in pairs(units) do
			if not unit:IsCustomBuilding() then
				unit:AddNewModifier(unit, nil, "modifier_phased", {duration=0.03}) -- unit will insta unstuck after this built-in modifier expires.
			end
		end
	else
		--building is not a custom or original dota building
		print("PreventGettingStuck function has an invalid first argument.")
	end
end

-- Modifier for handling construction
-- Expects its parent ability to have "health", "construction_time", "sink_height", and "think_interval" special values
-- Defaults to not making the building rise from the ground if no "sink_height" is set
-- Defaults to "think_interval" of 0.1
if modifier_building_construction == nil then
	modifier_building_construction = class({})
end

function modifier_building_construction:IsHidden()
	return true
end

function modifier_building_construction:IsPurgable()
	return false
end

if IsServer() then
	function modifier_building_construction:OnCreated()
		local parent = self:GetParent()
		local ability = self:GetAbility()
		parent:AddNewModifier(parent, ability, "modifier_building_health", {})
		self.constructionTime = ability:GetSpecialValueFor("construction_time")
		self.maxHealth = ability:GetSpecialValueFor("health")
		self.initialSinkHeight = ability:GetSpecialValueFor("sink_height")
		self.thinkInterval = ability:GetSpecialValueFor("think_interval")
		if self.thinkInterval == 0 then
			self.thinkInterval = 0.1
		end

		local origin = parent:GetOrigin()
		parent:SetAbsOrigin(Vector(origin.x, origin.y, origin.z-self.initialSinkHeight))

		PreventGettingStuck(parent, origin)

		parent:SetHealth(self.maxHealth*0.01)

		self.totalTicks = math.floor(self.constructionTime / self.thinkInterval)
		self.ticksRemaining = self.totalTicks
		self:StartIntervalThink(self.thinkInterval)
	end

	function modifier_building_construction:OnIntervalThink()
		if self.ticksRemaining <= 0 then
			self:StartIntervalThink(-1)
			self:Destroy()
			return
		end

		local parent = self:GetParent()
		local origin = parent:GetOrigin()
		parent:SetAbsOrigin(Vector(origin.x, origin.y, origin.z+self.initialSinkHeight / self.totalTicks))

		PreventGettingStuck(parent, origin)

		self.ticksRemaining = self.ticksRemaining - 1
	end
end

function modifier_building_construction:CheckState()
	return {
		[MODIFIER_STATE_DISARMED] = true,
		[MODIFIER_STATE_BLIND] = true,
		[MODIFIER_STATE_FROZEN] = true -- Freeze animation to prevent choppiness as calling SetOrigin resets the animation
	}
end

function modifier_building_construction:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
	}
end

function modifier_building_construction:GetModifierConstantHealthRegen()
	if IsServer() then
		return self.maxHealth * 0.99 / self.constructionTime
	end
end

-- Modifier for building health
if modifier_building_health == nil then
	modifier_building_health = class({})
end

function modifier_building_health:IsHidden()
	return true
end

function modifier_building_health:IsPurgable()
	return false
end

if IsServer() then
	function modifier_building_health:OnCreated()
		local parent = self:GetParent()
		local ability = self:GetAbility()
		self.initialMaxHealth = parent:GetMaxHealth()
		self.maxHealth = ability:GetSpecialValueFor("health")
	end
end

function modifier_building_health:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS
	}
end

function modifier_building_health:GetModifierExtraHealthBonus()
	if self.maxHealth == 0 then
		return 0
	else
		return self.maxHealth - self.initialMaxHealth
	end
end

-- Modifier for hiding buildings on the minimap entirely (even from allies)
if modifier_building_hide_on_minimap == nil then
	modifier_building_hide_on_minimap = class({})
end

function modifier_building_hide_on_minimap:IsHidden()
	return true
end

function modifier_building_hide_on_minimap:IsDebuff()
	return false
end

function modifier_building_hide_on_minimap:IsPurgable()
	return false
end

function modifier_building_hide_on_minimap:CheckState()
	return {
		[MODIFIER_STATE_NOT_ON_MINIMAP] = true,
	}
end

