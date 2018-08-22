-- Called OnSpellStart
function TimeStopStart(keys)
	local target = keys.target
	local caster = keys.caster
	local ability = keys.ability
	local modifier = keys.time_stop_modifier
	
	local duration = ability:GetLevelSpecialValueFor("duration", ability:GetLevel() - 1)
	-- Checking if the caster has Aghanim Scepter
	if caster:HasScepter() then
		duration = ability:GetLevelSpecialValueFor("duration_scepter", ability:GetLevel() - 1)
	end
	
	-- Check if a target is a caster's controlled unit, Void Demon, Faceless Void or Astral Trekker(with Time Constant)
	if (caster:GetPlayerOwner() == target:GetPlayerOwner()) or (target:GetName() == "npc_dota_hero_night_stalker") or (target:GetName() == "npc_dota_hero_faceless_void") or (target:HasModifier("modifier_time_constant")) then
		-- print("Time independent being detected.")
	else
		target:InterruptMotionControllers(false) -- this interrupts things like Force staff
		ability:ApplyDataDrivenModifier(caster, target, modifier, {duration = duration})
		if caster:HasScepter() and target:GetTeamNumber() ~= caster:GetTeamNumber() then
			modifier = "modifier_time_stop_scepter"
			ability:ApplyDataDrivenModifier(caster, target, modifier, {duration = duration})
		end
		--target:AddNewModifier(caster, ability, "modifier_faceless_void_chronosphere_freeze", {duration = duration})
	end
end

-- Called OnCreated and OnIntervalThink (every second)
function CooldownFreeze(keys)
	local target = keys.target
	
	-- Adds 1 second to the current cooldown to every spell off cooldown
	for i=0, 15 do
		local target_ability = target:GetAbilityByIndex(i)
		if target_ability then
			local cd = target_ability:GetCooldownTimeRemaining()
			if cd > 0 then
				target_ability:StartCooldown(cd + 1)
			end
		end
	end
end