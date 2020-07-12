-- Called when modifier_deadpool_madness is created after 0.03 seconds and OnIntervalThink
function Madness (keys)
	if IsServer() then
		local caster = keys.caster
		local ability = keys.ability
		
		if caster:GetForceAttackTarget() then
			local old_target = caster:GetForceAttackTarget()
			if (old_target:IsAlive() == false) then
				-- Stop caster from trying to attack the dead unit
				caster:SetForceAttackTarget(nil)
				-- We need to remove the command restricted modifier if we want to give the new attack order to the caster
				caster:RemoveModifierByName("modifier_madness_restricted")
				-- Find new target for caster to attack
				FindNewUnitToAttack(caster, ability)
			else
				if old_target:IsInvisible() or old_target:IsAttackImmune() or old_target:IsInvulnerable() then
				-- Find new target for caster to attack but remove deniable and revealed modifier from the old target first
				old_target:RemoveModifierByName("modifier_madness_deniable")
				old_target:RemoveModifierByName("modifier_madness_revealed")
				-- Stop caster from trying to attack the unit that is not attackable
				caster:SetForceAttackTarget(nil)
				-- We need to remove the command restricted modifier if we want to give the new attack order to the caster
				caster:RemoveModifierByName("modifier_madness_restricted")
				-- Find a nearest attackable unit for the caster
				FindNewUnitToAttack(caster, ability)
				else
				--print("Old target is still attackable")
				end
			end
		else
			caster:SetForceAttackTarget(nil)
			caster:RemoveModifierByName("modifier_madness_restricted")
			-- Find a nearest attackable unit for the caster for the first time
			FindNewUnitToAttack(caster, ability)
		end
	end
end

-- Find the nearest attackable unit (friend or foe) for the caster; 
function FindNewUnitToAttack(caster, ability)
	local caster_team = caster:GetTeamNumber()
	local caster_position = caster:GetAbsOrigin()
	local flags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_NO_INVIS + DOTA_UNIT_TARGET_FLAG_NOT_ATTACK_IMMUNE
	local closest_distance = 20000
	local target = nil
	
	-- Find all units on the map that are attackable (enemy or ally of the caster)
	local units = FindUnitsInRadius(caster_team, caster_position, nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_ALL, flags, 0, false)
	
	-- Find the closest one
	for k, unit in pairs(units) do
		if unit ~= caster and unit:IsAlive() then
			-- Calculating distance
			local unit_position = unit:GetAbsOrigin()
			local vector = unit_position - caster_position
			vector.z = 0.0
			local distance = vector:Length2D()
			if distance < closest_distance then
				closest_distance = distance
				target = unit
			end
		end
	end
	if target then
		-- If the target belongs in caster's team add deniable modifier to the target, else add revealed modifier
		if target:GetTeamNumber() == caster_team then
			ability:ApplyDataDrivenModifier(caster, target, "modifier_madness_deniable", {})
		else
			ability:ApplyDataDrivenModifier(caster, target, "modifier_madness_revealed", {})
		end
		-- Stop current orders
		caster:Stop()
		-- Executing order if its not in Fog of War, to stop other stuff like channeling etc.
		if caster:CanEntityBeSeenByMyTeam(target) then
			local order = 
				{
					UnitIndex = caster:entindex(),
					OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
					TargetIndex = target:entindex(),
				}
			ExecuteOrderFromTable(order)
		else
			ExecuteOrderFromTable({UnitIndex = caster:entindex(), OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE, nil, nil})
		end
		
		-- Set the force attack target to be the caster
		caster:SetForceAttackTarget(target)
		
		-- Applying the command restricted modifier
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_madness_restricted", {})
	end
end

-- Called when modifier_deadpool_madness is destroyed
function MadnessEnd(keys)
	local caster = keys.caster
	local target = caster:GetForceAttackTarget()
	caster:SetForceAttackTarget(nil)
	caster:RemoveModifierByName("modifier_madness_restricted")
	if target then
		if target:IsAlive() then
			target:RemoveModifierByName("modifier_madness_deniable")
			target:RemoveModifierByName("modifier_madness_revealed")
		end
	end
end

-- Make vision every second
function ProvideVision( event )
	local caster = event.caster
	local target = event.target
	local ability = event.ability
	local caster_team = caster:GetTeamNumber()
	local target_location = target:GetAbsOrigin()

	AddFOWViewer( caster_team, target_location, 50, 1.0, true)
	target:MakeVisibleToTeam(caster_team, 1.0)
end