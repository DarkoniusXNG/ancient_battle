if modifier_paladin_storm_hammer_talent == nil then
	modifier_paladin_storm_hammer_talent = class({})
end

function modifier_paladin_storm_hammer_talent:IsHidden()
    return true
end

function modifier_paladin_storm_hammer_talent:IsPurgable()
    return false
end

function modifier_paladin_storm_hammer_talent:AllowIllusionDuplicate() 
	return false
end

function modifier_paladin_storm_hammer_talent:RemoveOnDeath()
    return false
end

function modifier_paladin_storm_hammer_talent:OnCreated()
	if IsClient() then
		local parent = self:GetParent()
		local talent = self:GetAbility()
		local talent_value = talent:GetSpecialValueFor("value")
		parent.storm_hammer_talent_value = talent_value
	end
end
