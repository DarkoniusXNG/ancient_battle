modifier_sona_crescendo_celerity = class({})

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

function modifier_sona_crescendo_celerity:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE_MIN,
	}
end

function modifier_sona_crescendo_celerity:GetModifierMoveSpeed_AbsoluteMin()
	if IsServer() then
		local caster = self:GetCaster()
		if self:GetParent() ~= caster then
			return caster:GetMoveSpeedModifier(caster:GetBaseMoveSpeed(), true)
		end
	end
end
