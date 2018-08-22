-- Called OnSpellStart
function AstralStompDamageCheck(event)
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
	local base_damage = ability:GetLevelSpecialValueFor("base_damage", ability_level)
	local radius = ability:GetLevelSpecialValueFor("stun_radius", ability_level)
	
	local astral_damage = base_damage
	
	-- Checking if caster has Giant Growth ability
	if giant_growth then
		local giant_growth_level = giant_growth:GetLevel()
		-- Setting the damage according to level of Giant Growth
		if giant_growth_level == 1 then
			astral_damage = astral_damage + dmg_first_level
		end
		if giant_growth_level == 2 then
			astral_damage = astral_damage + dmg_second_level
		end
		if giant_growth_level == 3 then
			astral_damage = astral_damage + dmg_third_level
		end
		if caster:HasScepter() then
			-- Checking if Giant Growth is learned actually
			if giant_growth_level ~= 0 then
				-- Adding bonus damage if the caster has Scepter 
				astral_damage = astral_damage + 75
			end
			-- Increase the radius even if the caster doesn't have Giant Growth learned
			radius = radius + 485
		end
	end
	
	-- Damage enemies in a radius around the caster
	local enemies = FindUnitsInRadius(caster_team, caster_pos, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, 0, 0, false)
	for k, enemy in pairs(enemies) do
		if enemy:IsAttackImmune() or enemy:IsMagicImmune() then
			-- Enemy is immune to attacks or magic. Astral damage type doesn't affect them.
		else
			ApplyDamage({victim = enemy, attacker = caster, ability = ability, damage = astral_damage, damage_type = DAMAGE_TYPE_MAGICAL})
		end
	end
end