function PainStealStart(keys)
	local caster = keys.caster
	local ability = keys.ability
	local unit = keys.unit
	local damage_taken = keys.DamageTaken

	local ability_level = ability:GetLevel() - 1

	local pain_steal_heroes = ability:GetLevelSpecialValueFor("pain_steal", ability_level)
	local pain_steal_creeps = ability:GetLevelSpecialValueFor("pain_steal_creeps", ability_level)

	if caster and unit then
		if caster:IsRealHero() then
			local heal_amount
			if unit:IsRealHero() then
				heal_amount = damage_taken*pain_steal_heroes*0.01
			else
				heal_amount = damage_taken*pain_steal_creeps*0.01
			end
			if heal_amount > 0 then
				caster:Heal(heal_amount, ability)
				SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, caster, heal_amount, nil)
			end
		end
	end
end
