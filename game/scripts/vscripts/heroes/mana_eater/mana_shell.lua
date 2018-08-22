-- Give mana to the caster in relation to damage taken; doesn't work on illusions
-- Called OnTakeDamage inside modifier_mana_shell_passive
function ManaShellGiveMana(keys)
	local caster = keys.caster
	local damageTaken = keys.DamageTaken
	local mana_percentage = keys.ManaGain
	
	local mana_amount = damageTaken*mana_percentage/100
	
	if caster:IsRealHero() then
		caster:GiveMana(mana_amount)
	end
end