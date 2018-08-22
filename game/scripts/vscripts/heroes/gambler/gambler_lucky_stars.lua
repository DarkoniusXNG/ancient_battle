-- Adds gold when crit is succesful
function LuckyStars(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	
	local bonus_gold = ability:GetLevelSpecialValueFor("bonus_gold", ability:GetLevel() - 1)
	local caster_location = caster:GetAbsOrigin()
	
	-- Grants the gold (unreliable)
	caster:ModifyGold(bonus_gold, false, 0)

	-- Show the particles to all
	local particleName = "particles/units/heroes/hero_alchemist/alchemist_lasthit_coins.vpcf"		
	local particle = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN, caster)
	ParticleManager:SetParticleControl(particle, 0, caster_location)
	ParticleManager:SetParticleControl(particle, 1, caster_location)
	
	-- Message Particle, has a bunch of options
	local symbol = 0 -- "+" presymbol
	local color = Vector(255, 200, 33) -- Gold color
	local lifetime = 2
	local digits = string.len(bonus_gold) + 1
	local particleName = "particles/units/heroes/hero_alchemist/alchemist_lasthit_msg_gold.vpcf"
	local particle = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN, target)
	ParticleManager:SetParticleControl(particle, 1, Vector(symbol, bonus_gold, symbol))
    ParticleManager:SetParticleControl(particle, 2, Vector(lifetime, digits, 0))
    ParticleManager:SetParticleControl(particle, 3, color)
end
