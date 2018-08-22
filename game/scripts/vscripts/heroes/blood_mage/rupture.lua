-- Called OnSpellStart
function RuptureStart(event)
	local target = event.target
	local caster = event.caster
	local ability = event.ability
	
	caster:EmitSound("Hero_Bloodseeker.Rupture.Cast")
	-- Checking if target has spell block, and if its an enemy
	if not target:TriggerSpellAbsorb(ability) then
		local ability_level = ability:GetLevel() - 1
		
		local rupture_duration = ability:GetLevelSpecialValueFor("duration", ability_level)
		ability:ApplyDataDrivenModifier(caster, target, "modifier_custom_rupture", {["duration"] = rupture_duration})
		
		target:EmitSound("Hero_Bloodseeker.Rupture")
		target:EmitSound("Hero_Bloodseeker.Rupture_FP")
	end
end
-- Checks the target's distance from its last position and deals damage accordingly
-- Called OnCreated and OnIntervalThink
function DistanceCheck(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	
	local damage_per_movement = ability:GetLevelSpecialValueFor("movement_damage_pct", ability_level)
	local distance_cap_amount = ability:GetLevelSpecialValueFor("distance_cap_amount", ability_level)
	local damage = 0
	
	if target.last_position_rupture ~= nil then
		local distance = (target.last_position_rupture - target:GetAbsOrigin()):Length2D()
	
		if distance <= distance_cap_amount and distance > 0 then
			damage = distance*damage_per_movement*0.01
		end
		
		if damage > 0 then
			ApplyDamage({victim = target, attacker = caster, damage = damage, damage_type = ability:GetAbilityDamageType()})
		end
	end
	if IsValidEntity(target) then
		if target:IsAlive() then
			target.last_position_rupture = target:GetAbsOrigin()
		end
	end
end

-- Called OnDestroy
function RuptureEnd(keys)
	local target = keys.target
	target.last_position_rupture = nil
	target:StopSound("Hero_Bloodseeker.Rupture_FP")
end