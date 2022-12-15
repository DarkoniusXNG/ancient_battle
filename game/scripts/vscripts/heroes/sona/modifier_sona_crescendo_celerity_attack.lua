modifier_sona_crescendo_celerity_attack = class({})

function modifier_sona_crescendo_celerity_attack:IsHidden()
	return false
end

function modifier_sona_crescendo_celerity_attack:IsDebuff()
	return true
end

function modifier_sona_crescendo_celerity_attack:IsPurgable()
	return true
end

function modifier_sona_crescendo_celerity_attack:GetTexture()
	return "custom/sona_song_of_celerity"
end

function modifier_sona_crescendo_celerity_attack:OnCreated()
	-- references
	self.ms_bonus = self:GetAbility():GetSpecialValueFor( "celerity_slow" ) -- special value
end

modifier_sona_crescendo_celerity_attack.OnRefresh = modifier_sona_crescendo_celerity_attack.OnCreated

function modifier_sona_crescendo_celerity_attack:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
end

function modifier_sona_crescendo_celerity_attack:GetModifierMoveSpeedBonus_Percentage()
	return self.ms_bonus
end
