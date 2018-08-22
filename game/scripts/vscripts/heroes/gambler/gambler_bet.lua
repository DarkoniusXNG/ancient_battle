-- Called when Bet is cast on enemies
function gambler_bet_on_spell_start(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	
	local radius = ability:GetLevelSpecialValueFor("radius", ability:GetLevel() - 1)
	local targetCurrentHP = target:GetHealth()
	local targetMaxHP = target:GetMaxHealth()
	local target_location = target:GetAbsOrigin()
	local target_team = target:GetTeam()
	
	-- Checking if there are heroes around the target
	local target_allies = FindUnitsInRadius(target_team, target_location, nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, 0, 0, false)
	local target_enemies = FindUnitsInRadius(target_team, target_location, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, 0, 0, false)
	local number_of_target_allies = #target_allies
	local number_of_target_enemies = #target_enemies
	
	-- Getting Target HP values
	local target25HP = 0.25*targetMaxHP
	local target50HP = 0.5*targetMaxHP
	local target75HP = 0.75*targetMaxHP
	
	-- Calculating the quota
	local HP_coeff = 0
	
	if targetCurrentHP > target25HP then
		HP_coeff = 1
	end
	if targetCurrentHP > target50HP then
		HP_coeff = 2
	end
	if targetCurrentHP > target75HP then
		HP_coeff = 3
	end
	if targetCurrentHP == targetMaxHP then
		HP_coeff = 4
	end
	
	-- local coeff = number_of_target_allies-2*number_of_target_enemies+HP_coeff -- old
	-- target.quota = 0.555*coeff+5.005 -- old
	
	target.quota = ((0.5*number_of_target_allies*HP_coeff)/(number_of_target_enemies+1))+0.01
	
	-- Capping the min and max quota
	if target.quota < 0.01 then
		target.quota = 0.01
	end
	if target.quota > 10 then
		target.quota = 10
	end
end

-- Called when the hero affected by bet takes damage, main block is executed when hero dies.
function gambler_bet_on_target_death(keys)
	local caster = keys.caster
	local target = keys.unit
	local ability = keys.ability
	local attacker = keys.attacker
	
	local ability_level = ability:GetLevel() - 1
	local max_gold_when_caster_kills = ability:GetLevelSpecialValueFor("max_gold_caster", ability_level)
	local max_gold_when_ally_kills = ability:GetLevelSpecialValueFor("max_gold", ability_level)
	local gold_for_killer = ability:GetLevelSpecialValueFor("bonus_gold", ability_level)
	local gold_cost = ability:GetGoldCost(ability_level)
	local gold_for_caster = gold_cost
	
	if target:IsAlive() == false and target:IsRealHero() and attacker and attacker:GetOwner() ~= nil then
		local attacker_owner = attacker:GetOwner()
		local caster_owner = caster:GetOwner()
		
		-- Calculating the winning gold for the caster
		gold_for_caster = math.ceil(target.quota * gold_cost)
		
		-- Checking if the caster (or caster's unit or illusion) got the kill, if he did, he is cheating and he is getting less gold
		if attacker_owner ~= caster_owner then
			-- Capping the gold for the caster if his ally got the kill
			if gold_for_caster > max_gold_when_ally_kills then
				gold_for_caster = max_gold_when_ally_kills
			end
			caster:ModifyGold(gold_for_caster, false, 0)
			-- Killer gets reliable gold
			attacker:ModifyGold(gold_for_killer, true, 0)
		else
			-- Capping the gold for the caster if he got the kill (setting the max and min)
			if gold_for_caster > max_gold_when_caster_kills then
				gold_for_caster = max_gold_when_caster_kills
			end
			if gold_for_caster < gold_cost then
				gold_for_caster = gold_cost
			end
			caster:ModifyGold(gold_for_caster, false, 0)
		end
		
		-- Message Particle, has a bunch of options
		local symbol = 0 -- "+" presymbol
		local color = Vector(255, 200, 33) -- Gold color
		local lifetime = 3
		local digits = string.len(gold_for_caster) + 1
		local particleName = "particles/units/heroes/hero_alchemist/alchemist_lasthit_msg_gold.vpcf"
		local particle = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN, caster)
		ParticleManager:SetParticleControl(particle, 1, Vector(symbol, gold_for_caster, symbol))
		ParticleManager:SetParticleControl(particle, 2, Vector(lifetime, digits, 0))
		ParticleManager:SetParticleControl(particle, 3, color)
	end
end