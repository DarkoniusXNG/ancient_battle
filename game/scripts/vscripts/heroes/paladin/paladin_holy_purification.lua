-- Called OnSpellStart inside Action in ActOnTargets
function PurificationHit(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target
	local hit_particle = keys.hit_particle
	
	local radius = ability:GetLevelSpecialValueFor("radius", ability:GetLevel() - 1)
	
	local hit_pfx = ParticleManager:CreateParticle(hit_particle, PATTACH_ABSORIGIN_FOLLOW, target)
	ParticleManager:SetParticleControlEnt(hit_pfx, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(hit_pfx, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:SetParticleControl(hit_pfx, 3, Vector(radius, 0, 0))
	ParticleManager:ReleaseParticleIndex(hit_pfx)
end
