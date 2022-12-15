-- Called OnIntervalThink inside modifier_lich_custom_ice_storm_damage
function IceStormDamage(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target

	local ability_level = ability:GetLevel() - 1
	local damage_per_second = ability:GetLevelSpecialValueFor("damage_per_second", ability_level)
	local tick_interval = ability:GetLevelSpecialValueFor("tick_interval", ability_level)

	local damage_per_tick = damage_per_second*tick_interval

	ApplyDamage({victim = target, attacker = caster, ability = ability, damage = damage_per_tick, damage_type = DAMAGE_TYPE_MAGICAL})
end
