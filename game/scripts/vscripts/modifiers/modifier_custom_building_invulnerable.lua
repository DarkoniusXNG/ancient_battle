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
	local funcs = {
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
	}

	return funcs
end

function modifier_custom_building_invulnerable:GetAbsoluteNoDamageMagical(params)
	return 1
end

function modifier_custom_building_invulnerable:GetAbsoluteNoDamagePhysical(params)
	return 1
end

function modifier_custom_building_invulnerable:GetAbsoluteNoDamagePure(params)
	return 1
end

function modifier_custom_building_invulnerable:CheckState() 
  local state = {
    [MODIFIER_STATE_INVULNERABLE] = true,
    [MODIFIER_STATE_NO_HEALTH_BAR] = true
  }
  return state
end
