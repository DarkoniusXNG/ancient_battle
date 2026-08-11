modifier_holy_strike_passive_weapon_effect = class({})

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

-- function modifier_holy_strike_passive_weapon_effect:OnCreated()
	-- if IsServer() then

	-- end
-- end

-- modifier_holy_strike_passive_weapon_effect.OnRefresh = modifier_holy_strike_passive_weapon_effect.OnCreated

-- function modifier_holy_strike_passive_weapon_effect:OnDestroy()
	-- if IsServer() then
		-- if self.weapon_pfx then
			-- ParticleManager:DestroyParticle(self.weapon_pfx, true)
			-- ParticleManager:ReleaseParticleIndex(self.weapon_pfx)
			-- self.weapon_pfx = nil
		-- end
	-- end
-- end

function modifier_holy_strike_passive_weapon_effect:GetEffectName()
	return "particles/units/heroes/hero_omniknight/omniknight_degen_aura_debuff.vpcf"
end

function modifier_holy_strike_passive_weapon_effect:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end
