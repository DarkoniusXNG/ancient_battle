modifier_sona_crescendo_perseverance = class({})

function modifier_sona_crescendo_perseverance:IsHidden()
	return false
end

function modifier_sona_crescendo_perseverance:IsDebuff()
	return false
end

function modifier_sona_crescendo_perseverance:IsPurgable()
	return false
end

function modifier_sona_crescendo_perseverance:GetTexture()
	return "custom/sona_aria_of_perseverance"
end

function modifier_sona_crescendo_perseverance:OnCreated()
	self.armor_bonus = self:GetAbility():GetSpecialValueFor( "perseverance_armor" )
	self.magic_bonus = self:GetAbility():GetSpecialValueFor( "perseverance_magic" )
end

modifier_sona_crescendo_perseverance.OnRefresh = modifier_sona_crescendo_perseverance.OnCreated

function modifier_sona_crescendo_perseverance:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
	}
end

function modifier_sona_crescendo_perseverance:GetModifierPhysicalArmorBonus()
	return self.armor_bonus
end

function modifier_sona_crescendo_perseverance:GetModifierMagicalResistanceBonus()
	return self.magic_bonus
end
