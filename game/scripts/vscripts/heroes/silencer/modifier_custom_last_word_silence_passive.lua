if modifier_custom_last_word_silence_passive == nil then
	modifier_custom_last_word_silence_passive = class({})
end

function modifier_custom_last_word_silence_passive:IsHidden()
	return false
end

function modifier_custom_last_word_silence_passive:IsPurgable()
	return true
end

function modifier_custom_last_word_silence_passive:IsDebuff()
	return true
end

function modifier_custom_last_word_silence_passive:CheckState()
	return {
		[MODIFIER_STATE_SILENCED] = true,
	}
end

function modifier_custom_last_word_silence_passive:GetEffectName()
	return "particles/generic_gameplay/generic_silence.vpcf"
end

function modifier_custom_last_word_silence_passive:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end
