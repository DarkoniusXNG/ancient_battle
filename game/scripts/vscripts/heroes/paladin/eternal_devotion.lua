-- Called OnDestroy modifier_eternal_devotion_guardian_angel_spawn_passive
function EternalDevotionCheck(keys)
	local caster = keys.caster
	local ability = keys.ability
	
	local ability_level = ability:GetLevel() - 1
	local buff_duration = ability:GetLevelSpecialValueFor("buff_duration", ability_level)
	local radius = ability:GetLevelSpecialValueFor("buff_radius", ability_level)
	
	if caster then
		local talent = caster:FindAbilityByName("special_bonus_unique_omniknight_1")
		local caster_team = caster:GetTeamNumber()
		local caster_pos = caster:GetAbsOrigin()
		
		if caster:IsRealHero() then
			if talent then
				if talent:GetLevel() ~= 0 then
					radius = 20000
				end
			end
			
			local allies = FindUnitsInRadius(caster_team, caster_pos, nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 0, 0, false)
			for k, ally in pairs(allies) do
				ability:ApplyDataDrivenModifier(caster, ally, "modifier_guardian_angel_buff", {["duration"] = buff_duration})
			end
		end
	end
end