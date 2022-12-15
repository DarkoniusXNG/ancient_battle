modifier_sona_song_of_celerity = class({})

function modifier_sona_song_of_celerity:IsHidden()
	return false
end

function modifier_sona_song_of_celerity:IsDebuff()
	return false
end

function modifier_sona_song_of_celerity:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_sona_song_of_celerity:IsPurgable()
	return true
end

function modifier_sona_song_of_celerity:OnCreated()
	-- references
	self.as_bonus = self:GetAbility():GetSpecialValueFor( "as_bonus" )
	self.ms_bonus = self:GetAbility():GetSpecialValueFor( "ms_bonus" )
end

function modifier_sona_song_of_celerity:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
end

function modifier_sona_song_of_celerity:GetModifierAttackSpeedBonus_Constant()
	return self.as_bonus
end

function modifier_sona_song_of_celerity:GetModifierMoveSpeedBonus_Percentage()
	return self.ms_bonus
end
