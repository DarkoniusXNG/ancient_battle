modifier_bakedanuki_tricksters_insight_passive = class({})

function modifier_bakedanuki_tricksters_insight_passive:IsHidden()
	return true
end

function modifier_bakedanuki_tricksters_insight_passive:IsDebuff()
	return false
end

function modifier_bakedanuki_tricksters_insight_passive:IsPurgable()
	return false
end

modifier_bakedanuki_tricksters_insight_passive.modifier_name = "modifier_bakedanuki_tricksters_insight"

function modifier_bakedanuki_tricksters_insight_passive:OnCreated()
	self.crit_chance = self:GetAbility():GetSpecialValueFor( "crit_chance" )
	self.crit_mult = self:GetAbility():GetSpecialValueFor( "crit_mult" )
end

modifier_bakedanuki_tricksters_insight_passive.OnRefresh = modifier_bakedanuki_tricksters_insight_passive.OnCreated

function modifier_bakedanuki_tricksters_insight_passive:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
		MODIFIER_PROPERTY_ABSORB_SPELL,
	}
end

function modifier_bakedanuki_tricksters_insight_passive:GetModifierPreAttack_CriticalStrike( params )
	local parent = self:GetParent()
	local playerID = parent:GetPlayerOwnerID()

	local allow_crit = false
	local modifiers = params.target:FindAllModifiersByName(self.modifier_name)
	for _, mod in pairs(modifiers) do
		if mod then
			local mod_caster = mod:GetCaster()
			if mod_caster:GetPlayerOwnerID() == playerID then
				allow_crit = true
			end
		end
	end
	if allow_crit then
		if RandomInt(1, 100) <= self.crit_chance then
			return self.crit_mult
		end
	end
end

-- Using parent as the caster, so the spell block doesnt work for illusions
function modifier_bakedanuki_tricksters_insight_passive:GetAbsorbSpell( params )
	local modifier = params.ability:GetCaster():FindModifierByNameAndCaster( self.modifier_name, self:GetParent() )
	if modifier then
		self:PlayEffects()
		return 1
	end
end

function modifier_bakedanuki_tricksters_insight_passive:PlayEffects()
	local parent = self:GetParent()
	local particle_cast = "particles/units/heroes/hero_dark_willow/dark_willow_leyconduit_marker_helper.vpcf"
	local sound_cast = "Hero_DarkWillow.Ley.Count"

	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN, parent )
	ParticleManager:SetParticleControl( effect_cast, 2, Vector( 200, 200, 200 ) )
	ParticleManager:ReleaseParticleIndex( effect_cast )

	parent:EmitSound(sound_cast)
end
