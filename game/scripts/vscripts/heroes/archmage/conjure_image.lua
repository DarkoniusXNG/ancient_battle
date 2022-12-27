-- Called OnSpellStart
function ConjureImage(event)
	local target = event.target
	local caster = event.caster
	local ability = event.ability

	local caster_team = caster:GetTeamNumber()
	-- Checking if target has spell block or if it's an ally; pierces spell immunity
	if (not target:TriggerSpellAbsorb(ability)) or (target:GetTeamNumber() == caster_team) then
		-- Target is a friend or an enemy that doesn't have Spell Block
		local ability_level = ability:GetLevel() - 1

		local duration = ability:GetLevelSpecialValueFor("duration", ability_level)
		local damage_dealt = ability:GetLevelSpecialValueFor("illusion_damage_out", ability_level)
		local damage_taken = ability:GetLevelSpecialValueFor("illusion_damage_in", ability_level)

		--target:CreateIllusion(caster, ability, duration, nil, damage_dealt, damage_taken)

		-- Scepter super illusion
		if caster:HasScepter() and target:GetTeamNumber() ~= caster_team and target:IsRealHero() and not caster:IsCloneCustom() and not caster:IsTempestDouble() and not target:IsCloneCustom() and not target:IsTempestDouble() then
			local gold_bounty_base = 180
			local actual_gold_bounty = gold_bounty_base + 4 * target:GetLevel()
			local copy = CopyHero(target, caster)
			copy:AddNewModifier(caster, ability, "modifier_custom_super_illusion", {mute = 1, attack_dmg_reduction = damage_dealt, bounty = actual_gold_bounty})
			copy:AddNewModifier(caster, ability, "modifier_kill", {duration = duration})
			return
		end

		local illusion_table = {}
		illusion_table.outgoing_damage = damage_dealt
		illusion_table.incoming_damage = damage_taken
		illusion_table.bounty_base = 1
		illusion_table.bounty_growth = 4
		illusion_table.outgoing_damage_structure = damage_dealt
		illusion_table.outgoing_damage_roshan = damage_dealt
		illusion_table.duration = duration

		local padding = 108

		local illusions = CreateIllusions(caster, target, illusion_table, 1, padding, true, true)
		for _, illu in pairs(illusions) do
			if illu then
				illu:AddNewModifier(caster, ability, "modifier_custom_strong_illusion", {})
				--illu:AddNewModifier(caster, ability, "modifier_vengefulspirit_hybrid_special", {}) -- teleports the caster to the target and removes the illusion, because caster is alive
				--illu:AddNewModifier(caster, ability, "modifier_arc_warden_tempest_double", {}) -- does nothing except arc warden tempest double tooltips and visual effect
			end
		end
	end
end
