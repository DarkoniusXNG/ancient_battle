-- Called OnSpellStart
function BanishStart(event)
	local target = event.target
	local caster = event.caster
	local ability = event.ability

	local ability_level = ability:GetLevel() - 1
	local hero_duration = ability:GetLevelSpecialValueFor("hero_duration", ability_level)
	local creep_duration = ability:GetLevelSpecialValueFor("creep_duration", ability_level)
	
	-- Talent that increases duration:
	local talent = caster:FindAbilityByName("special_bonus_unique_blood_mage_1")
	if talent then
		if talent:GetLevel() > 0 then
			hero_duration = hero_duration + talent:GetSpecialValueFor("value")
			creep_duration = creep_duration + talent:GetSpecialValueFor("value")
		end
	end

	-- Checking if target has spell block, and if its an enemy
	if not target:TriggerSpellAbsorb(ability) and target:GetTeamNumber() ~= caster:GetTeamNumber()  then
		if target:IsRealHero() then
			ability:ApplyDataDrivenModifier(caster, target, "modifier_banished_enemy", {["duration"] = hero_duration})
		else
			ability:ApplyDataDrivenModifier(caster, target, "modifier_banished_enemy", {["duration"] = creep_duration})
		end
	elseif target:GetTeamNumber() == caster:GetTeamNumber() then
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

---------------------------------------------------------------------------------------------------

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

function modifier_banished_heal_amp:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.hp_regen_amp = ability:GetSpecialValueFor("heal_amp_pct")
    self.lifesteal_amp = ability:GetSpecialValueFor("heal_amp_pct")
    self.heal_amp = ability:GetSpecialValueFor("heal_amp_pct")
    self.spell_lifesteal_amp = ability:GetSpecialValueFor("heal_amp_pct")
  end
end

function modifier_banished_heal_amp:OnRefresh()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.hp_regen_amp = ability:GetSpecialValueFor("heal_amp_pct")
    self.lifesteal_amp = ability:GetSpecialValueFor("heal_amp_pct")
    self.heal_amp = ability:GetSpecialValueFor("heal_amp_pct")
    self.spell_lifesteal_amp = ability:GetSpecialValueFor("heal_amp_pct")
  end
end

function modifier_banished_heal_amp:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
		MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET,
		MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE,
		MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE,
	}

	return funcs
end

function modifier_banished_heal_amp:GetModifierHPRegenAmplify_Percentage()
  return self.hp_regen_amp or self:GetAbility():GetSpecialValueFor("heal_amp_pct")
end

function modifier_banished_heal_amp:GetModifierHealAmplify_PercentageTarget()
  return self.heal_amp or self:GetAbility():GetSpecialValueFor("heal_amp_pct")
end

function modifier_banished_heal_amp:GetModifierLifestealRegenAmplify_Percentage()
  return self.lifesteal_amp or self:GetAbility():GetSpecialValueFor("heal_amp_pct")
end

function modifier_banished_heal_amp:GetModifierSpellLifestealRegenAmplify_Percentage()
  return self.spell_lifesteal_amp or self:GetAbility():GetSpecialValueFor("heal_amp_pct")
end
