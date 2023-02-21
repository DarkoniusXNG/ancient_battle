function DoDamage(event)
    local ability = event.ability
    local caster = event.caster
    local team = caster:GetTeamNumber()
    local origin = caster:GetAbsOrigin()
    local radius = ability:GetCastRange()
    local damage = ability:GetAbilityDamage()
    --local max_damage = ability:GetLevelSpecialValueFor("max_damage",ability:GetLevel()-1)
	local target_team = ability:GetAbilityTargetTeam() or DOTA_UNIT_TARGET_TEAM_ENEMY
	local target_type = ability:GetAbilityTargetType() or bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
	local target_flags = ability:GetAbilityTargetFlags() or DOTA_UNIT_TARGET_FLAG_NONE

	local enemies = FindUnitsInRadius(
		team,
		origin,
		nil,
		radius,
		target_team,
		target_type,
		target_flags,
		FIND_ANY_ORDER,
		false
	)

	-- Damage table constants
	local damage_table = {}
	damage_table.attacker = caster
	damage_table.damage = damage
	damage_table.ability = ability
	damage_table.damage_type = ability:GetAbilityDamageType()

	for _, enemy in pairs(enemies) do
		if enemy and not enemy:IsNull() then
			damage_table.victim = enemy
			ApplyDamage(damage_table)
		end
	end
end