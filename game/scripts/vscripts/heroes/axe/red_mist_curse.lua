-- Called OnSpellStart
function RedMistCurse(event)
	local target = event.target
	local caster = event.caster
	local ability = event.ability
	local duration = ability:GetLevelSpecialValueFor("duration", ability:GetLevel() - 1)
	
	-- Checking if target has spell block, if target has spell block, there is no need to execute the spell
	if not target:TriggerSpellAbsorb(ability) then
		ability:ApplyDataDrivenModifier(caster, target, "modifier_red_mist_curse_debuff", {["duration"] = duration})
	end
end
