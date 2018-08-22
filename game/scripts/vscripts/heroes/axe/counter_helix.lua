-- Triggers when the unit attacks (OnAttackStart)
-- Checks if the attacked target has the counter helix aura_modifier
-- If true then trigger the counter helix if its not on cooldown
function CounterHelix(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local helix_modifier = keys.helix_modifier
	local aura_modifier = "modifier_counter_helix_aura_ultimate"

	-- If the attacked target has the counter helix aura_modifier then the attacked target is Axe or his illusion
	-- If the attacked target has helix_modifier then do not trigger the counter helix (its considered to be on cooldown)
	if target and IsValidEntity(target) and target.HasModifier and target.IsHero then
		if ability and target:HasModifier(aura_modifier) and not target:HasModifier(helix_modifier) then
			ability:ApplyDataDrivenModifier(caster, target, helix_modifier, {})
		end
	end	
end