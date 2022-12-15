-- Called OnProjectileHitUnit
function EntrapmentStart(event)
	local target = event.target
	local caster = event.caster
	local ability = event.ability
	local duration = ability:GetLevelSpecialValueFor("duration" , ability:GetLevel() - 1)

	-- Checking if target has spell block, if target has spell block, there is no need to execute the spell
	if not target:TriggerSpellAbsorb(ability) then
		duration = target:GetValueChangedByStatusResistance(duration)
		ability:ApplyDataDrivenModifier(caster, target, "modifier_entrapment", {["duration"] = duration})
		target:Interrupt()
	end
end
