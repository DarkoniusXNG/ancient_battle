-- Called OnAttackLanded
function PulverizeProc(event)
	local attacker = event.attacker
	local target = event.target
	local ability = event.ability
	local damage = event.DamageOnAttack
	local ability_level = ability:GetLevel() - 1
	
	local damage_percent = ability:GetLevelSpecialValueFor("cleave_damage", ability_level)
	local start_radius = ability:GetLevelSpecialValueFor("cleave_start_radius", ability_level)
	local distance = ability:GetLevelSpecialValueFor("cleave_distance", ability_level)
	local end_radius = ability:GetLevelSpecialValueFor("cleave_end_radius", ability_level)
	local particle = "particles/units/heroes/hero_magnataur/magnataur_empower_cleave_effect.vpcf"
	
	local cleave_origin = target:GetAbsOrigin()
	
	if attacker then
		if attacker:IsRealHero() then
			CustomCleaveAttack(attacker, target, ability, damage, damage_percent, cleave_origin, start_radius, end_radius, distance, particle)
		end
	end
end
