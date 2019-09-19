-- Called OnAttackLanded
function DemolishDamage(keys)
	local caster = keys.caster
	local attacker = keys.attacker
	local target = keys.target
	local ability = keys.ability
	local attack_damage = keys.Damage -- case-sensitive
	local ability_level = ability:GetLevel() - 1

	if not target then
		return nil
	end

	if target:IsNull() then
		return nil
    end

	-- Don't trigger on items
	if target.GetUnitName == nil then
		return nil
	end

	if target:IsOther() then
		return nil
	end

	local radius = ability:GetLevelSpecialValueFor("radius", ability_level)
	local damage_percent = ability:GetLevelSpecialValueFor("radius_damage_percent", ability_level)
	local buildings_bonus_damage = ability:GetLevelSpecialValueFor("bonus_damage_to_buildings", ability_level)

	local damage_value = attack_damage*(damage_percent/100)

	local target_type = bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)

	local damage_table = {}
	damage_table.attacker = attacker
	damage_table.ability = ability
	damage_table.damage_flags = DOTA_DAMAGE_FLAG_BYPASSES_BLOCK

	local enemies_in_radius = FindUnitsInRadius(caster:GetTeamNumber(), target:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, target_type, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
	for _,enemy in pairs(enemies_in_radius) do
		if enemy then
			if enemy ~= target and caster == attacker then
				damage_table.victim = enemy
				damage_table.damage = damage_value
				damage_table.damage_type = ability:GetAbilityDamageType()
				ApplyDamage(damage_table)
			end
		end
	end

	-- Check if the target is a building (target.GetInvulnCount() is nil for non-buildings)
	if target:IsBuilding() or target:IsTower() or target:IsBarracks() then
		damage_table.victim = target
		damage_table.damage = buildings_bonus_damage
		damage_table.damage_type = DAMAGE_TYPE_PHYSICAL
		ApplyDamage(damage_table)
	end
end
