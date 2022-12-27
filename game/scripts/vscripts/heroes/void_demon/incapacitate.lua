-- Called OnSpellStart
function IncapacitateStart(event)
	local target = event.target
	local caster = event.caster
	local ability = event.ability
	
	-- Check for spell block and spell immunity (latter because of lotus)
	if target:TriggerSpellAbsorb(ability) or target:IsMagicImmune() then
		return
	end

	local debuff_duration = ability:GetLevelSpecialValueFor("duration", ability:GetLevel() - 1)

	-- Apply the disarm
	local disarm_duration = target:GetValueChangedByStatusResistance(debuff_duration)
	ability:ApplyDataDrivenModifier(caster, target, "modifier_incapacitate_disarm", {["duration"] = disarm_duration})

	-- Apply the silence if caster has the talent
	local talent = caster:FindAbilityByName("special_bonus_unique_night_stalker")
	if talent and talent:GetLevel() > 0 then
		ability:ApplyDataDrivenModifier(caster, target, "modifier_incapacitate_silence", {["duration"] = debuff_duration})
	end
end
