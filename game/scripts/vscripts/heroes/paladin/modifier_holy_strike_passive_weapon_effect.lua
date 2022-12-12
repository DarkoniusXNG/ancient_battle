if modifier_holy_strike_passive_weapon_effect == nil then
	modifier_holy_strike_passive_weapon_effect = class({})
end

function modifier_holy_strike_passive_weapon_effect:IsHidden()
	return true
end

function modifier_holy_strike_passive_weapon_effect:IsPurgable()
	return false
end

function modifier_holy_strike_passive_weapon_effect:IsDebuff()
	return false
end

function modifier_holy_strike_passive_weapon_effect:RemoveOnDeath()
	return false
end

function modifier_holy_strike_passive_weapon_effect:OnCreated()
	if IsServer() then
		if self.weapon_pfx == nil then
			local parent = self:GetParent()
			local parent_loc = parent:GetAbsOrigin()
			self.weapon_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_kunkka/kunkka_weapon_tidebringer.vpcf", PATTACH_CUSTOMORIGIN, parent)
			ParticleManager:SetParticleControlEnt(self.weapon_pfx, 0, parent, PATTACH_POINT_FOLLOW, "attach_weapon", parent_loc, true)
			--ParticleManager:SetParticleControlEnt(self.weapon_pfx, 2, parent, PATTACH_POINT_FOLLOW, "attach_attack2", parent_loc, true)
		end
	end
end

modifier_holy_strike_passive_weapon_effect.OnRefresh = modifier_holy_strike_passive_weapon_effect.OnCreated

function modifier_holy_strike_passive_weapon_effect:OnDestroy()
	if IsServer() then
		if self.weapon_pfx then
			ParticleManager:DestroyParticle(self.weapon_pfx, true)
			ParticleManager:ReleaseParticleIndex(self.weapon_pfx)
			self.weapon_pfx = nil
		end
	end
end

function modifier_holy_strike_passive_weapon_effect:GetEffectName()
	return "particles/units/heroes/hero_omniknight/omniknight_degen_aura_debuff.vpcf"
end

function modifier_holy_strike_passive_weapon_effect:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end
