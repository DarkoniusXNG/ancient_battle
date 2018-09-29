if modifier_custom_last_word_silence_active == nil then
	modifier_custom_last_word_silence_active = class({})
end

function modifier_custom_last_word_silence_active:IsHidden()
	return false
end

function modifier_custom_last_word_silence_active:IsPurgable()
	return true
end

function modifier_custom_last_word_silence_active:IsDebuff()
	return true
end

function modifier_custom_last_word_silence_active:OnCreated()
	local parent = self:GetParent()

	if IsServer() then
		-- Sound on unit (parent)
		parent:EmitSound("Hero_Silencer.LastWord.Damage")
	end
end

function modifier_custom_last_word_silence_active:CheckState()
	local state = {
	[MODIFIER_STATE_SILENCED] = true,
	}

	return state
end

function modifier_custom_last_word_silence_active:GetEffectName()
	return "particles/generic_gameplay/generic_silence.vpcf"
end

function modifier_custom_last_word_silence_active:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end
