-- Called OnAttackLanded
function DrunkenFistCleave(event)
	local attacker = event.attacker
	local target = event.target
	local ability = event.ability
	local damage = event.DamageOnAttack
	local ability_level = ability:GetLevel() - 1
	
	local damage_percent = ability:GetLevelSpecialValueFor("cleave_damage", ability_level)
	local start_radius = ability:GetLevelSpecialValueFor("cleave_start_radius", ability_level)
	local distance = ability:GetLevelSpecialValueFor("cleave_distance", ability_level)
	local end_radius = ability:GetLevelSpecialValueFor("cleave_end_radius", ability_level)
	
	local push_start_radius = ability:GetLevelSpecialValueFor("push_start_radius", ability_level)
	local push_distance = ability:GetLevelSpecialValueFor("push_distance", ability_level)
	local push_end_radius = ability:GetLevelSpecialValueFor("push_end_radius", ability_level)
	
	local knockback_height = ability:GetLevelSpecialValueFor("knockback_height", ability_level)
	local knockback_effect_duration = ability:GetLevelSpecialValueFor("knockback_duration", ability_level)
	local knockback_distance = ability:GetLevelSpecialValueFor("knockback_distance", ability_level)
	
	local cleave_origin = attacker:GetAbsOrigin()
	local particle = "particles/units/heroes/hero_sven/sven_spell_great_cleave.vpcf"
	
	local team_number = attacker:GetTeamNumber()
	local direction = attacker:GetForwardVector()
	local cache_unit = nil
	local order = FIND_ANY_ORDER
	local cache = false
	local target_team = ability:GetAbilityTargetTeam() or DOTA_UNIT_TARGET_TEAM_ENEMY
	local target_type = ability:GetAbilityTargetType() or bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
	local target_flags = ability:GetAbilityTargetFlags() or DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
	
	local knockback_modifier_table =
	{
		should_stun = 0,
		knockback_duration = knockback_effect_duration,
		duration = knockback_effect_duration,
		knockback_distance = knockback_distance,
		knockback_height = knockback_height,
		center_x = cleave_origin.x,
		center_y = cleave_origin.y,
		center_z = cleave_origin.z
	}
	
	if attacker then
		if attacker:IsRealHero() then
			-- Damage (cleave)
			CustomCleaveAttack(attacker, target, ability, damage, damage_percent, cleave_origin, start_radius, end_radius, distance, particle)
			
			-- Knockback
			local enemies = FindUnitsinTrapezoid(team_number, direction, cleave_origin, cache_unit, push_start_radius, push_end_radius, push_distance, target_team, target_type, target_flags, order, cache)
			for _, enemy in pairs(enemies) do
				enemy:AddNewModifier(attacker, ability, "modifier_knockback", knockback_modifier_table)
			end
			-- Hero_Tiny_Tree.Impact
		end
	end
end
