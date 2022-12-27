-- Called OnProjectileHitUnit
function EntrapmentStart(event)
	local target = event.target
	local caster = event.caster
	local ability = event.ability
	local duration = ability:GetLevelSpecialValueFor("duration" , ability:GetLevel() - 1)

	-- Checking for spell block; pierces spell immunity
	if not target:TriggerSpellAbsorb(ability) then
		duration = target:GetValueChangedByStatusResistance(duration)
		ability:ApplyDataDrivenModifier(caster, target, "modifier_entrapment", {["duration"] = duration})
		target:Interrupt()
	end
end
