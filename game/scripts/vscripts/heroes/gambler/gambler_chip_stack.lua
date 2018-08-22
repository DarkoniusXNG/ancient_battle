-- Deals damage based on target's Net Worth. Target must be a hero.
function ChipStack(event)
	local caster = event.caster
	local target = event.target
	local ability = event.ability
	
	-- Checking if target has spell block, if target has spell block, there is no need to execute the spell
	if not target:TriggerSpellAbsorb(ability) then
		local gold_damage_type = ability:GetAbilityDamageType()
		local gold_to_damage_ratio = ability:GetLevelSpecialValueFor("gold_to_damage_ratio", ability:GetLevel() - 1 )
		
		-- Calculating target's networth
		local target_gold = target:GetGold()
		local items_worth = 0
		
		-- Getting the gold value of Target's items and adding to items_worth
		for i = 0, 5 do
			local item = target:GetItemInSlot( i )
			if item and item:GetPurchaser() == target then
				items_worth = items_worth + item:GetCost()
			end
		end
		
		-- Setting Damage
		local gold_damage = 100
		
		if target_gold then
			gold_damage = math.ceil((target_gold + items_worth)*gold_to_damage_ratio*0.01)
		end
		
		-- Applying Damage
		ApplyDamage({victim = target, attacker = caster, damage = gold_damage, damage_type = gold_damage_type, ability = ability}) 
		
		-- Sounds
		target:EmitSound("Hero_DoomBringer.DevourCast")
		target:EmitSound("DOTA_Item.Hand_Of_Midas")
		
		-- Particle number
		local color = Vector(255, 0, 0) -- RED color
		local lifetime = 2
		local digits = string.len(gold_damage) + 1
		local particleName = "particles/units/heroes/hero_alchemist/alchemist_lasthit_msg_gold.vpcf"
		local particle = ParticleManager:CreateParticle( particleName, PATTACH_ABSORIGIN, target)
		ParticleManager:SetParticleControl(particle, 1, Vector(1, gold_damage, 0))
		ParticleManager:SetParticleControl(particle, 2, Vector(lifetime, digits, 0))
		ParticleManager:SetParticleControl(particle, 3, color)
	end
end