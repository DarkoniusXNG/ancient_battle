if modifier_custom_unholy_aura_applier == nil then
	modifier_custom_unholy_aura_applier = class({})
end

function modifier_custom_unholy_aura_applier:IsHidden()
	return true
end

function modifier_custom_unholy_aura_applier:IsDebuff()
	return false
end

function modifier_custom_unholy_aura_applier:IsPurgable()
	return false
end

function modifier_custom_unholy_aura_applier:IsAura()
	if self:GetParent():PassivesDisabled() then
		return false
	end
	return true
end

function modifier_custom_unholy_aura_applier:AllowIllusionDuplicate()
	return true
end

function modifier_custom_unholy_aura_applier:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT
end

function modifier_custom_unholy_aura_applier:GetModifierAura()
	return "modifier_custom_unholy_aura_effect"
end

function modifier_custom_unholy_aura_applier:GetAuraRadius()
	local ability = self:GetAbility()
	if ability and not ability:IsNull() then
		return ability:GetSpecialValueFor("aura_radius")
	else
		return 1200
	end
end

function modifier_custom_unholy_aura_applier:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_custom_unholy_aura_applier:GetAuraSearchType()
	return bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC)
end

function modifier_custom_unholy_aura_applier:GetAuraSearchFlags()
	return DOTA_UNIT_TARGET_FLAG_NONE
end

function modifier_custom_unholy_aura_applier:GetEffectName()
	return "particles/custom/doom_bringer_doom.vpcf"
end

function modifier_custom_unholy_aura_applier:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end
