-- Called OnSpellStart
function ConjureImage(event)
	local target = event.target
	local caster = event.caster
	local ability = event.ability
	
	local caster_team = caster:GetTeamNumber()
	-- Checking if target has spell block, if target has spell block, there is no need to execute the spell
	if (not target:TriggerSpellAbsorb(ability)) or (target:GetTeamNumber() == caster_team) then
		-- Target is a friend or an enemy that doesn't have Spell Block
		local ability_level = ability:GetLevel() - 1
		
		local duration = ability:GetLevelSpecialValueFor("duration", ability_level)
		local damage_dealt = ability:GetLevelSpecialValueFor("illusion_damage_out", ability_level)
		local damage_taken = ability:GetLevelSpecialValueFor("illusion_damage_in", ability_level)
		
		target:CreateIllusion(caster, ability, duration, nil, damage_dealt, damage_taken)
	end
end
