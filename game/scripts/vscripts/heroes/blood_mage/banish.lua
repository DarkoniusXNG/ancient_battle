-- Called OnSpellStart
function BanishStart(event)
	local target = event.target
	local caster = event.caster
	local ability = event.ability

	-- Checking if target has spell block, and if its an enemy
	if not target:TriggerSpellAbsorb(ability) and target:GetTeamNumber() ~= caster:GetTeamNumber()  then
		local ability_level = ability:GetLevel() - 1

		local hero_duration = ability:GetLevelSpecialValueFor("hero_duration", ability_level)
		local creep_duration = ability:GetLevelSpecialValueFor("creep_duration", ability_level)

		if target:IsRealHero() then
			ability:ApplyDataDrivenModifier(caster, target, "modifier_banished_enemy", {["duration"] = hero_duration})
		else
			ability:ApplyDataDrivenModifier(caster, target, "modifier_banished_enemy", {["duration"] = creep_duration})
		end
	elseif target:GetTeamNumber() == caster:GetTeamNumber() then
		local ability_level = ability:GetLevel() - 1

		local hero_duration = ability:GetLevelSpecialValueFor("hero_duration", ability_level)
		local creep_duration = ability:GetLevelSpecialValueFor("creep_duration", ability_level)
		
		LinkLuaModifier("modifier_banished_heal_amp", "heroes/blood_mage/banish.lua", LUA_MODIFIER_MOTION_NONE)

		if target:IsRealHero() then
			ability:ApplyDataDrivenModifier(caster, target, "modifier_banished_ally", {["duration"] = hero_duration})
			target:AddNewModifier(caster, ability, "modifier_banished_heal_amp", {duration = hero_duration})
		else
			ability:ApplyDataDrivenModifier(caster, target, "modifier_banished_ally", {["duration"] = creep_duration})
			target:AddNewModifier(caster, ability, "modifier_banished_heal_amp", {duration = creep_duration})
		end
	end
end

if modifier_banished_heal_amp == nil then
	modifier_banished_heal_amp = class({})
end

function modifier_banished_heal_amp:IsHidden()
	return true
end

function modifier_banished_heal_amp:IsDebuff()
	return false
end

function modifier_banished_heal_amp:IsPurgable()
	return true
end

function modifier_banished_heal_amp:RemoveOnDeath()
	return true
end

function modifier_banished_heal_amp:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE
	}

	return funcs
end

function modifier_banished_heal_amp:GetModifierHPRegenAmplify_Percentage()
	local ability = self:GetAbility()
	local heal_amp_percentage = 75
	if ability then
		heal_amp_percentage = ability:GetSpecialValueFor("heal_amp_pct")
	end

	return heal_amp_percentage
end
