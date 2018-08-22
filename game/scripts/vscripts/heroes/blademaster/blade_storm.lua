-- Called OnCreated modifier_custom_blade_storm
function BladeStormStart(keys)
	local caster = keys.caster
	-- Basic Dispel
	local RemovePositiveBuffs = false
	local RemoveDebuffs = true
	local BuffsCreatedThisFrameOnly = false
	local RemoveStuns = false
	local RemoveExceptions = false
    caster:Purge(RemovePositiveBuffs, RemoveDebuffs, BuffsCreatedThisFrameOnly, RemoveStuns, RemoveExceptions)
end

-- Called OnIntervalThink inside modifier_custom_blade_storm
function BladeStormDamage(keys)
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	
	local damage_per_second = ability:GetLevelSpecialValueFor("damage_per_second", ability_level)
	local tick_interval = ability:GetLevelSpecialValueFor("tick_interval", ability_level)
    local radius = ability:GetLevelSpecialValueFor("radius", ability_level)
	
	local damage_per_tick = damage_per_second*tick_interval
	local damage_to_buildings = damage_per_tick*0.25
	local caster_team = caster:GetTeamNumber()
	local caster_pos = caster:GetAbsOrigin()
	
	-- Damage enemies (not buildings) in a radius
	local enemies = FindUnitsInRadius(caster_team, caster_pos, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, 0, 0, false)
	for k, enemy in pairs(enemies) do
		ApplyDamage({victim = enemy, attacker = caster, ability = ability, damage = damage_per_tick, damage_type = DAMAGE_TYPE_MAGICAL})
		enemy:EmitSound("Hero_Juggernaut.BladeFury.Impact")
	end
	
	-- Damage enemy buildings in a radius
    local buildings = FindUnitsInRadius(caster_team, caster_pos, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_BUILDING, 0, 0, false)
	for k, enemy_building in pairs(buildings) do
		ApplyDamage({victim = enemy_building, attacker = caster, ability = ability, damage = damage_to_buildings, damage_type = DAMAGE_TYPE_MAGICAL})
		enemy_building:EmitSound("Hero_Juggernaut.BladeFury.Impact")
	end
end

-- Called OnDestroy modifier_custom_blade_storm
function BladeStormStop(keys)
	local caster = keys.caster
	-- Stops the looping sound event
	caster:StopSound("Hero_Juggernaut.BladeFuryStart")
end