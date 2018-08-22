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

-- Called OnCreated modifier_ambushed
function AmbushFail(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	
	local target_location = target:GetAbsOrigin()
	local ability_level = ability:GetLevel() - 1
	
	local radius = ability:GetLevelSpecialValueFor("radius", ability_level)
	local base_damage = ability:GetLevelSpecialValueFor("base_damage", ability_level)
	local hp_percent = ability:GetLevelSpecialValueFor("max_hp_percent_damage", ability_level)
	
	local chance_to_fail = 0
	local target_max_hp = target:GetMaxHealth()
	local damage_table = {}
	damage_table.attacker = caster
	damage_table.damage_type = ability:GetAbilityDamageType()
	damage_table.ability = ability
	damage_table.victim = target
	
	-- Finding target's allies in a radius
	local enemies = FindUnitsInRadius(target:GetTeam(), target_location, nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 0, 0, false)
	-- Finding the number of target's allies excluding the target himself
	local number_of_nearby_enemies = #enemies - 1 -- removing the target from the count
	
	-- Calculating chance to fail (1 enemy - 20%; 2 enemies - 50%; 3 enemies - 66.67%; 4 enemies - 75%; 5 enemies - 80% ... 35 enemies - 97% etc.)
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
	local randomNumber = RandomFloat(0, 100.0)
	
	-- Setting the damage
	if randomNumber > chance_to_fail then
		damage_table.damage = math.ceil(base_damage + (hp_percent/100)*target_max_hp)
	else
		damage_table.damage = base_damage
	end
	
	-- Applying the damage
	ApplyDamage(damage_table)
end