function LinkensCheck(event)
	local target = event.target
	local caster = event.caster
	local ability = event.ability
	local duration = ability:GetLevelSpecialValueFor("slow_duration", ability:GetLevel() - 1)

	-- Check for spell block and spell immunity (latter because of lotus)
	if target:TriggerSpellAbsorb(ability) or target:IsMagicImmune() then
		return
	end

	ability:ApplyDataDrivenModifier(caster, target, "modifier_custom_lich_frost_nova_damage", {["duration"] = duration})
end
