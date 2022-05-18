-- Called on Spell Start
function Terrorize (event)
	local target = event.target
	local caster = event.caster
	local ability = event.ability
	local damageType = ability:GetAbilityDamageType()
	local silence_duration = ability:GetLevelSpecialValueFor( "silence_duration" , ability:GetLevel() - 1 )
	local disarm_duration = ability:GetLevelSpecialValueFor( "range_disarm_duration" , ability:GetLevel() - 1 )
	local creep_damage = ability:GetLevelSpecialValueFor( "base_damage" , ability:GetLevel() - 1 )
	local damage_per_missing_mana_multiplier = ability:GetLevelSpecialValueFor( "damage_per_mana_missing" , ability:GetLevel() - 1 )
	local int_difference_multiplier = ability:GetLevelSpecialValueFor( "int_difference_multiplier" , ability:GetLevel() - 1 )
	local agi_multiplier = ability:GetLevelSpecialValueFor( "agi_multiplier" , ability:GetLevel() - 1 )
	local caster_agi = caster:GetAgility()
	local caster_int = caster:GetIntellect()
	local damage_table = {}
	damage_table.attacker = caster
	damage_table.victim = target
	damage_table.damage_type = damageType
	damage_table.ability = ability	
	
	-- Checking if target has spell block, if target has spell block, there is no need to execute the spell
	if not target:TriggerSpellAbsorb( ability ) then
		--print("Target doesn't have Spell Block.")
		if target:IsHero() then
			if target:IsRealHero() then
				if caster_agi > caster_int then
					ability:ApplyDataDrivenModifier(caster, target, "modifier_terrified", {["duration"] = silence_duration})
					damage_table.damage = damage_per_missing_mana_multiplier * (target:GetMaxMana() - target:GetMana()) + agi_multiplier * caster_agi
					ApplyDamage(damage_table)
				else
					local target_int = target:GetIntellect()
					if target:IsRangedAttacker() then
						ability:ApplyDataDrivenModifier(caster, target, "modifier_terror_disarmed", {["duration"] = disarm_duration})
					end
					damage_table.damage = damage_per_missing_mana_multiplier * (target:GetMaxMana() - target:GetMana())
					if caster_int > target_int then
						damage_table.damage = damage_table.damage + int_difference_multiplier * (caster_int - target_int)
					end
					ApplyDamage(damage_table)
				end
				--print("Target is a Real Hero.")
			else
				damage_table.damage = creep_damage
				ApplyDamage(damage_table)
				--print("Target is an Illusion of a Hero.")
			end
		else
			--print("Target is a creep.")
			damage_table.damage = creep_damage
			if not target:IsRangedAttacker() then
				ability:ApplyDataDrivenModifier(caster, target, "modifier_terrified", {["duration"] = silence_duration})
				--print("Target is not Ranged.")
			else
				ability:ApplyDataDrivenModifier(caster, target, "modifier_terror_disarmed", {["duration"] = disarm_duration})
				--print("Target is a ranged unit.")
			end
			ApplyDamage(damage_table)
		end
		caster:EmitSound("Hero_Puck.Waning_Rift")
	else
		--print("Target have Spell Block")
	end
end