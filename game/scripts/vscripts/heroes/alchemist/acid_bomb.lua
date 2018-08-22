-- Called OnProjectileHitUnit
function AcidBombStart(event)
	local target = event.target
	local caster = event.caster
	local ability = event.ability
	local ability_level = ability:GetLevel() - 1
	
	local caster_team = caster:GetTeamNumber()
	local target_pos = target:GetAbsOrigin()
	
	local stun_duration = ability:GetLevelSpecialValueFor("stun_duration", ability_level)
	local debuff_duration = ability:GetLevelSpecialValueFor("debuff_duration", ability_level)
	local radius = ability:GetLevelSpecialValueFor("radius", ability_level)
	
	-- Checking if target has spell block, if target has spell block, there is no need to execute the spell
	if not target:TriggerSpellAbsorb(ability) then
		-- Apply a stun to the main target if he didnt become spell immune during projectile flight
		if not target:IsMagicImmune() then
			ability:ApplyDataDrivenModifier(caster, target, "modifier_custom_acid_bomb_stun", {["duration"] = stun_duration})
			target:Interrupt()
		
			-- Apply debuff to enemies in a radius around the target
			local enemies = FindUnitsInRadius(caster_team, target_pos, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, 0, 0, false)
			for k, enemy in pairs(enemies) do
				if not enemy:IsMagicImmune() then
					ability:ApplyDataDrivenModifier(caster, enemy, "modifier_custom_acid_bomb_debuff", {["duration"] = debuff_duration})
				end
			end
		end
	end
end