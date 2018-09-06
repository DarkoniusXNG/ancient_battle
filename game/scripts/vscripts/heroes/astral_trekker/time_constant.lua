-- Called periodically every 0.3 (think_interval) seconds OnIntervalThink
function PurgeTimeDebuffs(event)
	local caster = event.caster
	local ability = event.ability
	local ability_level = ability:GetLevel() - 1
	
	local threshold_ms = ability:GetLevelSpecialValueFor("ms_threshold", ability_level)
	local threshold_as = ability:GetLevelSpecialValueFor("as_threshold", ability_level)
	
	if caster then
		local current_as = caster:GetAttackSpeed()*100 		-- Current attack speed
		local current_ms = caster:GetIdealSpeed()			-- Current movement speed
		
		-- Checking current speeds with speed thresholds
		if current_as < threshold_as or current_ms < threshold_ms then
			
			SuperStrongDispel(caster, true, false)
			
			-- Sound
			EmitSoundOn("Hero_Tidehunter.KrakenShell", caster)
			
			-- Particle
			local particleName = "particles/units/heroes/hero_tidehunter/tidehunter_krakenshell_purge.vpcf"	
			local particle = ParticleManager:CreateParticle(particleName, PATTACH_POINT_FOLLOW, caster)
			ParticleManager:ReleaseParticleIndex(particle)
		end
	end
end
