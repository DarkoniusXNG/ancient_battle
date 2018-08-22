-- Called OnAttackLanded
function DemolishDamage(keys)
	local caster = keys.caster
	local attacker = keys.attacker
	local target = keys.target
	local ability = keys.ability
	local attack_damage = keys.Damage -- case-sensitive
	local ability_level = ability:GetLevel() - 1
	
	local radius = ability:GetLevelSpecialValueFor("radius", ability_level)
	local damage_percent = ability:GetLevelSpecialValueFor("radius_damage_percent", ability_level)
	local buildings_bonus_damage = ability:GetLevelSpecialValueFor("bonus_damage_to_buildings", ability_level)
	local damage_type = ability:GetAbilityDamageType()
	
	local damage_value = attack_damage*(damage_percent/100)
	
	local enemies_in_radius = FindUnitsInRadius(caster:GetTeamNumber(), target:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
	for _,enemy in pairs(enemies_in_radius) do
		if enemy ~= target and caster == attacker then
			ApplyDamage({victim = enemy, attacker = caster, ability = ability, damage = damage_value, damage_type = damage_type})
		end
	end
	
	-- Check if the target is a building (target.GetInvulnCount() is nil for non-buildings)
	if target:IsBuilding() then
		ApplyDamage({victim = target, attacker = caster, ability = ability, damage = buildings_bonus_damage, damage_type = DAMAGE_TYPE_PHYSICAL})
	end
end