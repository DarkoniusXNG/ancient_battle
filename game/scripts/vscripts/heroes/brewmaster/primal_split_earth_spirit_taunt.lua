-- Called OnSpellStart
function TauntStart(event)
	local caster = event.caster
	local ability = event.ability
	local ability_level = ability:GetLevel() - 1

	local radius = ability:GetLevelSpecialValueFor("radius", ability_level)
	local duration = ability:GetLevelSpecialValueFor("duration", ability_level)

	local caster_team = caster:GetTeamNumber()
	local caster_location = caster:GetAbsOrigin()

	-- Targetting constants
	local target_team = ability:GetAbilityTargetTeam() or DOTA_UNIT_TARGET_TEAM_ENEMY
	local target_type = ability:GetAbilityTargetType() or bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
	local target_flags = ability:GetAbilityTargetFlags() or DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES

	local enemies_in_radius = FindUnitsInRadius(caster_team, caster_location, nil, radius, target_team, target_type, target_flags, FIND_ANY_ORDER, false)
	for _,enemy in pairs(enemies_in_radius) do
		if enemy then
			-- Interrupt channelling and current orders
			enemy:Interrupt()

			-- Force the enemy to attack the caster
			if enemy:IsCreep() and not enemy:IsControllableByAnyPlayer() then
				enemy:SetForceAttackTarget(caster)
			elseif not enemy:IsCommandRestricted() then
				local order =
				{
					UnitIndex = enemy:entindex(),
					OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
					TargetIndex = caster:entindex()
				}
				ExecuteOrderFromTable(order)
			end

			-- Apply a modifier with command restricted state
			ability:ApplyDataDrivenModifier(caster, enemy, "modifier_earth_spirit_custom_taunted", {["duration"] = duration})
		end
	end
end

-- Called OnDestroy
function TauntEnd(event)
	local unit = event.target

	if unit:IsCreep() then
		unit:SetForceAttackTarget(nil)
	end
end

-- Called OnIntervalThink
function TauntCheck(keys)
	local caster = keys.caster
	local unit = keys.target

	if caster and unit then
		if caster:IsAlive() then
			if caster:IsInvisible() or caster:IsAttackImmune() or caster:IsInvulnerable() then
				unit:RemoveModifierByName("modifier_earth_spirit_custom_taunted")
			end
		else
			unit:RemoveModifierByName("modifier_earth_spirit_custom_taunted")
		end
	end
end
