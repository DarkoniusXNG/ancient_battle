-- Called OnSpellStart
function IncapacitateStart(event)
	local target = event.target
	local caster = event.caster
	local ability = event.ability
	
	-- Checking if target has spell block, if target has spell block, there is no need to execute the spell
	if not target:TriggerSpellAbsorb(ability) then
		local disarm_duration = ability:GetLevelSpecialValueFor("duration", ability:GetLevel() - 1)
		
		ability:ApplyDataDrivenModifier(caster, target, "modifier_incapacitate_disarm", {["duration"] = disarm_duration})
		
		local talent = caster:FindAbilityByName("special_bonus_unique_night_stalker")
		if talent then
			if talent:GetLevel() ~= 0 then
				ability:ApplyDataDrivenModifier(caster, target, "modifier_incapacitate_silence", {["duration"] = disarm_duration})
			end
		end
	end
end
