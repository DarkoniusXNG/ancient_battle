-- Called on Spell Start
-- Blinks the target to the target point, if the point is beyond max blink range then blink the maximum range]]
function Blink(keys)
	local point = keys.target_points[1]
	local caster = keys.caster
	local casterPos = caster:GetAbsOrigin()
	
	local difference = point - casterPos
	difference.z = 0.0
	local difference_norm_vector = difference:Normalized()
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local range = ability:GetLevelSpecialValueFor("blink_range", ability_level)
	

	if difference:Length2D() > range then
		point = casterPos + difference_norm_vector * range
	end
	
	-- Start Particle
	local blinkIndex = ParticleManager:CreateParticle("particles/items_fx/blink_dagger_start.vpcf", PATTACH_ABSORIGIN, caster)
	Timers:CreateTimer( 1, function()
		ParticleManager:DestroyParticle(blinkIndex, false)
		ParticleManager:ReleaseParticleIndex(blinkIndex)
		return nil
		end
	)
	
	-- Teleporting caster and preventing getting stuck
	FindClearSpaceForUnit(caster, point, false)
	
	-- Disjoint disjointable/dodgeable projectiles
	ProjectileManager:ProjectileDodge(caster)
	
	-- End Particle
	local blink_end_index = ParticleManager:CreateParticle("particles/items_fx/blink_dagger_end.vpcf", PATTACH_ABSORIGIN, caster)
	ParticleManager:ReleaseParticleIndex(blink_end_index)

end
