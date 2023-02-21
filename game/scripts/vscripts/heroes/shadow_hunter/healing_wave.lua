--[[
    Author: Noya
    Bounces from the main target to nearby targets in range. Avoids bouncing to full health units
]]
function HealingWave( event )
    local caster = event.caster
    local target = event.target
    local ability = event.ability
    local bounces = ability:GetLevelSpecialValueFor("max_bounces", ability:GetLevel()-1)
    local healing = ability:GetLevelSpecialValueFor("healing", ability:GetLevel()-1)
    local decay = ability:GetSpecialValueFor("wave_decay_percent")  * 0.01
    local radius = ability:GetSpecialValueFor("bounce_range")
    local time_between_bounces = 0.3

    local start_position
    local attach_attack1 = caster:ScriptLookupAttachment("attach_attack1")
    if attach_attack1 ~= 0 then
        start_position = caster:GetAttachmentOrigin(attach_attack1)
    else
        start_position = caster:GetAbsOrigin()
		start_position.z = start_position.z + target:GetBoundingMaxs().z
    end
    local current_position = CreateHealingWave(caster, caster:GetAbsOrigin(), target, healing, ability)
    bounces = bounces - 1 --The first hit counts as a bounce

    -- Every target struck by the chain is added to an entity index list
    local targetsStruck = {}
    targetsStruck[target:GetEntityIndex()] = true

	-- Targetting constants
	local target_team = DOTA_UNIT_TARGET_TEAM_FRIENDLY
	local target_type = bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
	local target_flags = DOTA_UNIT_TARGET_FLAG_NONE

    -- do bounces from target to new targets
    Timers:CreateTimer(time_between_bounces, function()

        -- unit selection and counting
		
		local allies = FindUnitsInRadius(caster:GetTeamNumber(), current_position, nil, radius, target_team, target_type, target_flags, FIND_ANY_ORDER, false)

        if #allies > 0 then

            -- Hit the first unit with health deficit that hasn't been struck yet
            local bounce_target
            for _,unit in pairs(allies) do
                local entIndex = unit:GetEntityIndex()
                if not targetsStruck[entIndex] and unit:GetHealthDeficit() > 0 then
                    bounce_target = unit
                    targetsStruck[entIndex] = true
                    break
                end
            end

            if bounce_target then
                -- heal and decay
                healing = healing - (healing*decay)
                current_position = CreateHealingWave(caster, current_position, bounce_target, healing, ability)

                -- decrement remaining spell bounces
                bounces = bounces - 1

                -- fire the timer again if spell bounces remain
                if bounces > 0 then
                    return time_between_bounces
                end
            end
        end
    end)
end

function CreateHealingWave(caster, start_position, target, healing, ability)
    local target_position
    local attach_hitloc = target:ScriptLookupAttachment("attach_hitloc")
    if attach_hitloc ~= 0 then
        target_position = target:GetAttachmentOrigin(attach_hitloc)
    else
        target_position = target:GetAbsOrigin()
		target_position.z = target_position.z + target:GetBoundingMaxs().z
    end

    local particle = ParticleManager:CreateParticle("particles/custom/dazzle_shadow_wave.vpcf", PATTACH_CUSTOMORIGIN, nil)
    ParticleManager:SetParticleControl(particle, 0, start_position)
    ParticleManager:SetParticleControl(particle, 1, target_position)

    local particle2 = ParticleManager:CreateParticle("particles/custom/dazzle_shadow_wave_copy.vpcf", PATTACH_CUSTOMORIGIN, nil)
    ParticleManager:SetParticleControl(particle2, 0, start_position)
    ParticleManager:SetParticleControl(particle2, 1, target_position)

    target:Heal(healing, target)
    local heal = math.floor(math.min(healing, target:GetHealthDeficit())+0.5)
    if heal > 0 then
        SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, target, heal, nil)
    end
    return target_position
end