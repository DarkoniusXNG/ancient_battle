-- Called OnSpellStart
-- Blinks the target to the target point, if the point is beyond max blink range then blink the maximum range
function Blink(keys)
	local point = keys.target_points[1]
	local caster = keys.caster
	local ability = keys.ability
	
	local casterPos = caster:GetAbsOrigin()
	local caster_team = caster:GetTeamNumber() -- GetTeam()
	local ability_level = ability:GetLevel() - 1
	
	local difference = point - casterPos
	difference.z = 0.0
	local difference_norm_vector = difference:Normalized()
	
	local range = ability:GetLevelSpecialValueFor("blink_range", ability_level)
	local radius = ability:GetLevelSpecialValueFor("radius", ability_level)
	local blink_damage = ability:GetLevelSpecialValueFor("damage", ability_level)

	if difference:Length2D() > range then
		point = casterPos + difference_norm_vector * range
	end
	
	-- Start Particle
	local blinkIndex = ParticleManager:CreateParticle("particles/units/heroes/hero_antimage/antimage_blink_start.vpcf", PATTACH_ABSORIGIN, caster)
	Timers:CreateTimer(1.0, function()
		ParticleManager:DestroyParticle(blinkIndex, false)
	end)
	
	-- Teleporting caster and preventing getting stuck
	FindClearSpaceForUnit(caster, point, false)
	
	-- Disjoint disjointable/dodgeable projectiles
	ProjectileManager:ProjectileDodge(caster)
	
	-- End Particle
	ParticleManager:CreateParticle("particles/items_fx/blink_dagger_end.vpcf", PATTACH_ABSORIGIN, caster)
	
	-- Sound
	caster:EmitSound("Hero_Antimage.Blink_in")
	
	-- Damage around blink destination
	local enemies = FindUnitsInRadius(caster_team, point, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, 0, 0, false)
	for k, enemy in pairs(enemies) do
		ApplyDamage({victim = enemy, attacker = caster, ability = ability, damage = blink_damage, damage_type = ability:GetAbilityDamageType()})
	end
end
