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
		
			-- Targetting constants
			local target_team = ability:GetAbilityTargetTeam() or DOTA_UNIT_TARGET_TEAM_ENEMY
			local target_type = ability:GetAbilityTargetType() or bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
			local target_flags = ability:GetAbilityTargetFlags() or DOTA_UNIT_TARGET_FLAG_NONE
			
			-- Apply debuff to enemies in a radius around the target
			local enemies = FindUnitsInRadius(caster_team, target_pos, nil, radius, target_team, target_type, target_flags, FIND_ANY_ORDER, false)
			for _, enemy in pairs(enemies) do
				ability:ApplyDataDrivenModifier(caster, enemy, "modifier_custom_acid_bomb_debuff", {["duration"] = debuff_duration})
			end
		end
	end
end
