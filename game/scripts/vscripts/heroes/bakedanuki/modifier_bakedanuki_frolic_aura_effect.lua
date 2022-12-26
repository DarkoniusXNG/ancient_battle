modifier_bakedanuki_frolic_aura_effect = class({})

function modifier_bakedanuki_frolic_aura_effect:IsHidden()
	return false
end

function modifier_bakedanuki_frolic_aura_effect:IsDebuff()
	return false
end

function modifier_bakedanuki_frolic_aura_effect:IsPurgable()
	return false
end

function modifier_bakedanuki_frolic_aura_effect:OnCreated()
	-- references
	self.evasion_self = self:GetAbility():GetSpecialValueFor( "evasion_self" )
	self.evasion_ally = self:GetAbility():GetSpecialValueFor( "evasion_ally" )
end

modifier_bakedanuki_frolic_aura_effect.OnRefresh = modifier_bakedanuki_frolic_aura_effect.OnCreated

function modifier_bakedanuki_frolic_aura_effect:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_EVASION_CONSTANT,
	}
end

function modifier_bakedanuki_frolic_aura_effect:GetModifierEvasion_Constant()
	if self:GetParent() == self:GetCaster() then
		return self.evasion_self
	else
		return self.evasion_ally
	end
end
