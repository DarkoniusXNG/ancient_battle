-- Called OnSpellStart
function AstralStomp(event)
	local caster = event.caster
	local ability = event.ability
	
	local ability_level = ability:GetLevel() - 1
	local caster_team = caster:GetTeamNumber()
	local caster_pos = caster:GetAbsOrigin()
	local giant_growth = caster:FindAbilityByName("astral_trekker_giant_growth")
	
	-- KV variables
	local dmg_first_level = ability:GetLevelSpecialValueFor("damage_level_1", ability_level)
	local dmg_second_level = ability:GetLevelSpecialValueFor("damage_level_2", ability_level)
	local dmg_third_level = ability:GetLevelSpecialValueFor("damage_level_3", ability_level)
	local astral_damage = ability:GetLevelSpecialValueFor("base_damage", ability_level)
	local radius = ability:GetLevelSpecialValueFor("radius", ability_level)
	local stun_duration = ability:GetLevelSpecialValueFor("stun_duration", ability_level)
	
	if caster:HasScepter() then
		-- Adding bonus damage if the caster has Scepter 
		astral_damage = ability:GetLevelSpecialValueFor("base_damage_scepter", ability_level)
		-- Increase the radius even if the caster doesn't have Giant Growth learned
		radius = ability:GetLevelSpecialValueFor("radius_scepter", ability_level)
	end
	
	-- Checking if caster has Giant Growth ability
	if giant_growth then
		local giant_growth_level = giant_growth:GetLevel()
		-- Setting the damage according to level of Giant Growth
		if giant_growth_level == 1 then
			astral_damage = astral_damage + dmg_first_level
		elseif giant_growth_level == 2 then
			astral_damage = astral_damage + dmg_second_level
		elseif giant_growth_level == 3 then
			astral_damage = astral_damage + dmg_third_level
		end
	end
	
	-- Targetting constants
	local target_team = ability:GetAbilityTargetTeam() or DOTA_UNIT_TARGET_TEAM_ENEMY
	local target_type = ability:GetAbilityTargetType() or bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
	local target_flags = ability:GetAbilityTargetFlags() or DOTA_UNIT_TARGET_FLAG_NONE
	
	-- Damage enemies in a radius around the caster
	local enemies = FindUnitsInRadius(caster_team, caster_pos, nil, radius, target_team, target_type, target_flags, FIND_ANY_ORDER, false)
	for _, enemy in pairs(enemies) do
		if enemy and not enemy:IsNull() then
			-- Get stun duration
			local enemy_stun_duration = enemy:GetValueChangedByStatusResistance(stun_duration)
			-- Apply stun modifier
			ability:ApplyDataDrivenModifier(caster, enemy, "modifier_astral_stomp", {["duration"] = enemy_stun_duration})
			-- Apply astral damage
			if not enemy:IsAttackImmune() and not enemy:IsMagicImmune() then
				-- Enemy is not immune to attacks and not immune to magic. Astral damage type can affect them.
				ApplyDamage({victim = enemy, attacker = caster, ability = ability, damage = astral_damage, damage_type = DAMAGE_TYPE_MAGICAL})
			end
		end
	end
end
