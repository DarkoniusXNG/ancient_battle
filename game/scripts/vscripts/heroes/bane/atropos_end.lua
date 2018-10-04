-- Called OnToggleOn (instead of OnSpellStart so it can be used while stunned)
function AtroposEndStrongDispel(event)
	local caster = event.caster
	local ability = event.ability

	ability:ToggleAbility()
	
	SuperStrongDispel(caster, true, false)
	
	-- Sound on caster
	caster:EmitSound("n_creep_SatyrTrickster.Cast")
	
	-- Particle
	local particleName = "particles/generic_gameplay/generic_purge.vpcf"	
	local particle = ParticleManager:CreateParticle(particleName, PATTACH_POINT_FOLLOW, caster)
	ParticleManager:ReleaseParticleIndex(particle)
end
