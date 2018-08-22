-- Called OnOrbImpact (when orb attack lands on the target)
function IncinerateAttack(event)
	local caster = event.caster
	local target = event.target
	local ability = event.ability
	local modifier_name = "modifier_incinerate_stack"
	local damageType = ability:GetAbilityDamageType()
	local ability_level = ability:GetLevel() - 1

	local duration = ability:GetLevelSpecialValueFor("bonus_reset_time", ability_level)
	local damage_per_stack = ability:GetLevelSpecialValueFor("damage_per_stack", ability_level)
	
	-- If the unit has the modifier, increase the stack, else initialize it
	if IsValidEntity(target) then
		if target:HasModifier(modifier_name) then
			local current_stack = target:GetModifierStackCount(modifier_name, ability)
			
			local damage_value = damage_per_stack*(current_stack+1)
			
			local damage_table = {
				victim = target,
				attacker = caster,
				damage = damage_value,
				damage_type = damageType
			}
			
			ApplyDamage(damage_table)
			
			--if not target:IsNull() then
			if IsValidEntity(target) then
				ability:ApplyDataDrivenModifier(caster, target, modifier_name, {Duration = duration})
				target:SetModifierStackCount(modifier_name, ability, current_stack + 1)
			end
		else
			ability:ApplyDataDrivenModifier(caster, target, modifier_name, {Duration = duration})
			target:SetModifierStackCount(modifier_name, ability, 1)
			
			-- Deal damage of 1 stack
			local damage_table = {
				victim = target,
				attacker = caster,
				damage = damage_per_stack,
				damage_type = damageType
			}
			
			ApplyDamage(damage_table)
		end
	end
end