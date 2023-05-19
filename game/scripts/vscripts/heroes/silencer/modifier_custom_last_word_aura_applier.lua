modifier_custom_last_word_aura_applier = class({})

function modifier_custom_last_word_aura_applier:IsHidden()
	return true
end

function modifier_custom_last_word_aura_applier:IsPurgable()
	return false
end

function modifier_custom_last_word_aura_applier:IsAura()
	return true
end

function modifier_custom_last_word_aura_applier:AllowIllusionDuplicate()
	return true
end

function modifier_custom_last_word_aura_applier:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT
end

function modifier_custom_last_word_aura_applier:GetModifierAura()
	return "modifier_custom_last_word_aura_effect"
end

function modifier_custom_last_word_aura_applier:GetAuraRadius()
	local ability = self:GetAbility()
	return ability:GetSpecialValueFor("aura_radius")
end

function modifier_custom_last_word_aura_applier:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_custom_last_word_aura_applier:GetAuraSearchType()
	return bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC)
end

function modifier_custom_last_word_aura_applier:GetAuraSearchFlags()
	return DOTA_UNIT_TARGET_FLAG_NONE
end
