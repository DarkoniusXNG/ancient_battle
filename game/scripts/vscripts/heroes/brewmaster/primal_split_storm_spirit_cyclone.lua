-- Called OnSpellStart
function Cyclone(event)
	local target = event.target
	local caster = event.caster
	local ability = event.ability
	
	-- Checking if target has spell block, if target has spell block, there is no need to execute the spell
	if not target:TriggerSpellAbsorb(ability) then
		local ability_level = ability:GetLevel() - 1
		local hero_duration = ability:GetLevelSpecialValueFor("duration_hero", ability_level)
		local creep_duration = ability:GetLevelSpecialValueFor("duration_creeps", ability_level)
		
		-- Play sound
		target:EmitSound("Brewmaster_Storm.Cyclone")
		
		if target:IsRealHero() then
			--ability:ApplyDataDrivenModifier(caster, target, "modifier_custom_cyclone", {["duration"] = hero_duration})
			target:AddNewModifier(caster, ability, "modifier_brewmaster_storm_cyclone", {duration=hero_duration})
		else
			target:AddNewModifier(caster, ability, "modifier_brewmaster_storm_cyclone", {duration=creep_duration})
		end
	end
end