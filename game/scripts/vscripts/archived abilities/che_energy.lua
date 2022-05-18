-- Called when ability is learned / upgraded; It runs only on level 1
function rocket_start_charge( keys )
	-- Only start charging at level 1; it runs only on level 1
	if keys.ability:GetLevel() ~= 1 then return end

	-- Variables
	local caster = keys.caster
	local ability = keys.ability
	local modifierName = "modifier_rocket_stack_counter"
	local maximum_charges = ability:GetLevelSpecialValueFor( "maximum_charges", ( ability:GetLevel() - 1 ) )
	local charge_replenish_time = ability:GetLevelSpecialValueFor( "charge_replenish_time", ( ability:GetLevel() - 1 ) )
	
	-- Initialize stack
	caster:SetModifierStackCount( modifierName, caster, 0 )
	caster.rocket_charges = maximum_charges
	caster.start_charge = false
	caster.rocket_cooldown = 0.0
	
	ability:ApplyDataDrivenModifier( caster, caster, modifierName, {} )
	caster:SetModifierStackCount( modifierName, caster, maximum_charges )
	
	-- create timer to restore stack
	Timers:CreateTimer( function()
			-- Restore charge
			if caster.start_charge and caster.rocket_charges < maximum_charges then
				-- Calculate stacks
				local next_charge = caster.rocket_charges + 1
				caster:RemoveModifierByName( modifierName )
				if next_charge ~= maximum_charges  then
					ability:ApplyDataDrivenModifier( caster, caster, modifierName, { Duration = charge_replenish_time } )
					rocket_start_cooldown( caster, charge_replenish_time )
				else
					ability:ApplyDataDrivenModifier( caster, caster, modifierName, {} )
					caster.start_charge = false
				end
				caster:SetModifierStackCount( modifierName, caster, next_charge )
				
				-- Update stack
				caster.rocket_charges = next_charge
			end
			
			-- Check if max is reached then check every 0.5 seconds if the charge is used
			if caster.rocket_charges ~= maximum_charges then
				caster.start_charge = true
				return charge_replenish_time
			else
				return 0.5
			end
		end
	)
end

function rocket_start_cooldown( caster, charge_replenish_time )
	caster.rocket_cooldown = charge_replenish_time
	Timers:CreateTimer( function()
			local current_cooldown = caster.rocket_cooldown - 0.1
			if current_cooldown > 0.1 then
				caster.rocket_cooldown = current_cooldown
				return 0.1
			else
				return nil
			end
		end
	)
end

-- Called OnSpellStart
function rocket_fire( keys )
	-- Reduce stack if more than 0 else refund mana
	if keys.caster.rocket_charges and keys.caster.rocket_charges > 0 then
		-- variables
		local caster = keys.caster
		local ability = keys.ability
		local modifierName = "modifier_rocket_stack_counter"
		local maximum_charges = ability:GetLevelSpecialValueFor( "maximum_charges", ( ability:GetLevel() - 1 ) )
		local charge_replenish_time = ability:GetLevelSpecialValueFor( "charge_replenish_time", ( ability:GetLevel() - 1 ) )
		
		-- Deplete charge
		local next_charge = caster.rocket_charges - 1
		if caster.rocket_charges == maximum_charges then
			caster:RemoveModifierByName( modifierName )
			ability:ApplyDataDrivenModifier( caster, caster, modifierName, { Duration = charge_replenish_time } )
			rocket_start_cooldown( caster, charge_replenish_time )
		end
		caster:SetModifierStackCount( modifierName, caster, next_charge )
		caster.rocket_charges = next_charge
		
		-- Check if stack is 0, display ability cooldown
		if caster.rocket_charges == 0 then
			-- Start Cooldown
			ability:StartCooldown( caster.rocket_cooldown )
		else
			ability:EndCooldown()
		end
	else
		keys.ability:RefundManaCost()
	end
end