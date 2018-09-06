-- Called OnProjectileHitUnit
function HazeBurnStart(keys)
    local caster = keys.caster
    local ability = keys.ability
    local target = keys.target
	
    if target:HasModifier("modifier_custom_drunken_haze_debuff") then
		ability:ApplyDataDrivenModifier(caster, target, "modifier_breath_fire_haze_burn", {})
	end
end

-- Called OnIntervalThink inside modifier_breath_fire_haze_burn
function HazeBurnDamage(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target
	
	local ability_level = ability:GetLevel() - 1
	local damage_per_second = ability:GetLevelSpecialValueFor("burn_damage_per_second", ability_level)
	local tick_interval = ability:GetLevelSpecialValueFor("tick_interval", ability_level)
    
	local damage_per_tick = damage_per_second*tick_interval
	
	ApplyDamage({victim = target, attacker = caster, ability = ability, damage = damage_per_tick, damage_type = DAMAGE_TYPE_MAGICAL})
	
end
