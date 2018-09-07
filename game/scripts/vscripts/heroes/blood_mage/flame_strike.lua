function FlameStrikeStart(keys)
    local caster = keys.caster
	local ability = keys.ability
    local point = keys.target_points[1]
	local caster_team = caster:GetTeamNumber()
	
	local particle_name1 = "particles/blood_mage/invoker_sun_strike_team_immortal1.vpcf"
    local particle1 = ParticleManager:CreateParticleForTeam(particle_name1, PATTACH_CUSTOMORIGIN, caster, caster_team)
	ParticleManager:SetParticleControl(particle1, 0, point)
	ParticleManager:ReleaseParticleIndex(particle1)
	
	local particle_name2 = "particles/econ/items/shadow_fiend/sf_fire_arcana/sf_fire_arcana_requiemofsouls_line_ground.vpcf"
    local particle2 = ParticleManager:CreateParticleForTeam(particle_name2, PATTACH_CUSTOMORIGIN, caster, caster_team)
    ParticleManager:SetParticleControl(particle2, 0, point)
	ParticleManager:ReleaseParticleIndex(particle2)

	local particle_name3 = "particles/neutral_fx/black_dragon_fireball_lava_scorch.vpcf"
    local particle3 = ParticleManager:CreateParticleForTeam(particle_name3, PATTACH_CUSTOMORIGIN, caster, caster_team)
    ParticleManager:SetParticleControl(particle3, 0, point)
    ParticleManager:SetParticleControl(particle3, 2, Vector(11,0,0))
	ParticleManager:ReleaseParticleIndex(particle3)
end

function FlameStrikeDamage(keys)
    local caster = keys.caster
	local ability = keys.ability
	local target = keys.target
	local ability_level = ability:GetLevel() - 1
	
	local damage_per_second = ability:GetLevelSpecialValueFor("damage_per_second", ability_level)
	local damage_interval = ability:GetLevelSpecialValueFor("damage_interval", ability_level)
	
	local damage_per_tick = damage_per_second*damage_interval
	local damage_to_buildings = damage_per_tick*0.25
	
	if target.GetInvulnCount == nil then
		ApplyDamage({victim = target, attacker = caster, ability = ability, damage = damage_per_tick, damage_type = DAMAGE_TYPE_MAGICAL})
	else
		ApplyDamage({victim = target, attacker = caster, ability = ability, damage = damage_to_buildings, damage_type = DAMAGE_TYPE_MAGICAL})
	end
end

function InitialDamage(keys)
	local caster = keys.caster
	local point = keys.target_points[1]
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	
	local damage_to_units = ability:GetLevelSpecialValueFor("initial_damage", ability_level)
	local radius = ability:GetLevelSpecialValueFor("radius", ability_level)
	
	local damage_to_buildings = damage_to_units*0.25
	local caster_team = caster:GetTeamNumber()
	
	local target_type = bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
	
	-- Damage enemies (not buildings) in a radius
	local enemies = FindUnitsInRadius(caster_team, point, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, target_type, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
	for _, enemy in pairs(enemies) do
		ApplyDamage({victim = enemy, attacker = caster, ability = ability, damage = damage_to_units, damage_type = DAMAGE_TYPE_MAGICAL})
	end
	
	-- Damage enemy buildings in a radius
    local buildings = FindUnitsInRadius(caster_team, point, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_BUILDING, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
	for _, enemy_building in pairs(buildings) do
		ApplyDamage({victim = enemy_building, attacker = caster, ability = ability, damage = damage_to_buildings, damage_type = DAMAGE_TYPE_MAGICAL})
	end
end
