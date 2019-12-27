-- Called OnSpellStart
function SoulBurnStart(event)
	local target = event.target
	local caster = event.caster
	local ability = event.ability
	local ability_level = ability:GetLevel() - 1

	local hero_duration = ability:GetLevelSpecialValueFor("hero_duration", ability_level)
	local creep_duration = ability:GetLevelSpecialValueFor("creep_duration", ability_level)

	-- Checking if target is an enemy 
	if target:GetTeamNumber() ~= caster:GetTeamNumber() then
		-- Checking if target has spell block
		if not target:TriggerSpellAbsorb(ability) then
			if target:IsRealHero() then
				ability:ApplyDataDrivenModifier(caster, target, "modifier_soul_burn", {["duration"] = hero_duration})
			else
				ability:ApplyDataDrivenModifier(caster, target, "modifier_soul_burn", {["duration"] = creep_duration})
			end
		end
	else
		local buff_duration = ability:GetLevelSpecialValueFor("buff_duration", ability_level)
		local cooldown_allies = ability:GetLevelSpecialValueFor("cooldown_allies", ability_level)

		ability:ApplyDataDrivenModifier(caster, target, "modifier_soul_buff", {["duration"] = buff_duration})
		local cdr = caster:GetCooldownReduction()
		ability:EndCooldown()
		ability:StartCooldown(cdr*cooldown_allies)
	end
end
