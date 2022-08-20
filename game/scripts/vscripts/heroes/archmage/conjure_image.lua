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

		--target:CreateIllusion(caster, ability, duration, nil, damage_dealt, damage_taken)
		
		local gold_bounty_base = 1
		if caster:HasScepter() and target:GetTeamNumber() ~= caster_team then
			gold_bounty_base = 180
		end

		illusion_table = {}
		illusion_table.outgoing_damage = damage_dealt
		illusion_table.incoming_damage = damage_taken
		illusion_table.bounty_base = gold_bounty_base
		illusion_table.bounty_growth = 4
		illusion_table.outgoing_damage_structure = damage_dealt
		illusion_table.outgoing_damage_roshan = damage_dealt
		illusion_table.duration = duration

		local padding = 108

		local illusions = CreateIllusions(caster, target, illusion_table, 1, padding, true, true)
		for _, illu in pairs(illusions) do
			if illu then
				illu:AddNewModifier(caster, ability, "modifier_custom_strong_illusion", {})
				-- Scepter super illusion
				if caster:HasScepter() and target:GetTeamNumber() ~= caster_team then
					illu:AddNewModifier(caster, ability, "modifier_vengefulspirit_hybrid_special", {})
				end
			end
		end
	end
end
