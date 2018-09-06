function LinkensCheck(event)
	local target = event.target
	local caster = event.caster
	local ability = event.ability
	local duration = ability:GetLevelSpecialValueFor("slow_duration", ability:GetLevel() - 1)
	
	if not target:TriggerSpellAbsorb(ability) then
		ability:ApplyDataDrivenModifier(caster, target, "modifier_custom_lich_frost_nova_damage", {["duration"] = duration})
	end
end
