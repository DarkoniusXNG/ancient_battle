-- Called OnSpellStart
function TimeVoidStart(event)
	local target = event.target
	local caster = event.caster
	local ability = event.ability
	
	local ability_level = ability:GetLevel() - 1
	
	local slow_duration = ability:GetLevelSpecialValueFor("duration", ability_level)
	local mini_stun_duration = ability:GetLevelSpecialValueFor("mini_stun_duration", ability_level)
	local damage = ability:GetLevelSpecialValueFor("damage", ability_level)
	
	local damage_table = {}
	damage_table.victim = target
	damage_table.attacker = caster
	damage_table.damage = damage
	damage_table.damage_type = ability:GetAbilityDamageType()
	damage_table.ability = ability
	
	-- Checking if target has spell block, if target has spell block, there is no need to execute the spell
	if not target:TriggerSpellAbsorb(ability) then
		ability:ApplyDataDrivenModifier(caster, target, "modifier_time_void_mini_stun", {["duration"] = mini_stun_duration})
		ability:ApplyDataDrivenModifier(caster, target, "modifier_time_void_slow_debuff", {["duration"] = slow_duration})
		
		ApplyDamage(damage_table)
	end
end
