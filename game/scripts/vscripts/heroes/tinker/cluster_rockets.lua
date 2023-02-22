--[[
    Author: Noya
    Fires a tracking projectile to a random position in a radius of the area targeted previously. Area increases with engineering_upgrade levels
]]
function FireClusterRocket( event )
    local caster = event.caster
    local ability = event.ability
    local point = ability.point
    local radius =  ability:GetLevelSpecialValueFor( "radius" , ability:GetLevel() - 1  )
    --local projectile_count =  ability:GetLevelSpecialValueFor( "projectile_count" , ability:GetLevel() - 1  )
    local projectile_speed =  ability:GetLevelSpecialValueFor( "projectile_speed" , ability:GetLevel() - 1  )
    local particleName = "particles/units/heroes/hero_tinker/tinker_missile.vpcf"

    -- Get engineering level and increase the radius
    local engineering_level = 0
    local engineering_ability = caster:FindAbilityByName("tinker_engineering_upgrade")
    if engineering_ability and engineering_ability:GetLevel() > 0 then

        -- Increase radius
        local cluster_extra_radius = engineering_ability:GetLevelSpecialValueFor( "cluster_extra_radius" , engineering_level -1  )
        radius = radius + cluster_extra_radius
    end

    -- Create a dummy on the area to make the rocket track it
    local random_position = point + RandomVector(RandomInt(0,radius))
    local dummy = CreateUnitByName("npc_dota_custom_dummy_unit", random_position, false, caster, caster, DOTA_UNIT_TARGET_TEAM_ENEMY)

    local projTable = {
        EffectName = particleName,
        Ability = ability,
        Target = dummy,
        Source = caster,
        bDodgeable = false,
        bProvidesVision = false,
        vSpawnOrigin = caster:GetAbsOrigin(),
        iMoveSpeed = projectile_speed,
        iVisionRadius = 0,
        iVisionTeamNumber = caster:GetTeamNumber(),
        iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1
    }
    ProjectileManager:CreateTrackingProjectile( projTable )

    Timers:CreateTimer(2,function() UTIL_Remove(dummy) end)

end

-- Keep track of the targeted point to make the rockets
function StartClusterRockets( event )
    local ability = event.ability
    ability.point = event.target_points[1]
end

-- Damage and stun
function ClusterRocketHit(event)
    local caster = event.caster
    local target = event.target
    local ability = event.ability
    local damage = ability:GetAbilityDamage()
    local duration = ability:GetLevelSpecialValueFor("stun_duration",ability:GetLevel()-1)
    local target_team = ability:GetAbilityTargetTeam() or DOTA_UNIT_TARGET_TEAM_ENEMY
	local target_type = ability:GetAbilityTargetType() or bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
	local target_flags = ability:GetAbilityTargetFlags() or DOTA_UNIT_TARGET_FLAG_NONE

	local enemies = FindUnitsInRadius(
		caster:GetTeamNumber(),
		target:GetAbsOrigin(),
		nil,
		100,
		target_team,
		target_type,
		target_flags,
		FIND_ANY_ORDER,
		false
	)

    for _, enemy in pairs(enemies) do
        if enemy and not enemy:IsNull() and not enemy:HasFlyMovementCapability() then
            ability:ApplyDataDrivenModifier(caster,enemy,"modifier_cluster_rocket_stun",{duration=duration})
            ApplyDamage({ victim = enemy, attacker = caster, damage = damage, ability = ability, damage_type = DAMAGE_TYPE_MAGICAL })
        end
    end
end