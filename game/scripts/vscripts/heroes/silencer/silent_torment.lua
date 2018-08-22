﻿-- OnIntervalThink inside modifier_silent_torment_debuff
function SilentTormentDamageSlow(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	
	local ability_level = ability:GetLevel() - 1
	local tick_interval = ability:GetLevelSpecialValueFor("tick_interval", ability_level)
	local damage_per_second = ability:GetLevelSpecialValueFor("damage_per_second", ability_level)
	local damage_per_tick = damage_per_second * tick_interval
	
	if target:IsSilenced() then
		-- if the target is silenced apply slow and double the damage
		ability:ApplyDataDrivenModifier(caster, target, "modifier_silent_torment_slow",{})
		damage_per_tick = 2*damage_per_tick
	else
		target:RemoveModifierByName("modifier_silent_torment_slow")
	end
	
	ApplyDamage({victim = target, attacker = caster, ability = ability, damage = damage_per_tick, damage_type = DAMAGE_TYPE_MAGICAL})
end