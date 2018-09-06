-- Called OnSpellStart; doesn't give xp to anyone
function DarkRitual(event)
	local caster = event.caster
	local target = event.target
	local ability = event.ability

	local target_health = target:GetHealth()
	local hp_percent = ability:GetLevelSpecialValueFor("health_conversion", ability:GetLevel() - 1)
	
	local mana_gain = target_health*hp_percent*0.01

	caster:GiveMana(mana_gain)
	target:ForceKill(true)
end
