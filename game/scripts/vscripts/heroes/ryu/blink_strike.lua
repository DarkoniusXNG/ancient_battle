-- Called OnSpellStart
-- Blinks the target to the target point, if the point is beyond max blink range then blink the maximum range
function Blink(keys)
	local point = keys.target_points[1]
	local caster = keys.caster
	local ability = keys.ability

	local caster_pos = caster:GetAbsOrigin()
	local caster_team = caster:GetTeamNumber()
	local ability_level = ability:GetLevel() - 1

	local direction = point - caster_pos
	direction.z = 0.0
	local direction_norm = direction:Normalized()

	local range = ability:GetLevelSpecialValueFor("blink_range", ability_level)
	local radius = ability:GetLevelSpecialValueFor("radius", ability_level)
	local blink_damage = ability:GetLevelSpecialValueFor("damage", ability_level)

	if direction:Length2D() > range then
		point = caster_pos + direction_norm*range
	end

	-- Start Particle
	local blink_start_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_antimage/antimage_blink_start.vpcf", PATTACH_ABSORIGIN, caster)
	Timers:CreateTimer(1.0, function()
		ParticleManager:DestroyParticle(blink_start_particle, false)
		ParticleManager:ReleaseParticleIndex(blink_start_particle)
	end)

	-- Teleporting caster and preventing getting stuck
	FindClearSpaceForUnit(caster, point, false)

	-- Disjoint disjointable/dodgeable projectiles
	ProjectileManager:ProjectileDodge(caster)

	-- End Particle
	local blink_end_particle = ParticleManager:CreateParticle("particles/items_fx/blink_dagger_end.vpcf", PATTACH_ABSORIGIN, caster)
	ParticleManager:ReleaseParticleIndex(blink_end_particle)

	-- Sound
	caster:EmitSound("Hero_Antimage.Blink_in")

	-- Targetting constants
	local target_team = ability:GetAbilityTargetTeam() or DOTA_UNIT_TARGET_TEAM_ENEMY
	local target_type = ability:GetAbilityTargetType() or bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
	local target_flags = ability:GetAbilityTargetFlags() or DOTA_UNIT_TARGET_FLAG_NONE

	local damage_table = {}
	damage_table.attacker = caster
	damage_table.damage = blink_damage
	damage_table.damage_type = ability:GetAbilityDamageType()
	damage_table.ability = ability

	-- Damage around blink destination
	local enemies = FindUnitsInRadius(caster_team, point, nil, radius, target_team, target_type, target_flags, FIND_ANY_ORDER, false)
	for _, enemy in pairs(enemies) do
		damage_table.victim = enemy
		ApplyDamage(damage_table)
	end
end
