function IntToDamage( keys )
	local ability = keys.ability
	local caster = keys.caster
	local target = keys.target
	local int_caster = caster:GetIntellect()
	local int_damage = ability:GetLevelSpecialValueFor("intellect_damage_pct", (ability:GetLevel() -1)) 
	
	-- Damage table
	local damage_table = {}
	damage_table.attacker = caster
	damage_table.damage_type = DAMAGE_TYPE_PURE
	damage_table.ability = ability
	damage_table.victim = target
	damage_table.damage = math.ceil(int_caster * int_damage / 100)
	
	-- Apply damage
	ApplyDamage(damage_table)
end