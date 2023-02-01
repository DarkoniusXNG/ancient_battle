if stealth_assassin_desolate == nil then
	stealth_assassin_desolate = class({})
end

LinkLuaModifier("modifier_stealth_assassin_desolate_passive", "heroes/ryu/desolate.lua", LUA_MODIFIER_MOTION_NONE)

function stealth_assassin_desolate:IsStealable()
	return false
end

function stealth_assassin_desolate:GetIntrinsicModifierName()
	return "modifier_stealth_assassin_desolate_passive"
end

function stealth_assassin_desolate:ProcMagicStick()
	return false
end

---------------------------------------------------------------------------------------------------

modifier_stealth_assassin_desolate_passive = class({})

function modifier_stealth_assassin_desolate_passive:IsHidden()
	return true
end

function modifier_stealth_assassin_desolate_passive:IsDebuff()
	return false
end

function modifier_stealth_assassin_desolate_passive:IsPurgable()
	return false
end

function modifier_stealth_assassin_desolate_passive:RemoveOnDeath()
	return false
end

function modifier_stealth_assassin_desolate_passive:AllowIllusionDuplicate()
	return true
end

function modifier_stealth_assassin_desolate_passive:DeclareFunctions()
	return {
		--MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end

function modifier_stealth_assassin_desolate_passive:GetActivityTranslationModifiers()
	if self:GetParent():GetUnitName() == "npc_dota_hero_riki" then
		return "backstab"
	end
end

if IsServer() then
	function modifier_stealth_assassin_desolate_passive:OnAttackLanded(event)
		local parent = self:GetParent()
		local ability = self:GetAbility()
		local attacker = event.attacker
		local target = event.target

		-- Check if attacker exists
		if not attacker or attacker:IsNull() then
			return
		end

		-- Check if attacker has this modifier
		if attacker ~= parent then
			return
		end

		-- Check if attacked entity exists
		if not target or target:IsNull() then
			return
		end

		-- Check for existence of GetUnitName method to determine if target is a unit or an item
		-- items don't have that method -> nil; if the target is an item, don't continue
		if target.GetUnitName == nil then
			return
		end

		-- Don't affect buildings and wards
		if target:IsTower() or target:IsBarracks() or target:IsBuilding() or target:IsOther() or target:IsCustomWardTypeUnit() then
			return
		end

		-- Don't continue if parent is affected with 'break'
		if parent:PassivesDisabled() then
			return
		end

		-- Check if ability exists
		if not ability or ability:IsNull() then
			return
		end

		-- Backstab KVs
		local max_angle = ability:GetSpecialValueFor("backstab_max_angle")
		local backstab_multiplier = ability:GetSpecialValueFor("backstab_agi_multiplier")

		-- Desolate KVs
		local radius = ability:GetSpecialValueFor("desolate_radius")
		local desolate_multiplier = ability:GetSpecialValueFor("desolate_agi_multiplier")

		-- Derived variables
		local agility = parent:GetAgility()
		local target_location = target:GetAbsOrigin()

		-- Damage table constants
		local damage_table = {}
		damage_table.attacker = parent
		damage_table.damage_type = ability:GetAbilityDamageType()
		damage_table.ability = ability
		damage_table.victim = target
		damage_table.damage_flags = bit.bor(DOTA_DAMAGE_FLAG_BYPASSES_BLOCK, DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL)

		-- Backstab check
		------------------------------------------------------------------------------------------ 
		local backstab_proc = false

		-- The y value of the angles vector contains the angle we actually want: where units are directionally facing in the world.
		local victim_angle = target:GetAnglesAsVector().y
		local origin_difference = target_location - parent:GetAbsOrigin()

		-- Get the radian of the origin difference between the attacker and target. We use this to figure out at what angle the attacker is at relative to the target.
		local origin_difference_radian = math.atan2(origin_difference.y, origin_difference.x)

		-- Convert the radian to degrees.
		origin_difference_radian = origin_difference_radian * 180
		local attacker_angle = origin_difference_radian / math.pi

		-- it's to turn negative angles into positive ones and make the math simpler. (+30?)
		attacker_angle = attacker_angle + 180.0

		-- Finally, get the angle at which target is facing the attacker.
		local result_angle = attacker_angle - victim_angle
		result_angle = math.abs(result_angle)

		-- Check for back angle
		if result_angle >= (180 - (max_angle / 2)) and result_angle <= (180 + (max_angle / 2)) then
			backstab_proc = true
		end
		-------------------------------------------------------------------------------------------

		-- Desolate check
		-------------------------------------------------------------------------------------------
		local desolate_proc = false

		-- Targetting constants
		local target_team = DOTA_UNIT_TARGET_TEAM_FRIENDLY
		local target_type = bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
		local target_flags = DOTA_UNIT_TARGET_FLAG_NONE

		-- Finding target's allies in a radius
		local candidates = FindUnitsInRadius(target:GetTeamNumber(), target_location, nil, radius, target_team, target_type, target_flags, FIND_ANY_ORDER, false)

		-- Count the number of target's allies around the target hero or unit (excluding invalid units and the target itself)
		local number_of_nearby_enemies = 0
		for _, unit in pairs(candidates) do
			if unit and not unit:IsNull() and not unit:IsCustomWardTypeUnit() and unit ~= target then
				number_of_nearby_enemies = number_of_nearby_enemies + 1
			end
		end

		if number_of_nearby_enemies < 1 then
			desolate_proc = true
		end
		-------------------------------------------------------------------------------------------

		local backstab_dmg = 0
		local desolate_dmg = 0
		if backstab_proc then
			-- Particle
			local particle_name = "particles/units/heroes/hero_riki/riki_backstab.vpcf"
			local particle = ParticleManager:CreateParticle(particle_name, PATTACH_ABSORIGIN_FOLLOW, target)
			ParticleManager:SetParticleControlEnt(particle, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target_location, true)
			ParticleManager:ReleaseParticleIndex(particle)

			--Timers:CreateTimer(1.0, function()
				--ParticleManager:DestroyParticle(particle, false)
				--ParticleManager:ReleaseParticleIndex(particle)
			--end)

			-- Sound
			caster:EmitSound("Hero_Riki.Backstab")

			-- Calculate backstab damage
			backstab_dmg = math.ceil(agility*backstab_multiplier)
		end
		if desolate_proc then
			-- Particle

			-- Sound

			-- Calculate desolate damage
			desolate_dmg = math.ceil(agility*desolate_multiplier)
		end

		-- Calculate total damage
		local total_damage = backstab_dmg + desolate_dmg

		-- Applying the damage
		if total_damage > 0 then
			damage_table.damage = total_damage
			ApplyDamage(damage_table)
		end
	end
end
