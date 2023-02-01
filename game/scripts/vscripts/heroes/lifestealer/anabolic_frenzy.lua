-- Called OnSpellStart
function AnabolicFrenzyStart(event)
	local target = event.target
	local caster = event.caster
	local ability = event.ability
	local duration = ability:GetLevelSpecialValueFor("duration", ability:GetLevel() - 1)

	-- This check must be before spell block check
	if caster:GetUnitName() ~= "npc_dota_hero_life_stealer" then
		caster:RemoveModifierByName("modifier_anabolic_frenzy_passive")
	end

	-- Check for spell block and spell immunity (latter because of lotus)
	if target:TriggerSpellAbsorb(ability) or target:IsMagicImmune() then
		return
	end

	ability:ApplyDataDrivenModifier(caster, target, "modifier_anabolic_frenzy_slow", {["duration"] = duration})
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_anabolic_frenzy_active", {["duration"] = duration})
end
