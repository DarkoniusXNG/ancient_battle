modifier_sona_crescendo_celerity = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_sona_crescendo_celerity:IsHidden()
	return false
end

function modifier_sona_crescendo_celerity:IsDebuff()
	return false
end

function modifier_sona_crescendo_celerity:IsPurgable()
	return false
end

function modifier_sona_crescendo_celerity:GetTexture()
	return "custom/sona_song_of_celerity"
end

function modifier_sona_crescendo_celerity:OnCreated( kv )
	self.caster = self:GetCaster()
end

function modifier_sona_crescendo_celerity:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE_MIN,
	}
end

function modifier_sona_crescendo_celerity:GetModifierMoveSpeed_AbsoluteMin()
	if IsServer() then
		if self:GetParent()~=self.caster then
			return self.caster:GetMoveSpeedModifier( self.caster:GetBaseMoveSpeed() )
		end
	end
end
