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
    local origin = caster:GetAbsOrigin()

	target:SetForwardVector(fv)

	-- Keep the unit creation time of the first one created (needed for calculation of remaining time)
	caster.creation_time = GameRules:GetGameTime()
end

-- Counts hits made, creates a new unit, and refreshes the hp of the attacker
function LavaSpawnAttackCounter(event)
	local caster = event.caster
	local attacker = event.attacker
	local ability = event.ability
	local ability_level = ability:GetLevel() - 1

	local playerID = caster:GetPlayerID()
	local attacks_to_split = ability:GetLevelSpecialValueFor("attacks_to_split", ability_level)
	local lava_spawn_duration = ability:GetLevelSpecialValueFor("lava_spawn_duration", ability_level)

	-- Initialize counter
	if not attacker.attack_counter then
		attacker.attack_counter = 0
	end

	-- Increase counter
	attacker.attack_counter = attacker.attack_counter + 1

	-- Copy the unit, applying all the necessary modifiers
	if attacker.attack_counter == attacks_to_split then
		attacker:SetHealth(attacker:GetMaxHealth())			-- comment this if you don't want lava spawns to refresh their hp
		local lava_spawn = CreateUnitByName(attacker:GetUnitName(), attacker:GetAbsOrigin(), true, caster, caster, caster:GetTeamNumber())
		lava_spawn:SetControllableByPlayer(playerID, true)
		--local attacker_creation_time = attacker:GetCreationTime() 					-- uncomment for debugging
		--print("Creation time of the one that replicated: "..attacker_creation_time)	-- uncomment for debugging

		-- Getting the creation time of the first one
		local first_creation_time = caster.creation_time
		local current_time = GameRules:GetGameTime()
		local remaining_time = lava_spawn_duration - (current_time - first_creation_time) + 1

		ability:ApplyDataDrivenModifier(caster, lava_spawn, "modifier_lava_spawn", nil)
		ability:ApplyDataDrivenModifier(caster, lava_spawn, "modifier_lava_spawn_replicate", nil)
		ability:ApplyDataDrivenModifier(caster, lava_spawn, "modifier_lavaspawn_phased", {["duration"] = 1.0})
		--lava_spawn:SetHealth(attacker:GetHealth()) 		-- uncomment this if you don't want them to spawn with full hp

		if remaining_time > 0 then
			lava_spawn:AddNewModifier(caster, ability, "modifier_kill", {duration = remaining_time})
		else
			lava_spawn:AddNewModifier(caster, ability, "modifier_kill", {duration = 1.0})
		end
		--attacker.attack_counter = 0 						-- uncomment this if you want them to replicate multiple times
	end
end
