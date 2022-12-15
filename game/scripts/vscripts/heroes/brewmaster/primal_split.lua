-- Called OnCreated modifier_custom_primal_split_caster_buff
function PrimalSplit(event)
	local caster = event.caster
	local playerID = caster:GetPlayerID()
	local ability = event.ability
	local duration = ability:GetLevelSpecialValueFor("spirit_duration", ability:GetLevel() - 1)

	local caster_team = caster:GetTeamNumber()

	local unit_name_earth = "npc_dota_custom_primal_split_earth_spirit"
	local unit_name_storm = "npc_dota_custom_primal_split_storm_spirit"
	local unit_name_fire = "npc_dota_custom_primal_split_fire_spirit"

	-- Calculating spawn positions
	local forwardV = caster:GetForwardVector()
    local origin = caster:GetAbsOrigin()
    local distance = 100
	local ang_right = QAngle(0, -90, 0)
    local ang_left = QAngle(0, 90, 0)

	local earth_position = origin + forwardV * distance 					-- Earth in front
	local storm_position = RotatePosition(origin, ang_left, earth_position) -- Storm at the left, a bit behind
	local fire_position = RotatePosition(origin, ang_right, earth_position) -- Fire at the righ, a bit behind

	-- Create the spirits
	caster.Earth = CreateUnitByName(unit_name_earth, earth_position, true, caster, caster, caster_team)
	caster.Storm = CreateUnitByName(unit_name_storm, storm_position, true, caster, caster, caster_team)
	caster.Fire = CreateUnitByName(unit_name_fire, fire_position, true, caster, caster, caster_team)

	-- Select spirits, deselect caster (main hero) - parts of selection library
	PlayerResource:AddToSelection(playerID, caster.Earth)
	PlayerResource:AddToSelection(playerID, caster.Storm)
	PlayerResource:AddToSelection(playerID, caster.Fire)
	PlayerResource:RemoveFromSelection(playerID, caster)

	-- Make them controllable
	caster.Earth:SetControllableByPlayer(playerID, true)
	caster.Storm:SetControllableByPlayer(playerID, true)
	caster.Fire:SetControllableByPlayer(playerID, true)

	-- Set all of them looking at the same point as the caster
	caster.Earth:SetForwardVector(forwardV)
	caster.Storm:SetForwardVector(forwardV)
	caster.Fire:SetForwardVector(forwardV)

	-- Apply modifiers to detect their death
	ability:ApplyDataDrivenModifier(caster, caster.Earth, "modifier_custom_primal_split_spirit_buff", {})
	ability:ApplyDataDrivenModifier(caster, caster.Storm, "modifier_custom_primal_split_spirit_buff", {})
	ability:ApplyDataDrivenModifier(caster, caster.Fire, "modifier_custom_primal_split_spirit_buff", {})

	-- Make them expire after the duration (Fire needs to die first, thats why shortest duration)
	caster.Earth:AddNewModifier(caster, ability, "modifier_kill", {duration = duration+0.2})
	caster.Storm:AddNewModifier(caster, ability, "modifier_kill", {duration = duration+0.1})
	caster.Fire:AddNewModifier(caster, ability, "modifier_kill", {duration = duration})

	-- Set the Earth unit as the primary active of the split (the hero will be periodically moved to the ActiveSplit location)
	caster.ActiveSplit = caster.Earth

	-- Hide the hero underground
	local underground_position = Vector(origin.x, origin.y, origin.z - 322)
	caster:SetAbsOrigin(underground_position)
end

-- When the spell ends, the Brewmaster takes Earth's place, if Earth is dead he takes Storm's place,
-- and if Storm is dead he takes Fire's place.
-- Called OnDeath inside modifier_custom_primal_split_spirit_buff
function SpiritDied(event)
	local caster = event.caster
	local attacker = event.attacker
	local unit = event.unit

	local playerID = caster:GetPlayerID()

	unit:AddNoDraw()

	-- Part of selection library
	PlayerResource:RemoveFromSelection(playerID, unit)

	local function IsAliveCustom(test)
		if not test or test:IsNull() then
			return false
		end

		if not IsValidEntity(test) then
			return false
		end

		if not test:IsAlive() then
			return false
		end

		return true
	end

	-- Check which spirits are still alive
	if IsAliveCustom(caster.Earth) then
		caster.ActiveSplit = caster.Earth
	elseif IsAliveCustom(caster.Storm) then
		caster.ActiveSplit = caster.Storm
	elseif IsAliveCustom(caster.Fire) then
		caster.ActiveSplit = caster.Fire
	else
		-- Check if they died because the spell ended, or they were killed by an attacker
		-- If the attacker is the same as the unit, it means the summon duration is over.
		if attacker and attacker ~= unit then
			-- Kill the caster with credit to the attacker.
			caster:Kill(nil, attacker)
			caster.ActiveSplit = nil
		end
	end
end

-- While the main spirit is alive, reposition the hero to its position so that auras are carried over.
-- This will also help finding the current Active primal split unit with the hero hotkey
function PrimalSplitAuraMove(event)
	-- Hide the hero underground on the Active Spirit position
	local caster = event.caster
	local active_split_position = caster.ActiveSplit:GetAbsOrigin()
	local underground_position = Vector(active_split_position.x, active_split_position.y, active_split_position.z - 322)
	caster:SetAbsOrigin(underground_position)
end

-- Ends the ability, repositioning the hero on the latest active split unit
function PrimalSplitEnd(event)
	local caster = event.caster
	local playerID = caster:GetPlayerID()

	if caster.ActiveSplit then
		local position = caster.ActiveSplit:GetAbsOrigin()
		FindClearSpaceForUnit(caster, position, true)
		-- Part of selection library
		PlayerResource:ResetSelection(playerID)
	end
end
