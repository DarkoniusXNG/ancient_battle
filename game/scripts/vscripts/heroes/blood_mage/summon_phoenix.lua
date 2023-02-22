-- Gets the summoning location for the new units
function GetSummonPoints(event)
    local caster = event.caster
	local distance = event.distance
    local fv = caster:GetForwardVector()
    local origin = caster:GetAbsOrigin()

	local front_position = origin + fv*distance

    local result = {}
    table.insert(result, front_position)

    return result
end

-- Set units to look at the same point as the caster
function SetUnitsMoveForward(event)
	local caster = event.caster
	local target = event.target
    local fv = caster:GetForwardVector()

	target:SetForwardVector(fv)

	-- Keep the unit as caster's handle
	caster.phoenix = target
	-- Set ownership
	target:SetOwner(caster)
end

-- Called OnSpellStart - Kills previously summoned phoenix and egg if there are any
function KillPhoenix(event)
    local caster = event.caster
    local phoenix = caster.phoenix
    local phoenix_egg = caster.phoenix_egg

    if phoenix and not phoenix:IsNull() then
		phoenix:RemoveAbility("custom_phoenix_turn_into_egg")
		phoenix:RemoveModifierByName("modifier_custom_phoenix_reborn")
		phoenix:ForceKill(false)
	end
	if phoenix_egg and not phoenix_egg:IsNull() then
		phoenix_egg:RemoveAbility("custom_egg_turn_into_phoenix")
		phoenix_egg:RemoveModifierByName("modifier_custom_phoenix_egg")
		phoenix_egg:AddNoDraw()
		phoenix_egg:ForceKill(false)
	end
end

-- Called OnDeath - Removes the phoenix and spawns the egg with a timer
function PhoenixIntoEgg(event)
	local caster = event.caster -- the phoenix
	local ability = event.ability
	local hero = caster:GetOwner()
	local phoenix_egg_duration = ability:GetLevelSpecialValueFor("egg_duration", ability:GetLevel() - 1)

	-- Set the position, a bit floating over the ground
	local origin = caster:GetAbsOrigin()
	local position = Vector(origin.x, origin.y, origin.z+50)

	-- Hero can be removed 1 min Charm ends or Super Illusion expires
	if hero and not hero:IsNull() then
		local phoenix_egg = CreateUnitByName("npc_dota_custom_phoenix_egg", origin, true, hero, hero, hero:GetTeamNumber())
		phoenix_egg:SetAbsOrigin(position)

		-- Keep reference to the egg
		hero.phoenix_egg = phoenix_egg

		-- Apply modifiers for the summon properties
		phoenix_egg:AddNewModifier(hero, ability, "modifier_kill", {duration = phoenix_egg_duration})
	end

	-- Remove/Hide the phoenix
	--caster:RemoveSelf()
	--caster:ForceKill(true)
	caster:AddNoDraw()
end

-- Called OnDeath - Check if the egg died from an attacker other than the time-out
function PhoenixEggDeathCheck(event)
    local unit = event.unit -- the egg
    local attacker = event.attacker
    local hero = unit:GetOwner()
    local player = hero:GetPlayerOwner()
    local playerID = hero:GetPlayerID()

    if unit == attacker then
        local phoenix = CreateUnitByName("npc_dota_custom_phoenix_summon", unit:GetAbsOrigin(), true, player, hero, hero:GetTeamNumber())
        phoenix:SetControllableByPlayer(playerID, true)

        -- Keep reference
        hero.phoenix = phoenix
    else
        local particleName = "particles/units/heroes/hero_phoenix/phoenix_supernova_death.vpcf"
        local particle = ParticleManager:CreateParticle(particleName, PATTACH_CUSTOMORIGIN, unit)
        ParticleManager:SetParticleControl(particle, 0, unit:GetAbsOrigin())
        ParticleManager:SetParticleControl(particle, 1, unit:GetAbsOrigin())
        ParticleManager:SetParticleControl(particle, 3, unit:GetAbsOrigin())
		ParticleManager:ReleaseParticleIndex(particle)
    end

    -- Remove/Hide the egg
    --unit:RemoveSelf()
	--unit:ForceKill(true) -- not good -> plays the death animation
	unit:AddNoDraw()
end

-- Called OnIntervalThink inside modifier_custom_phoenix_fire_aura_applier
function PhoenixDegen(event)
	local caster = event.caster -- the phoenix
	local ability = event.ability

	if not caster or not ability then
		return
	end

	local damage_table = {}
	damage_table.victim = caster
	damage_table.attacker = caster
	damage_table.damage_type = DAMAGE_TYPE_PURE
	damage_table.ability = ability
	damage_table.damage = ability:GetLevelSpecialValueFor("damage_to_self", ability:GetLevel() - 1)
	damage_table.damage_flags = bit.bor(DOTA_DAMAGE_FLAG_HPLOSS, DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL, DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS)

	ApplyDamage(damage_table)
end
