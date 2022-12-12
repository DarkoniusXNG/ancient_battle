-- Deals damage based on target's Net Worth. Target must be a hero.
function ChipStack(event)
	local caster = event.caster
	local target = event.target
	local ability = event.ability

	-- Checking if target has spell block, if target has spell block, there is no need to execute the spell
	if not target:TriggerSpellAbsorb(ability) then
		local gold_to_damage_ratio = ability:GetLevelSpecialValueFor("gold_to_damage_ratio", ability:GetLevel() - 1)

		-- Calculating target's networth
		local target_gold = target:GetGold()
		local items_worth = 0

		-- Getting the gold value of Target's items and adding to items_worth
		for i = DOTA_ITEM_SLOT_1, DOTA_STASH_SLOT_6 do
			local item = target:GetItemInSlot(i)
			if item and item:GetPurchaser() == target then
				items_worth = items_worth + item:GetCost()
			end
		end

		-- Setting Damage
		local gold_damage = 100

		if target_gold then
			gold_damage = math.ceil((target_gold + items_worth)*gold_to_damage_ratio*0.01)
		end

		local damage_table = {}
		damage_table.attacker = caster
		damage_table.damage_type = ability:GetAbilityDamageType()
		damage_table.damage_flags = DOTA_DAMAGE_FLAG_BYPASSES_BLOCK
		damage_table.ability = ability
		damage_table.victim = target
		damage_table.damage = gold_damage

		-- Applying Damage
		ApplyDamage(damage_table)

		-- Sound
		target:EmitSound("Hero_DoomBringer.DevourCast")

		-- Particle
		local color = Vector(255, 0, 0) -- RED color
		local lifetime = 2
		local digits = string.len(gold_damage) + 1
		local particleName = "particles/units/heroes/hero_alchemist/alchemist_lasthit_msg_gold.vpcf"
		local particle = ParticleManager:CreateParticle( particleName, PATTACH_ABSORIGIN, target)
		ParticleManager:SetParticleControl(particle, 1, Vector(1, gold_damage, 0))
		ParticleManager:SetParticleControl(particle, 2, Vector(lifetime, digits, 0))
		ParticleManager:SetParticleControl(particle, 3, color)
		ParticleManager:ReleaseParticleIndex(particle)
	end
end
