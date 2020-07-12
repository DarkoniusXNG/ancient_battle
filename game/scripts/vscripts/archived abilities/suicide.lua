﻿--[[Author: Pizzalol (modified by Darkonius)
	Removes the exception modifiers and kills the caster]]
function Suicide( keys )
	local caster = keys.caster
	local caster_location = caster:GetAbsOrigin()
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	-- Ability variables
	local vision_radius = ability:GetLevelSpecialValueFor("vision_radius", ability_level) 
	local vision_duration = ability:GetLevelSpecialValueFor("vision_duration", ability_level)

	-- Insert modifiers into the table that would otherwise prevent a units death
	local exception_table = {}
	table.insert(exception_table, "modifier_dazzle_shallow_grave")
	table.insert(exception_table,"modifier_charmed_cloned_hero")
	--table.insert(exception_table,"modifier_false_promise") -- check the name of the modifier
	
	-- Remove the modifiers if they exist
	local modifier_count = caster:GetModifierCount()
	for i = 0, modifier_count do
		local modifier_name = caster:GetModifierNameByIndex(i)
		local modifier_check = false

		-- Compare if the modifier is in the exception table
		-- If it is then set the helper variable to true and breaks the 'for' block
		for j = 0, #exception_table do
			if exception_table[j] == modifier_name then
				modifier_check = true
				break
			end
		end

		-- Remove the modifier depending on the helper variable
		if modifier_check then
			caster:RemoveModifierByName(modifier_name)
		end
	end

	-- Create the vision and kill the caster
	ability:CreateVisibilityNode(caster_location, vision_radius, vision_duration)
	caster:Kill(ability, caster)
end