if modifier_death_knight_death_pit_thinker == nil then
	modifier_death_knight_death_pit_thinker = class({})
end

function modifier_death_knight_death_pit_thinker:IsHidden()
	return true
end

function modifier_death_knight_death_pit_thinker:IsPurgable()
	return false
end

function modifier_death_knight_death_pit_thinker:IsAura()
	return true
end

function modifier_death_knight_death_pit_thinker:GetModifierAura()
	return "modifier_death_knight_death_pit_effect"
end

function modifier_death_knight_death_pit_thinker:GetAuraRadius()
	local ability = self:GetAbility()
	return ability:GetSpecialValueFor("radius")
end

function modifier_death_knight_death_pit_thinker:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_death_knight_death_pit_thinker:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC)
end

function modifier_death_knight_death_pit_thinker:GetAuraSearchFlags()
  return DOTA_UNIT_TARGET_FLAG_NONE
end

function modifier_death_knight_death_pit_thinker:OnCreated()
	if IsServer() then
		local ability = self:GetAbility()
		local radius = ability:GetSpecialValueFor("radius")
		local duration = ability:GetSpecialValueFor("pit_duration")
		local caster = ability:GetCaster()
		local location = ability:GetCursorPosition()
		
		self.location = location

		local dummy = CreateUnitByName("npc_dota_custom_dummy_unit", location, true, caster, caster, caster:GetTeamNumber())
		
		-- Sound on dummy (thinker) that represents Acid Spray itself
		dummy:EmitSound("Hero_AbyssalUnderlord.PitOfMalice")
		dummy:AddNewModifier(caster, ability, "modifier_kill", {duration = duration})

		-- Stops the sound after the duration; a bit early to ensure the dummy still exists
		Timers:CreateTimer(duration-0.1, function() 
			dummy:StopSound("Hero_AbyssalUnderlord.PitOfMalice")
		end)
		
		local particle = ParticleManager:CreateParticle("particles/econ/items/undying/undying_pale_augur/undying_pale_augur_decay.vpcf", PATTACH_CUSTOMORIGIN, caster)
		ParticleManager:SetParticleControl(particle, 0, location)
		ParticleManager:SetParticleControl(particle, 1, Vector(radius, radius, radius))
		ParticleManager:ReleaseParticleIndex(particle)
		
		--self.particle = ParticleManager:CreateParticle("particles/units/heroes/hero_ancient_apparition/ancient_ice_vortex.vpcf", PATTACH_CUSTOMORIGIN, caster)
		--ParticleManager:SetParticleControl(self.particle, 0, location)
		--ParticleManager:SetParticleControl(self.particle, 5, Vector(radius, radius, radius))
		
		self:StartIntervalThink(0.8)
	end
end

-- OnIntervalThink is needed only for the particles to repeat
function modifier_death_knight_death_pit_thinker:OnIntervalThink()
	if IsServer() then
		local ability = self:GetAbility()
		local radius = ability:GetSpecialValueFor("radius")
		
		local caster = ability:GetCaster()
		local location = self.location or ability:GetCursorPosition()
		
		local particle = ParticleManager:CreateParticle("particles/econ/items/undying/undying_pale_augur/undying_pale_augur_decay.vpcf", PATTACH_CUSTOMORIGIN, caster)
    	ParticleManager:SetParticleControl(particle, 0, location)
		ParticleManager:SetParticleControl(particle, 1, Vector(radius, radius, radius))
		ParticleManager:ReleaseParticleIndex(particle)
	end
end

function modifier_death_knight_death_pit_thinker:OnDestroy()
	if IsServer() then
		if self.particle then
			ParticleManager:DestroyParticle(self.particle, false)
			ParticleManager:ReleaseParticleIndex(self.particle)
		end
	end
end
