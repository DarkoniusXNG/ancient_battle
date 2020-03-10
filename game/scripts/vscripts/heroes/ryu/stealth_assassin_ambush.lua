-- Called OnSpellStart
function AmbushStart(event)
	local target = event.target
	local caster = event.caster
	local ability = event.ability
	
	-- Checking if target has spell block, if target has spell block, there is no need to execute the spell
	if not target:TriggerSpellAbsorb(ability) then
		ability:ApplyDataDrivenModifier(caster, target, "modifier_ambushed", {})
	end
end

-- Called OnCreated in modifier_ambushed
function AmbushFail(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	
	local target_location = target:GetAbsOrigin()
	local ability_level = ability:GetLevel() - 1
	
	local radius = ability:GetLevelSpecialValueFor("radius", ability_level)
	local base_damage = ability:GetLevelSpecialValueFor("base_damage", ability_level)
	local hp_percent_damage = ability:GetLevelSpecialValueFor("max_hp_percent_damage", ability_level)
	
	local target_max_hp = target:GetMaxHealth()
	
	local damage_table = {}
	damage_table.attacker = caster
	damage_table.damage_type = ability:GetAbilityDamageType()
	damage_table.ability = ability
	damage_table.victim = target
	
	-- Targetting constants
	local target_team = DOTA_UNIT_TARGET_TEAM_FRIENDLY
	local target_type = bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
	local target_flags = DOTA_UNIT_TARGET_FLAG_NONE
	
	-- Finding target's allies in a radius
	local enemies = FindUnitsInRadius(target:GetTeamNumber(), target_location, nil, radius, target_team, target_type, target_flags, FIND_ANY_ORDER, false)
	
	-- Number of target's allies around the target hero or unit (excluding the target itself)
	local number_of_nearby_enemies = #enemies - 1 -- removing the target from the count
	
	-- Calculating chance to fail (1 enemy - 20%; 2 enemies - 50%; 3 enemies - 66.67%; 4 enemies - 75%; 5 enemies - 80% ... 35 enemies - 97% etc.)
	local chance_to_fail
	if number_of_nearby_enemies > 1 then
		chance_to_fail = 100-(100/number_of_nearby_enemies)
	else
		if number_of_nearby_enemies == 1 then
			chance_to_fail = 20
		else
			chance_to_fail = 0
		end
	end
	
	-- Random number generation
	local random_number = RandomFloat(0, 100.0)
	
	-- Setting the damage
	if random_number > chance_to_fail then
		damage_table.damage = math.ceil(base_damage + hp_percent_damage*target_max_hp*0.01)
		
		-- Apply Slow debuff
		local slow_duration = ability:GetLevelSpecialValueFor("slow_duration", ability_level)
		ability:ApplyDataDrivenModifier(caster, target, "modifier_ambushed_slow_debuff", {["duration"] = slow_duration})
	else
		damage_table.damage = base_damage
	end
	
	-- Applying the damage
	ApplyDamage(damage_table)
end