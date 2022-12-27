-- Called OnProjectileHitUnit
function DrunkenHazeStart(event)
	local target = event.target
	local caster = event.caster
	local ability = event.ability

	-- Check for spell block and spell immunity (latter because of lotus)
	if target:TriggerSpellAbsorb(ability) or target:IsMagicImmune() then
		return
	end

	local ability_level = ability:GetLevel() - 1
	local hero_duration = ability:GetLevelSpecialValueFor("duration_heroes", ability_level)
	local creep_duration = ability:GetLevelSpecialValueFor("duration_creeps", ability_level)
	local radius = ability:GetLevelSpecialValueFor("radius", ability_level)
	local caster_team = caster:GetTeamNumber()
	local target_location = target:GetAbsOrigin()

	-- Targetting constants
	local target_team = ability:GetAbilityTargetTeam() or DOTA_UNIT_TARGET_TEAM_ENEMY
	local target_type = ability:GetAbilityTargetType() or bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
	local target_flags = ability:GetAbilityTargetFlags() or DOTA_UNIT_TARGET_FLAG_NONE

	-- Talent that applies another modifier:
	local has_talent = false
	local talent = caster:FindAbilityByName("special_bonus_unique_brewmaster_drunken_haze_fizzle")
	if talent and talent:GetLevel() > 0 then
		LinkLuaModifier("modifier_drunken_haze_fizzle", "heroes/brewmaster/drunken_haze.lua", LUA_MODIFIER_MOTION_NONE)
		has_talent = true
	end

	local enemies = FindUnitsInRadius(caster_team, target_location, nil, radius, target_team, target_type, target_flags, FIND_ANY_ORDER, false)
	for _, unit in pairs(enemies) do
		if unit and not unit:IsMagicImmune() then
			-- If the target didn't become spell immune in the same frame as projectile hit then apply the debuff
			if unit:IsRealHero() then
				ability:ApplyDataDrivenModifier(caster, unit, "modifier_custom_drunken_haze_debuff", {["duration"] = hero_duration})
				if has_talent then
					unit:AddNewModifier(caster, ability, "modifier_drunken_haze_fizzle", {duration = hero_duration})
				end
			else
				ability:ApplyDataDrivenModifier(caster, unit, "modifier_custom_drunken_haze_debuff", {["duration"] = creep_duration})
			end
		end
	end
end

---------------------------------------------------------------------------------------------------

if modifier_drunken_haze_fizzle == nil then
	modifier_drunken_haze_fizzle = class({})
end

function modifier_drunken_haze_fizzle:IsHidden()
	return true
end

function modifier_drunken_haze_fizzle:IsDebuff()
	return true
end

function modifier_drunken_haze_fizzle:IsPurgable()
	return true
end

function modifier_drunken_haze_fizzle:RemoveOnDeath()
	return true
end
