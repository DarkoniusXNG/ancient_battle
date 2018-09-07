-- Called OnProjectileHitUnit inside Action in ActOnTargets
function BallHit(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	
	local caster_intelligence = caster:GetIntellect()
	local target_location = target:GetAbsOrigin()
	local ability_level = ability:GetLevel() - 1
	
	local vision_radius = ability:GetLevelSpecialValueFor("ball_vision", ability_level)
	local vision_duration = ability:GetLevelSpecialValueFor("vision_duration", ability_level)
	local base_damage = ability:GetLevelSpecialValueFor("base_damage", ability_level)
	local multiplier = ability:GetLevelSpecialValueFor("int_multiplier", ability_level)
	
	-- Calculating damage
	local total_damage = base_damage + caster_intelligence*multiplier
	
	-- Initializing the damage table
	local damage_table = {}
	damage_table.attacker = caster
	damage_table.victim = target
	damage_table.damage_type = ability:GetAbilityDamageType()
	damage_table.ability = ability	
	damage_table.damage = total_damage
	ApplyDamage(damage_table)
	
	-- Vision (visibility node)
	ability:CreateVisibilityNode(target_location, vision_radius, vision_duration)
end
