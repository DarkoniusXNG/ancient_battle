-- Called OnSpellStart
function BanishStart(event)
	local target = event.target
	local caster = event.caster
	local ability = event.ability
	
	-- Checking if target has spell block, and if its an enemy
	if not target:TriggerSpellAbsorb(ability) and target:GetTeamNumber() ~= caster:GetTeamNumber()  then
		local ability_level = ability:GetLevel() - 1
		
		local hero_duration = ability:GetLevelSpecialValueFor("hero_duration", ability_level)
		local creep_duration = ability:GetLevelSpecialValueFor("creep_duration", ability_level)
		
		if target:IsRealHero() then
			ability:ApplyDataDrivenModifier(caster, target, "modifier_banished_enemy", {["duration"] = hero_duration})
		else
			ability:ApplyDataDrivenModifier(caster, target, "modifier_banished_enemy", {["duration"] = creep_duration})
		end
	end
end
