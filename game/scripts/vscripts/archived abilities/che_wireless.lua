function GhostShip( keys )
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local caster_team = caster:GetTeamNumber()
	local caster_owner = caster:GetPlayerOwnerID() -- Owning player

	-- Particles and sounds
	local particle_name = keys.particle_name
	local projectile_name = keys.projectile_name
	local crash_sound = keys.crash_sound

	-- Parameters
	local spawn_distance = ability:GetLevelSpecialValueFor("spawn_distance", ability_level)
	local crash_distance = ability:GetLevelSpecialValueFor("crash_distance", ability_level)
	local ship_speed = ability:GetLevelSpecialValueFor("ghostship_speed", ability_level)
	local ship_radius = ability:GetLevelSpecialValueFor("ghostship_width", ability_level)
	local crash_delay = ability:GetLevelSpecialValueFor("tooltip_delay", ability_level)
	local stun_duration = ability:GetLevelSpecialValueFor("stun_duration", ability_level)
	local crash_damage = ability:GetLevelSpecialValueFor("crash_damage", ability_level)
	local crash_radius = 425

	-- Scepter parameters
	if caster:HasScepter() then
		spawn_distance = ability:GetLevelSpecialValueFor("spawn_distance_scepter", ability_level)
		ship_speed = ability:GetLevelSpecialValueFor("ghostship_speed_scepter", ability_level)
		ship_radius = ability:GetLevelSpecialValueFor("ghostship_width_scepter", ability_level)
		crash_damage = ability:GetLevelSpecialValueFor("crash_damage_scepter", ability_level)
	end

	-- Calculate spawn and crash positions
	local caster_pos = caster:GetAbsOrigin()
	local target_pos = keys.target_points[1]
	local boat_direction = ( target_pos - caster_pos )
	boat_direction.z = 0.0
	boat_direction = boat_direction:Normalized()
	local crash_pos = caster_pos + boat_direction * crash_distance
	local spawn_pos = caster_pos + boat_direction * spawn_distance * (-1)

	-- Persistent target point (for OnABoat function)
	caster.ghostship_crash_pos = crash_pos

	-- Show visual crash point effect to allies only
	local crash_pfx = ParticleManager:CreateParticleForTeam(particle_name, PATTACH_ABSORIGIN, caster, caster:GetTeam())
	ParticleManager:SetParticleControl(crash_pfx, 0, crash_pos )

	-- Destroy particle after the crash
	Timers:CreateTimer(crash_delay, function()
		ParticleManager:DestroyParticle(crash_pfx, false)
	end)

	-- Spawn the boat projectile
	local boat_projectile = {
		Ability = ability,
		EffectName = projectile_name,
		vSpawnOrigin = spawn_pos,
		fDistance = spawn_distance + crash_distance - ship_radius,
		fStartRadius = ship_radius,
		fEndRadius = ship_radius,
		fExpireTime = GameRules:GetGameTime() + crash_delay + 2,
		Source = caster,
		bHasFrontalCone = false,
		bReplaceExisting = false,
		bProvidesVision = true,
		iUnitTargetTeam = ability:GetAbilityTargetTeam(),
		iUnitTargetType = ability:GetAbilityTargetType(),
		vVelocity = boat_direction * ship_speed
	}

	ProjectileManager:CreateLinearProjectile(boat_projectile)
	
	-- After [crash_delay], apply damage and stun in the target area
	Timers:CreateTimer(crash_delay, function()
		
		-- Fire sound on crash point
		local dummy = CreateUnitByName("npc_dota_dummy_unit_wotf", crash_pos, false, caster, caster, caster:GetTeam() )
		--dummy:SetControllableByPlayer(caster_owner, true)
		--dummy:SetTeam(caster_team)
		--dummy:SetOwner(caster)
		dummy:EmitSound(crash_sound)
		dummy:Destroy()
		
		-- Stun and damage enemies
		local enemies = FindUnitsInRadius(caster:GetTeam(), crash_pos, nil, crash_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, ability:GetAbilityTargetType(), 0, 0, false)
		for k, enemy in pairs(enemies) do
			ApplyDamage({victim = enemy, attacker = caster, ability = ability, damage = crash_damage, damage_type = ability:GetAbilityDamageType()})
			enemy:AddNewModifier(caster, ability, "modifier_stunned", { duration = stun_duration })
			enemy.glimpsepoint = enemy:GetAbsOrigin()
		end
	end)
	
	-- After [glimpse_delay], apply glimpse to targets hit (targets hit has glimpsepoint)
	local glimpse_delay = crash_delay + stun_duration + 4
	local glimpse_radius = 20000 -- Global
	Timers:CreateTimer(glimpse_delay, function()
		-- Find Targets
		local glimpse_enemies = FindUnitsInRadius(caster_team, crash_pos, nil, glimpse_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, ability:GetAbilityTargetType(), 0, 0, false)
		for k, enemy in pairs(glimpse_enemies) do
			if enemy and enemy.glimpsepoint and enemy:IsRealHero() and (enemy:HasModifier("modifier_time_constant") == false) then
				FindClearSpaceForUnit( enemy, enemy.glimpsepoint, true )
				enemy:Interrupt()
				enemy.glimpsepoint = nil
			end
		end
	end)
end

function OnABoat( keys )
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	-- Parameters
	local crash_distance = ability:GetLevelSpecialValueFor("crash_distance", ability_level)
	local ship_speed = ability:GetLevelSpecialValueFor("ghostship_speed", ability_level)
	local impact_damage = ability:GetLevelSpecialValueFor("impact_damage", ability_level)
	local modifier_wireless_heal = keys.modifier_rum

	-- Scepter parameters
	if caster:HasScepter() then
		ship_speed = ability:GetLevelSpecialValueFor("ghostship_speed_scepter", ability_level)
		modifier_wireless_heal = keys.modifier_rum_scepter
	end

	-- If the target is an ally, apply healing buff and exit the function
	if caster:GetTeam() == target:GetTeam() then
		ability:ApplyDataDrivenModifier(caster, target, modifier_wireless_heal, {})
		return nil
	end

	-- Retrieve crash position and calculate knockback parameters
	local crash_pos = caster.ghostship_crash_pos
	local target_pos = target:GetAbsOrigin()
	local knockback_origin = target_pos + (target_pos - crash_pos):Normalized() * 100
	local distance = (crash_pos - target_pos):Length2D()
	local duration = distance / ship_speed

	-- Apply the knockback modifier and deal impact damage
	local knockback =
	{	should_stun = 1,
		knockback_duration = duration,
		duration = duration,
		knockback_distance = distance,
		knockback_height = 0,
		center_x = knockback_origin.x,
		center_y = knockback_origin.y,
		center_z = knockback_origin.z
	}
	target:RemoveModifierByName("modifier_knockback")
	target:AddNewModifier(caster, nil, "modifier_knockback", knockback)
	ApplyDamage({victim = target, attacker = caster, ability = ability, damage = impact_damage, damage_type = ability:GetAbilityDamageType()})
end