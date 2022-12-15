modifier_sona_crescendo_valor_attack = class({})

function modifier_sona_crescendo_valor_attack:IsHidden()
	return false
end

function modifier_sona_crescendo_valor_attack:IsDebuff()
	return true
end

function modifier_sona_crescendo_valor_attack:IsPurgable()
	return true
end

function modifier_sona_crescendo_valor_attack:GetTexture()
	return "custom/sona_hymn_of_valor"
end

function modifier_sona_crescendo_valor_attack:OnCreated()
	-- references
	self.input = self:GetAbility():GetSpecialValueFor( "valor_attack" )
end

modifier_sona_crescendo_valor_attack.OnRefresh = modifier_sona_crescendo_valor_attack.OnCreated

function modifier_sona_crescendo_valor_attack:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
	}
end

function modifier_sona_crescendo_valor_attack:GetModifierIncomingDamage_Percentage()
	return self.input
end
