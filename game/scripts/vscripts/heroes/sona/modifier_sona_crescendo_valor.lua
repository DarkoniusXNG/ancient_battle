modifier_sona_crescendo_valor = class({})

function modifier_sona_crescendo_valor:IsHidden()
	return false
end

function modifier_sona_crescendo_valor:IsDebuff()
	return false
end

function modifier_sona_crescendo_valor:IsPurgable()
	return false
end

function modifier_sona_crescendo_valor:GetTexture()
	return "custom/sona_hymn_of_valor"
end

function modifier_sona_crescendo_valor:OnCreated()
	-- references
	self.output = self:GetAbility():GetSpecialValueFor( "valor_aura" )
end

modifier_sona_crescendo_valor.OnRefresh = modifier_sona_crescendo_valor.OnCreated

function modifier_sona_crescendo_valor:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
	}
end

function modifier_sona_crescendo_valor:GetModifierDamageOutgoing_Percentage()
	return self.output
end
