modifier_sona_crescendo_perseverance_attack = class({})

function modifier_sona_crescendo_perseverance_attack:IsHidden()
	return false
end

function modifier_sona_crescendo_perseverance_attack:IsDebuff()
	return true
end

function modifier_sona_crescendo_perseverance_attack:IsPurgable()
	return true
end

function modifier_sona_crescendo_perseverance_attack:GetTexture()
	return "custom/sona_aria_of_perseverance"
end

function modifier_sona_crescendo_perseverance_attack:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_TAKEDAMAGE,
	}
end

if IsServer() then
	function modifier_sona_crescendo_perseverance_attack:OnTakeDamage( params )
		if params.attacker~=self:GetParent() then return end

		if params.unit:GetHealth()<=0 then
			params.unit:SetHealth(1)
		end
	end
end
