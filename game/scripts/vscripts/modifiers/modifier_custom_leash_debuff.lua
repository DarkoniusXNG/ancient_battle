modifier_custom_leash_debuff = class({})

function modifier_custom_leash_debuff:IsHidden()
	return true
end

function modifier_custom_leash_debuff:IsDebuff()
	return true
end

function modifier_custom_leash_debuff:IsPurgable()
	return true
end

function modifier_custom_leash_debuff:RemoveOnDeath()
	return true
end

function modifier_custom_leash_debuff:CheckState()
	return {
		[MODIFIER_STATE_TETHERED] = true,
	}
end
