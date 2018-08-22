-- Called OnProjectileHitUnit
function DrunkenHazeStart(event)
	local target = event.target
	local caster = event.caster
	local ability = event.ability
	
	-- Checking if target has spell block, if target has spell block, there is no need to execute the spell
	if not target:TriggerSpellAbsorb(ability) then
		local ability_level = ability:GetLevel() - 1
		local hero_duration = ability:GetLevelSpecialValueFor("duration_heroes", ability_level)
		local creep_duration = ability:GetLevelSpecialValueFor("duration_creeps", ability_level)
		local radius = ability:GetLevelSpecialValueFor("radius", ability_level)
		local caster_team = caster:GetTeamNumber() -- GetTeam()
		local target_location = target:GetAbsOrigin()
		
		local enemies = FindUnitsInRadius(caster_team, target_location, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, 0, 0, false)
		
		for k, unit in pairs(enemies) do
			-- If the target didn't become spell immune in the same frame as projectile hit then apply the debuff
			if not unit:IsMagicImmune() then
				if unit:IsRealHero() then
					ability:ApplyDataDrivenModifier(caster, unit, "modifier_custom_drunken_haze_debuff", {["duration"] = hero_duration})
				else
					ability:ApplyDataDrivenModifier(caster, unit, "modifier_custom_drunken_haze_debuff", {["duration"] = creep_duration})
				end
			end
		end
	end
end