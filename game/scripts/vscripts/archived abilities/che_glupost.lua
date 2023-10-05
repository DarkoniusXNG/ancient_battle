-- Called when projectile actually hits
function glupost( keys )
	local caster = keys.caster
	local target = keys.target
	local target_location = target:GetAbsOrigin()
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	
	-- Checking if target has spell block, if target has spell block, there is no need to execute the spell
	if ( not target:TriggerSpellAbsorb( ability ) ) then
		-- Ability variables
		local stun_min = ability:GetLevelSpecialValueFor("stun_min", ability_level)
		local stun_max = ability:GetLevelSpecialValueFor("stun_max", ability_level) 
		local mana_value = ability:GetLevelSpecialValueFor("mana_burn", ability_level)
		local glupost_particle = keys.glupost_particle
		local current_mana = target:GetMana()

		-- Calculate the stun value
		local random = RandomFloat(0, 1)
		local stun = stun_min + (stun_max - stun_min) * random
		
		-- Calculate the number of digits needed for the particle
		local stun_digits = string.len(tostring(math.floor(stun))) + 1
		
		-- Create the stun particle for the spell
		local particle = ParticleManager:CreateParticle(glupost_particle, PATTACH_OVERHEAD_FOLLOW, target)
		ParticleManager:SetParticleControl(particle, 0, target_location) 

		-- Stun particle
		ParticleManager:SetParticleControl(particle, 3, Vector(8,stun,0)) -- prefix symbol, number, postfix symbol
		ParticleManager:SetParticleControl(particle, 4, Vector(2,stun_digits,0)) -- duration, digits, 0
		ParticleManager:ReleaseParticleIndex(particle)

		-- Apply the stun duration
		target:AddNewModifier(caster, ability, "modifier_stunned", {duration = stun})

		-- Mana Steal Calculation
		local mana_steal = math.min(current_mana, mana_value)
		-- Reducing Target's mana
		target:ReduceMana(mana_steal, ability)
		-- Increasing Caster's mana
		caster:GiveMana(mana_steal)
	end
end
