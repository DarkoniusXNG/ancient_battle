modifier_custom_terror_buff = class({})

function modifier_custom_terror_buff:IsHidden()
	return false
end

function modifier_custom_terror_buff:IsDebuff()
	return false
end

function modifier_custom_terror_buff:IsPurgable()
	return true
end

function modifier_custom_terror_buff:RemoveOnDeath()
	return true
end

function modifier_custom_terror_buff:CheckState()
	return {
		[MODIFIER_STATE_DISARMED] = true,
	}
end

function modifier_custom_terror_buff:GetEffectName()
	return "particles/econ/items/invoker/invoker_ti6/invoker_deafening_blast_disarm_ti6_debuff.vpcf"
end

function modifier_custom_terror_buff:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end
