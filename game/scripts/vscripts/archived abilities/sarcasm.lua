--[[Mana drain and damage part of Mana Break
	Author: Pizzalol]]
function ManaBreak( keys )
	local target = keys.target
	local caster = keys.caster
	local ability = keys.ability
	local manaBurn = ability:GetLevelSpecialValueFor("mana_per_hit", (ability:GetLevel() - 1))
	local manaDamage = ability:GetLevelSpecialValueFor("damage_per_burn", (ability:GetLevel() - 1))

	local damageTable = {}
	damageTable.attacker = caster
	damageTable.victim = target
	damageTable.damage_type = ability:GetAbilityDamageType()
	damageTable.ability = ability

	-- If the target is not magic immune then reduce the mana and deal damage
	if not target:IsMagicImmune() then
		-- Checking the mana of the target and calculating the damage
		local actual_mana_burn = math.min(target:GetMana(), manaBurn)
		damageTable.damage = actual_mana_burn * manaDamage

		-- Burn Mana
		target:ReduceMana(actual_mana_burn, ability)

		ApplyDamage(damageTable)
	end
	-- Sound and effect
	if not target:IsMagicImmune() and target:GetMana() > 1 then
		-- Play the sound
		target:EmitSound("Hero_Antimage.ManaBreak")
		-- Plays the particle
		local manaburn_fx = ParticleManager:CreateParticle("particles/generic_gameplay/generic_manaburn.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
		ParticleManager:SetParticleControl(manaburn_fx, 0, target:GetAbsOrigin() )
		ParticleManager:ReleaseParticleIndex(manaburn_fx)
	end
end