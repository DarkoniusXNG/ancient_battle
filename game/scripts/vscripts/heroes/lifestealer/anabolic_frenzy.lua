-- Called OnSpellStart
function AnabolicFrenzyStart(event)
	local target = event.target
	local caster = event.caster
	local ability = event.ability
	local duration = ability:GetLevelSpecialValueFor("duration", ability:GetLevel() - 1)

	-- Checking if target has spell block, if target has spell block, there is no need to execute the spell
	if not target:TriggerSpellAbsorb(ability) and not target:IsMagicImmune() then
		ability:ApplyDataDrivenModifier(caster, target, "modifier_anabolic_frenzy_slow", {["duration"] = duration})
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_anabolic_frenzy_active", {["duration"] = duration})

		if caster:GetName() ~= "npc_dota_hero_life_stealer" then
			caster:RemoveModifierByName("modifier_anabolic_frenzy_passive")
		end
	end
end
