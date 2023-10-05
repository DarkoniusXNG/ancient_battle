modifier_custom_last_word_disarm = class({})

function modifier_custom_last_word_disarm:IsHidden()
	return false
end

function modifier_custom_last_word_disarm:IsPurgable()
	return true
end

function modifier_custom_last_word_disarm:IsDebuff()
	return true
end

function modifier_custom_last_word_disarm:CheckState()
	return {
		[MODIFIER_STATE_DISARMED] = true,
	}
end

function modifier_custom_last_word_disarm:GetEffectName()
	return "particles/units/heroes/hero_silencer/silencer_last_word_disarm.vpcf"
end

function modifier_custom_last_word_disarm:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end
