if modifier_custom_paladin_talent == nil then
	modifier_custom_paladin_talent = class({})
end

function modifier_custom_paladin_talent:IsHidden()
    return true
end

function modifier_custom_paladin_talent:IsPurgable()
    return false
end

function modifier_custom_paladin_talent:AllowIllusionDuplicate() 
	return false
end

function modifier_custom_paladin_talent:RemoveOnDeath()
    return false
end