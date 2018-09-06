-- Called OnSpellStart
function DeathCoilStart(event)
	local caster = event.caster
	local ability = event.ability
	
	local damage_type = DAMAGE_TYPE_PURE
	local damage_to_self = ability:GetLevelSpecialValueFor("self_damage", ability:GetLevel() - 1)
	
	local damage_table = {}
	damage_table.attacker = caster
	damage_table.victim = caster
	damage_table.damage_type = damage_type
	damage_table.ability = ability
	damage_table.damage = damage_to_self
	ApplyDamage(damage_table)
end

-- Called OnProjectileHitUnit
function DeathCoilProjectileHit(event)
	local target = event.target
	local caster = event.caster
	local ability = event.ability
	local ability_level = ability:GetLevel() - 1
	
	local damage_type = ability:GetAbilityDamageType()
	local damage_to_enemies = ability:GetLevelSpecialValueFor("target_damage", ability_level)
	local heal_amount = ability:GetLevelSpecialValueFor("heal_amount", ability_level)
	
	-- Hit Sound
	target:EmitSound("Hero_Abaddon.DeathCoil.Target")
	
	-- Target is an enemy or ally?
	if target:GetTeamNumber() ~= caster:GetTeamNumber() then
		if not target:TriggerSpellAbsorb(ability) then
			local damage_table = {}
			damage_table.attacker = caster
			damage_table.victim = target
			damage_table.damage_type = damage_type
			damage_table.ability = ability
			damage_table.damage = damage_to_enemies
			ApplyDamage(damage_table)
		end
	else
		target:Heal(heal_amount, caster)
		SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, target, heal_amount, nil)
	end
end
