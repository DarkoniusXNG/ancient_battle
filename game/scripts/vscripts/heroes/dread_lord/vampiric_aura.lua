dread_lord_vampiric_aura = class({})

LinkLuaModifier("modifier_vampiric_aura", "heroes/dread_lord/vampiric_aura", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_vampiric_aura_buff", "heroes/dread_lord/vampiric_aura", LUA_MODIFIER_MOTION_NONE)

function dread_lord_vampiric_aura:GetIntrinsicModifierName()
    return "modifier_vampiric_aura"
end

--------------------------------------------------------------------------------

modifier_vampiric_aura = class({})

function modifier_vampiric_aura:IsAura()
    return true
end

function modifier_vampiric_aura:IsHidden()
    return true
end

function modifier_vampiric_aura:IsPurgable()
    return false
end

function modifier_vampiric_aura:GetAuraRadius()
    return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_vampiric_aura:GetModifierAura()
    return "modifier_vampiric_aura_buff"
end

function modifier_vampiric_aura:GetEffectName()
    return "particles/custom/aura_vampiric.vpcf"
end

function modifier_vampiric_aura:GetEffectAttachType()
    return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_vampiric_aura:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_vampiric_aura:GetAuraSearchFlags()
    return DOTA_UNIT_TARGET_FLAG_MELEE_ONLY
end

--function modifier_vampiric_aura:GetAuraEntityReject(target)
    --return
--end

function modifier_vampiric_aura:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_vampiric_aura:GetAuraDuration()
    return 0.5
end

--------------------------------------------------------------------------------

modifier_vampiric_aura_buff = class({})

function modifier_vampiric_aura_buff:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end

if IsServer() then
	function modifier_vampiric_aura_buff:OnAttackLanded(event)
		local parent = self:GetParent()
		local ability = self:GetAbility()
		local attacker = event.attacker
		local target = event.target
		local damage_on_attack = event.damage

		-- Check if attacker exists
		if not attacker or attacker:IsNull() then
			return
		end

		-- Check if attacker has this modifier
		if attacker ~= parent then
			return
		end

		-- To prevent crashes:
		if not target or target:IsNull() then
			return
		end

		-- Check for existence of GetUnitName method to determine if target is a unit or an item
		-- items don't have that method -> nil; if the target is an item, don't continue
		if target.GetUnitName == nil then
			return
		end

		-- Don't lifesteal from buildings, wards and invulnerable units.
		if target:IsTower() or target:IsBarracks() or target:IsBuilding() or target:IsOther() or target:IsInvulnerable() then
			return
		end

		-- Check if attacker is dead
		if not attacker:IsAlive() then
			return
		end

		-- Check if damage is 0 or negative
		if damage_on_attack <= 0 then
			return
		end

		local lifesteal_amount = self:GetAbility():GetSpecialValueFor("lifesteal") * damage_on_attack * 0.01
		attacker:HealWithParams(lifesteal_amount, ability, true, true, attacker, false)

		local particle = ParticleManager:CreateParticle("particles/generic_gameplay/generic_lifesteal.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, parent)
		ParticleManager:SetParticleControlEnt(particle, 0, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
		ParticleManager:ReleaseParticleIndex(particle)
	end
end

function modifier_vampiric_aura:IsPurgable()
    return false
end