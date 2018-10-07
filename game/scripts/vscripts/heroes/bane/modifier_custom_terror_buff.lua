if modifier_custom_terror_buff == nil then
	modifier_custom_terror_buff = class({})
end

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
	local state = {
	[MODIFIER_STATE_DISARMED] = true,
	}

	return state
end

function modifier_custom_terror_buff:GetEffectName()
	return "particles/econ/items/invoker/invoker_ti6/invoker_deafening_blast_disarm_ti6_debuff.vpcf"
end

function modifier_custom_terror_buff:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end
