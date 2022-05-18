-- Called OnDestroy modifier_eternal_devotion_guardian_angel_spawn_passive
function EternalDevotionCheck(keys)
	local caster = keys.caster
	local ability = keys.ability
	
	local ability_level = ability:GetLevel() - 1
	local buff_duration = ability:GetLevelSpecialValueFor("buff_duration", ability_level)
	local radius = ability:GetLevelSpecialValueFor("buff_radius", ability_level)
	
	if caster then
		local talent_1 = caster:FindAbilityByName("special_bonus_unique_paladin_2")
		local talent_2 = caster:FindAbilityByName("special_bonus_unique_paladin_5")
		local caster_team = caster:GetTeamNumber()
		local caster_pos = caster:GetAbsOrigin()
		
		if caster:IsRealHero() then
			-- Check if caster has the global talent
			if talent_1 and talent_1:GetLevel() > 0 then
				radius = FIND_UNITS_EVERYWHERE
			end
			
			-- Check if caster has Wrath of God talent
			local wrath_of_god = false
			if talent_2 and talent_2:GetLevel() > 0 then
				wrath_of_god = true
			end
			
			local target_type = bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BUILDING)
			local target_flags = DOTA_UNIT_TARGET_FLAG_NONE
			
			local allies = FindUnitsInRadius(caster_team, caster_pos, nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, target_type, target_flags, FIND_ANY_ORDER, false)
			for _, ally in pairs(allies) do
				ability:ApplyDataDrivenModifier(caster, ally, "modifier_guardian_angel_buff", {["duration"] = buff_duration})
			end
			
			if wrath_of_god then
				target_type = bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
				target_flags = bit.bor(DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS, DOTA_UNIT_TARGET_FLAG_NOT_ATTACK_IMMUNE)
				local enemies = FindUnitsInRadius(caster_team, caster_pos, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, target_type, target_flags, FIND_ANY_ORDER, false)
				--local angel_dmg = ability:GetLevelSpecialValueFor("angel_damage", ability_level) -- not needed because of modifier_guardian_angel_summoned_buff
				for _, enemy in pairs(enemies) do
					local position = enemy:GetAbsOrigin()

					-- Create an angel at the enemy position
					local angel = CreateUnitByName("npc_dota_summoned_guardian_angel", position, true, caster, caster:GetOwner(), caster_team)
					FindClearSpaceForUnit(angel, position, false)
					--angel:SetControllableByPlayer(playerID, false) -- uncontrollable on purpose
					angel:SetOwner(caster)
					--angel:SetBaseDamageMin(angel_dmg) -- not needed because of modifier_guardian_angel_summoned_buff
					--angel:SetBaseDamageMax(angel_dmg) -- not needed because of modifier_guardian_angel_summoned_buff
					
					angel:AddNewModifier(caster, ability, "modifier_kill", {duration = buff_duration})

					-- Apply angel buff
					ability:ApplyDataDrivenModifier(caster, angel, "modifier_guardian_angel_summoned_buff", {["duration"] = buff_duration})
					
					-- Order the angel to attack the enemy
					angel:SetForceAttackTarget(enemy)
				end
			end
		end
	end
end
