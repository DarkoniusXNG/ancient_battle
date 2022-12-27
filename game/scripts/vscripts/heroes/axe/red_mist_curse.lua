-- Called OnSpellStart
function RedMistCurse(event)
	local target = event.target
	local caster = event.caster
	local ability = event.ability
	local duration = ability:GetLevelSpecialValueFor("duration", ability:GetLevel() - 1)

	-- Check for spell block and spell immunity (latter because of lotus)
	if target:TriggerSpellAbsorb(ability) or target:IsMagicImmune() then
		return
	end

	ability:ApplyDataDrivenModifier(caster, target, "modifier_red_mist_curse_debuff", {["duration"] = duration})
end
