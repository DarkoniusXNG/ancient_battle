--[[
	Author: kritth (modified by Darkonius)
	Start traversing the caster, and checking if caster should stop traversing based on destination or health
	This ability cannot be casted multiple times while it is active
]]
function astral_charge_traverse(keys)
	local caster = keys.caster
	local casterLoc = caster:GetAbsOrigin()
	local target = keys.target_points[1]
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	
	-- KV Variables
	local speed = ability:GetLevelSpecialValueFor("move_speed", ability_level)
	local destroy_radius = ability:GetLevelSpecialValueFor("tree_destroy_radius", ability_level)
	local vision_radius = ability:GetLevelSpecialValueFor("vision_radius", ability_level)
	local hp_percent = ability:GetLevelSpecialValueFor("hp_travel_cost_percent", ability_level)
	local distance_per_hp = ability:GetLevelSpecialValueFor("distance_per_hp", ability_level)
	local hp_cost_base = ability:GetLevelSpecialValueFor("hp_cost_base", ability_level)
	local damage = ability:GetLevelSpecialValueFor("damage", ability_level)
	local radius = ability:GetLevelSpecialValueFor("damage_radius", ability_level)
	
	-- Variables based on modifiers and precaches
	local loop_sound_name = "Hero_StormSpirit.BallLightning.Loop"
	local modifierName = "modifier_astral_charge_buff"
	
	if caster:GetHealth() < 100 then
		-- Stop everything if health of the caster is below 100 upon cast start
		ability:RefundManaCost()
		caster:RemoveModifierByName(modifierName)
		StopSoundOn(loop_sound_name, caster)
		caster.astral_charge_is_running = false
		caster:SetDayTimeVisionRange(1800)
		caster:SetNightTimeVisionRange(1000)
		return
	end
	
	-- Check if spell has already casted (this 'if block' prevents casting multiple times)
	if (caster.astral_charge_is_running ~= nil) and (caster.astral_charge_is_running == true) then
		ability:RefundManaCost()
		return
	end
	
	-- Set global value if the spell is already running
	caster.astral_charge_is_running = true
	
	-- Necessary pre-calculated variables
	local currentPos = casterLoc
	local intervals_per_second = speed / destroy_radius -- This will calculate how many times in one second, unit should move based on destroy tree radius
	local forwardVec = Vector(target.x - casterLoc.x, target.y - casterLoc.y, 0):Normalized()
	local hp_per_distance = (hp_percent/100)*caster:GetMaxHealth()
	
	-- Adjust vision (decrease vision of the caster)
	caster:SetDayTimeVisionRange(vision_radius)
	caster:SetNightTimeVisionRange(vision_radius)
	
	-- Start
	local distance = 0.0
	if caster:GetHealth() > hp_per_distance and caster:GetHealth() > 100 then
		-- Spend initial health cost; Health can't get lower than 100 hp with Astral Charge
		if ((caster:GetHealth() - hp_per_distance) > 100) then
			caster:SetHealth(caster:GetHealth() - hp_per_distance)
		else
			caster:SetHealth(100)
		end
		-- Emitting sound (added 15.1.2016;)
		EmitSoundOn(loop_sound_name, caster)
		-- Traverse
		Timers:CreateTimer(function()
			-- Removing health
			distance = distance + speed / intervals_per_second
			if distance >= distance_per_hp then
				-- Check if there is enough health to cast
				local hp_to_spend = hp_cost_base + hp_per_distance
				if caster:GetHealth() >= hp_to_spend and caster:GetHealth() > 100 then
					if ((caster:GetHealth() - hp_to_spend) > 100) then
						caster:SetHealth(caster:GetHealth() - hp_to_spend)
					else
						caster:SetHealth(100)
					end
				else
					-- Exit condition if caster run out of hp (his hp is < 100)
					caster:RemoveModifierByName(modifierName)
					StopSoundOn(loop_sound_name, caster)
					caster.astral_charge_is_running = false
					caster:SetDayTimeVisionRange(1800)
					caster:SetNightTimeVisionRange(1000)
					return nil
				end
				distance = distance - distance_per_hp
			end
			
			-- Update location
			currentPos = currentPos + forwardVec * ( speed / intervals_per_second )
			-- caster:SetAbsOrigin( currentPos ) -- This doesn't work because unit will not stick to the ground but rather travel in linear
			FindClearSpaceForUnit(caster, currentPos, false)
			
			-- Check if unit is close to the destination point
			if (target - currentPos):Length2D() <= speed / intervals_per_second then
				-- Exit condition if caster arrived at designated location
				caster:RemoveModifierByName(modifierName)
				StopSoundOn(loop_sound_name, caster)
				caster.astral_charge_is_running = false
				caster:SetDayTimeVisionRange(1800)
				caster:SetNightTimeVisionRange(1000)
				-- Damage around destination
				local enemies = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, 0, 0, false)
				for k, enemy in pairs(enemies) do
					ApplyDamage({victim = enemy, attacker = caster, ability = ability, damage = damage, damage_type = DAMAGE_TYPE_MAGICAL})
				end
				return nil
			else
				return 1 / intervals_per_second
			end
		end)
	else
		ability:RefundManaCost()
		-- Exit condition if caster doesn't have enough health
		caster:RemoveModifierByName(modifierName)
		StopSoundOn(loop_sound_name, caster)
		caster.astral_charge_is_running = false
		caster:SetDayTimeVisionRange(1800)
		caster:SetNightTimeVisionRange(1000)
	end
end

-- Stopping the Astral Charge OnDeath
function astral_charge_stop(keys)
	local caster = keys.caster
	local loop_sound_name = "Hero_StormSpirit.BallLightning.Loop"
	local modifierName = "modifier_astral_charge_buff"
	caster:RemoveModifierByName(modifierName)
	StopSoundOn(loop_sound_name, caster)
	caster.astral_charge_is_running = false
	caster:SetDayTimeVisionRange(1800)
	caster:SetNightTimeVisionRange(1000)
end