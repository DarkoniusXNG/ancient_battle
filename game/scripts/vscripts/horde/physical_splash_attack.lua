custom_unit_splash_attack = class({})

LinkLuaModifier("modifier_custom_unit_custom_splash_attack", "horde/physical_splash_attack.lua", LUA_MODIFIER_MOTION_NONE)

function custom_unit_splash_attack:GetIntrinsicModifierName()
	return "modifier_custom_unit_custom_splash_attack"
end

function custom_unit_splash_attack:IsStealable()
	return false
end

---------------------------------------------------------------------------------------------------

modifier_custom_unit_custom_splash_attack = class({})

function modifier_custom_unit_custom_splash_attack:IsHidden()
	return true
end

function modifier_custom_unit_custom_splash_attack:IsDebuff()
	return false
end

function modifier_custom_unit_custom_splash_attack:IsPurgable()
	return false
end

function modifier_custom_unit_custom_splash_attack:IsPurgeException()
	return false
end

function modifier_custom_unit_custom_splash_attack:IsStunDebuff()
	return false
end

function modifier_custom_unit_custom_splash_attack:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT
end

function modifier_custom_unit_custom_splash_attack:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end

if IsServer() then
	function modifier_custom_unit_custom_splash_attack:OnAttackLanded(event)
		local parent = self:GetParent()

		if event.attacker ~= parent then
			return
		end

		-- No splash while broken or if its an illusion
		if parent:PassivesDisabled() or parent:IsIllusion() then
			return
		end

		local target = event.target

		-- To prevent crashes:
		if not target or target:IsNull() then
			return
		end

		-- Check for existence of GetUnitName method to determine if target is a unit or an item
		-- items don't have that method -> nil; if the target is an item, don't continue
		if target.GetUnitName == nil then
			return
		end

		-- Don't affect buildings and wards
		if target:IsTower() or target:IsBarracks() or target:IsBuilding() or target:IsOther() then
			return
		end

		local ability = self:GetAbility()
		local target_team = DOTA_UNIT_TARGET_TEAM_ENEMY
		local target_type = bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
		local target_flags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
		local radius = 400
		local damage_percent = 100

		local damage_table = {}
		damage_table.damage_type = DAMAGE_TYPE_PHYSICAL
		damage_table.attacker = parent
		damage_table.damage_flags = bit.bor(DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL)

		if ability then
			target_team = ability:GetAbilityTargetTeam()
			target_type = ability:GetAbilityTargetType()
			target_flags = ability:GetAbilityTargetFlags()
			radius = ability:GetSpecialValueFor("radius")
			damage_percent = ability:GetSpecialValueFor("damage_percent")
			damage_table.damage_type = ability:GetAbilityDamageType()
			damage_table.ability = ability
		end

		local target_location = target:GetAbsOrigin()
		local parent_team = parent:GetTeamNumber()

		-- Find all appropriate targets around the initial target
		local units = FindUnitsInRadius(parent_team, target_location, nil, radius, target_team, target_type, target_flags, FIND_ANY_ORDER, false)
		-- Remove the initial target from the table
		for k, unit in pairs(units) do
			if unit == target then
				table.remove(units, k)
				break
			end
		end

		-- Get parent's damage
		local damage = event.original_damage

		-- Calculate splash damage
		local splash_damage = damage*damage_percent*0.01

		-- Show particle only if damage is above zero and only if there are units nearby
		if splash_damage > 0 and #units > 0 then
			local particle = ParticleManager:CreateParticle( "particles/items/powertreads_splash.vpcf", PATTACH_POINT, target)
			ParticleManager:SetParticleControl(particle, 5, Vector(1, 0, radius))
			ParticleManager:ReleaseParticleIndex(particle)
		end

		-- Apply damage to units
		for k, unit in pairs(units) do
			if unit then
				damage_table.victim = unit
				damage_table.damage = splash_damage
				ApplyDamage(damage_table)
			end
		end
    end
end

---------------------------------------------------------------------------------------------------

custom_phoenix_splash_attack = custom_unit_splash_attack