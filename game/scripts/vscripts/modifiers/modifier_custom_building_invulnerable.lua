if modifier_custom_building_invulnerable == nil then
	modifier_custom_building_invulnerable = class({})
end

function modifier_custom_building_invulnerable:IsHidden()
    return true
end

function modifier_custom_building_invulnerable:IsPurgable()
    return false
end

function modifier_custom_building_invulnerable:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
	}
end

function modifier_custom_building_invulnerable:GetAbsoluteNoDamageMagical()
	return 1
end

function modifier_custom_building_invulnerable:GetAbsoluteNoDamagePhysical()
	return 1
end

function modifier_custom_building_invulnerable:GetAbsoluteNoDamagePure()
	return 1
end

function modifier_custom_building_invulnerable:CheckState()
	return {
		[MODIFIER_STATE_INVULNERABLE] = true,
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
	}
end
