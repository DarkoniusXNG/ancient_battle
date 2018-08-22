-- Called OnSpellStart
function SoulBurnStart(event)
	local target = event.target
	local caster = event.caster
	local ability = event.ability
	local ability_level = ability:GetLevel() - 1
	
	local hero_duration = ability:GetLevelSpecialValueFor("hero_duration", ability_level)
	local creep_duration = ability:GetLevelSpecialValueFor("creep_duration", ability_level)
		
	-- Checking if target is an enemy and if it has spell block
	if not target:TriggerSpellAbsorb(ability) and target:GetTeamNumber() ~= caster:GetTeamNumber()  then
		if target:IsRealHero() then
			ability:ApplyDataDrivenModifier(caster, target, "modifier_soul_burn", {["duration"] = hero_duration})
		else
			ability:ApplyDataDrivenModifier(caster, target, "modifier_soul_burn", {["duration"] = creep_duration})
		end
	end
end