-- Called OnSpellStart
function TimeStopStart(event)
	local target = event.target
	local caster = event.caster
	local ability = event.ability
	local modifier = event.time_stop_modifier

	local ability_level = ability:GetLevel() - 1

	local duration = ability:GetLevelSpecialValueFor("duration", ability_level)

	-- Checking if the caster has Aghanim Scepter
	if caster:HasScepter() then
		duration = ability:GetLevelSpecialValueFor("duration_scepter", ability_level)
	end

	-- Check if a target is a caster's controlled unit, Void Demon, Faceless Void or Astral Trekker (with Time Constant)
	if caster:GetPlayerOwner() == target:GetPlayerOwner() or target:GetName() == "npc_dota_hero_night_stalker" or target:GetName() == "npc_dota_hero_faceless_void" or (target:HasModifier("modifier_time_constant") and not target:PassivesDisabled()) then
		-- print("Time independent being detected.")
		return
	end

	-- Interrupt things like Force staff
	target:InterruptMotionControllers(false)

	ability:ApplyDataDrivenModifier(caster, target, modifier, {duration = duration})

	if caster:HasScepter() and target:GetTeamNumber() ~= caster:GetTeamNumber() then
		modifier = "modifier_time_stop_scepter"
		ability:ApplyDataDrivenModifier(caster, target, modifier, {duration = duration})
	end
	--target:AddNewModifier(caster, ability, "modifier_faceless_void_chronosphere_freeze", {duration = duration})

end

-- Called OnCreated and OnIntervalThink (every second)
function CooldownFreeze(keys)
	local target = keys.target
	
	-- Adds 1 second to the current cooldown to every spell off cooldown
	for i = 0, target:GetAbilityCount()-1 do
		local target_ability = target:GetAbilityByIndex(i)
		if target_ability then
			local cd = target_ability:GetCooldownTimeRemaining()
			if cd > 0 then
				target_ability:StartCooldown(cd + 1)
			end
		end
	end
end
