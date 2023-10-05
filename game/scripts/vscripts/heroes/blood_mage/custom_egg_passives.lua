﻿custom_egg_passives = class({})

LinkLuaModifier("modifier_custom_phoenix_egg_passives", "heroes/blood_mage/custom_egg_passives.lua", LUA_MODIFIER_MOTION_NONE)

function custom_egg_passives:GetIntrinsicModifierName()
	return "modifier_custom_phoenix_egg_passives"
end

function custom_egg_passives:IsStealable()
	return false
end

---------------------------------------------------------------------------------------------------

modifier_custom_phoenix_egg_passives = class({})

function modifier_custom_phoenix_egg_passives:IsHidden()
	return true
end

function modifier_custom_phoenix_egg_passives:IsDebuff()
	return false
end

function modifier_custom_phoenix_egg_passives:IsPurgable()
	return false
end

function modifier_custom_phoenix_egg_passives:IsPurgeException()
	return false
end

function modifier_custom_phoenix_egg_passives:IsStunDebuff()
	return false
end

function modifier_custom_phoenix_egg_passives:RemoveOnDeath()
	return true
end

--function modifier_custom_phoenix_egg_passives:OnCreated()
	-- "particles/units/heroes/hero_phoenix/phoenix_supernova_egg.vpcf"
--end

--function modifier_custom_phoenix_egg_passives:OnDestroy()

--end

function modifier_custom_phoenix_egg_passives:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
		MODIFIER_PROPERTY_DISABLE_HEALING,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end

function modifier_custom_phoenix_egg_passives:GetAbsoluteNoDamagePhysical()
	return 1
end

function modifier_custom_phoenix_egg_passives:GetAbsoluteNoDamageMagical()
	return 1
end

function modifier_custom_phoenix_egg_passives:GetAbsoluteNoDamagePure()
	return 1
end

function modifier_custom_phoenix_egg_passives:GetDisableHealing()
	return 1
end

if IsServer() then
	function modifier_custom_phoenix_egg_passives:OnAttackLanded(event)
		local parent = self:GetParent()
		local attacker = event.attacker
		local target = event.target

		if not attacker or attacker:IsNull() then
			return
		end

		if not target or target:IsNull() then
			return
		end

		if target ~= parent then
			return
		end

		-- Don't trigger when someone attacks items;
		if target.GetUnitName == nil then
			return
		end

		-- Handle attacks to destroy the egg
		local total_hp = parent:GetMaxHealth()
		local creep_attacks_to_destroy = 16
		local melee_hero_attacks_to_destroy = 4
		local ranged_hero_attacks_to_destroy = 4

		local ability = self:GetAbility()
		if ability then
			creep_attacks_to_destroy = ability:GetSpecialValueFor("creep_hits_to_kill")
			melee_hero_attacks_to_destroy = ability:GetSpecialValueFor("melee_hero_hits_to_kill")
			ranged_hero_attacks_to_destroy = ability:GetSpecialValueFor("ranged_hero_hits_to_kill")
		end

		local damage = total_hp/creep_attacks_to_destroy
		if attacker:IsRealHero() then
			damage = total_hp/melee_hero_attacks_to_destroy
			if attacker:IsRangedAttacker() then
				damage = total_hp/ranged_hero_attacks_to_destroy
			end
		end

		-- To prevent eggs staying in memory (preventing SetHealth(0) or SetHealth(-value) )
		if parent:GetHealth() - damage <= 0 then
			parent:Kill(ability, attacker)
		else
			parent:SetHealth(parent:GetHealth() - damage)
		end
	end
end

function modifier_custom_phoenix_egg_passives:CheckState()
	return {
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
	}
end
