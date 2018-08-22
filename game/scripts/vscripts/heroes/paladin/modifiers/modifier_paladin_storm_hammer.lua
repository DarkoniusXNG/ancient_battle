if modifier_paladin_storm_hammer == nil then
	modifier_paladin_storm_hammer = class({})
end

function modifier_paladin_storm_hammer:IsDebuff()
	return true
end

function modifier_paladin_storm_hammer:IsStunDebuff()
	return true
end

function modifier_paladin_storm_hammer:GetEffectName()
	return "particles/generic_gameplay/generic_stunned.vpcf"
end

function modifier_paladin_storm_hammer:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end

function modifier_paladin_storm_hammer:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
	}

	return funcs
end

function modifier_paladin_storm_hammer:GetOverrideAnimation(params)
	return ACT_DOTA_DISABLED
end

function modifier_paladin_storm_hammer:CheckState()
	local state = {
	[MODIFIER_STATE_STUNNED] = true,
	}

	return state
end