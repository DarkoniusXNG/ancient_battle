-- Succesful All In, does damage to target based on caster's net worth
function AllInSuccess(event)
	local caster = event.caster
	local target = event.target
	local ability = event.ability

	local gold_damage_type = ability:GetAbilityDamageType()
	local ability_level = ability:GetLevel() - 1

	local gold_damage_ratio = ability:GetLevelSpecialValueFor("net_worth_to_damage_ratio", ability_level)
	local damage_cap = ability:GetLevelSpecialValueFor("damage_cap", ability_level)
	local scepter_damage_cap = ability:GetLevelSpecialValueFor("damage_cap_scepter", ability_level)

	-- Checking if target has spell block, if target has spell block, there is no need to execute the spell
	if not target:TriggerSpellAbsorb(ability) and not target:IsMagicImmune() then
		-- Checking if caster has aghanim scepter
		if caster:HasScepter() then
			damage_cap = scepter_damage_cap
		end

		-- Gold (Net worth) variables
		local current_gold = caster:GetGold()
		local items_worth = 0

		-- Getting the gold value of caster's items and adding to items_worth
		for i = DOTA_ITEM_SLOT_1, DOTA_STASH_SLOT_6 do
			local item = caster:GetItemInSlot(i)
			if item and item:GetPurchaser() == caster then
				items_worth = items_worth + item:GetCost()
			end
		end

		-- Setting the damage
		local gold_damage = math.ceil((current_gold + items_worth)*gold_damage_ratio*0.01)

		-- Cap the damage if it is over the damage cap
		if gold_damage > damage_cap then  
			gold_damage = damage_cap
		end

		-- Applying the damage
		ApplyDamage({victim = target, attacker = caster, damage = gold_damage, damage_type = gold_damage_type, ability = ability})

		-- Victory Particle
		local duel_victory_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_legion_commander/legion_commander_duel_victory.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
		ParticleManager:ReleaseParticleIndex(duel_victory_particle)

		-- Sounds
		local damage_sound_cap = damage_cap*0.8
		if gold_damage > damage_sound_cap then
			caster:EmitSound("Hero_OgreMagi.Fireblast.x3")
		else
			caster:EmitSound("Hero_OgreMagi.Fireblast.x2")
		end

		-- Message particle
		local symbol = 2
		local color = Vector(1, 200, 1) -- Green
		local lifetime = 2
		local digits = string.len(gold_damage) + 1
		local particleName = "particles/units/heroes/hero_alchemist/alchemist_lasthit_msg_gold.vpcf"
		local particle = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN, target)
		ParticleManager:SetParticleControl(particle, 1, Vector(symbol, gold_damage, 5))
		ParticleManager:SetParticleControl(particle, 2, Vector(lifetime, digits, 0))
		ParticleManager:SetParticleControl(particle, 3, color)
		ParticleManager:ReleaseParticleIndex(particle)
	end
end

-- Failed All In, damage is applied to caster, damage is credited to the target
function AllInFailure(event)
 	local caster = event.caster
 	local target = event.target
	local ability = event.ability

	local gold_damage_type = ability:GetAbilityDamageType()
	local ability_level = ability:GetLevel() - 1

	local gold_damage_ratio = ability:GetLevelSpecialValueFor("net_worth_to_damage_ratio", ability_level)
	local damage_cap = ability:GetLevelSpecialValueFor("damage_cap", ability_level)
	local scepter_damage_cap = ability:GetLevelSpecialValueFor("damage_cap_scepter", ability_level)

	-- Checking if caster has aghanim scepter
	if caster:HasScepter() then
		damage_cap = scepter_damage_cap
	end

	-- Gold (Net worth) variables
	local current_gold = caster:GetGold()
	local items_worth = 0

	-- Getting the gold value of caster's items and adding to items_worth
	for i = DOTA_ITEM_SLOT_1, DOTA_STASH_SLOT_6 do
		local item = caster:GetItemInSlot(i)
		if item and item:GetPurchaser() == caster then
			items_worth = items_worth + item:GetCost()
		end
	end

	-- Setting the damage
	local gold_damage = math.ceil((current_gold + items_worth)*gold_damage_ratio*0.01)

	-- Cap the damage if it is over the damage cap.
	if gold_damage > damage_cap then  
		gold_damage = damage_cap
	end

	-- Applying the damage
	ApplyDamage({victim = caster, attacker = target, damage = gold_damage, damage_type = gold_damage_type, ability = ability})

	-- Sound
	caster:EmitSound("Hero_Rubick.SpellSteal.Target")

	-- Message particle
	local symbol = 2
	local color = Vector(255, 1, 1) -- Red
	local lifetime = 2
	local digits = string.len(gold_damage) + 1
	local particleName = "particles/units/heroes/hero_alchemist/alchemist_lasthit_msg_gold.vpcf"
	local particle = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN, caster)
	ParticleManager:SetParticleControl(particle, 1, Vector(symbol, gold_damage, 0))
	ParticleManager:SetParticleControl(particle, 2, Vector(lifetime, digits, 0))
	ParticleManager:SetParticleControl(particle, 3, color)
	ParticleManager:ReleaseParticleIndex(particle)
end
