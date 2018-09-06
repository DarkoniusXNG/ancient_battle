-- Called OnOrbImpact (when orb attack lands on the target)
function IncinerateAttack(event)
	local caster = event.caster
	local target = event.target
	local ability = event.ability
	local modifier_name = "modifier_incinerate_stack"
	local ability_level = ability:GetLevel() - 1

	local duration = ability:GetLevelSpecialValueFor("bonus_reset_time", ability_level)
	local damage_per_stack = ability:GetLevelSpecialValueFor("damage_per_stack", ability_level)
	
	-- If the unit has the modifier, increase the stack, else initialize it
	if IsValidEntity(target) then
	
		local damage_table = {}
		damage_table.attacker = caster
		damage_table.damage_type = ability:GetAbilityDamageType()
		damage_table.damage_flags = DOTA_DAMAGE_FLAG_BYPASSES_BLOCK
		damage_table.ability = ability
		damage_table.victim = target
		
		if target:HasModifier(modifier_name) then
			local current_stack = target:GetModifierStackCount(modifier_name, ability)
			
			damage_table.damage = damage_per_stack*(current_stack+1)
			
			ApplyDamage(damage_table)
			
			if IsValidEntity(target) then
				ability:ApplyDataDrivenModifier(caster, target, modifier_name, {Duration = duration})
				target:SetModifierStackCount(modifier_name, ability, current_stack + 1)
			end
		else
			ability:ApplyDataDrivenModifier(caster, target, modifier_name, {Duration = duration})
			target:SetModifierStackCount(modifier_name, ability, 1)
			
			-- Deal damage of 1 stack
			damage_table.damage = damage_per_stack
			
			ApplyDamage(damage_table)
		end
	end
end
