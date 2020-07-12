--[[ ============================================================================================================
	Called when Caster dies and has levelled Revert.  Untoggles Revert if it is toggled on.
================================================================================================================= ]]
function revert_on_owner_died(keys)
	if keys.ability:GetToggleState() == true then
		keys.ability:ToggleAbility()
		keys.caster:StopSound("Hero_Morphling.MorphStrengh")
	end
end

--[[ ============================================================================================================
	Called when Caster toggles on Revert.  Applies a modifier, starts a sound, and toggles off
	other toggles.
================================================================================================================= ]]
function revert_on_toggle_on(keys)
	local other_toggle_ability = keys.caster:FindAbilityByName("mimic_int_to_agi")
	if other_toggle_ability ~= nil then
		if other_toggle_ability:GetToggleState() == true then
			other_toggle_ability:ToggleAbility()
		end
	end
	
	keys.ability:ApplyDataDrivenModifier(keys.caster, keys.caster, "modifier_revert_toggled_on", {duration = -1})
	keys.caster:EmitSound("Hero_Morphling.MorphStrengh")
end

--[[ ============================================================================================================
	Called when Caster toggles off Revert.  Removes a modifier and stops a sound.
================================================================================================================= ]]
function revert_on_toggle_off(keys)
	keys.caster:RemoveModifierByName("modifier_revert_toggled_on")
	keys.caster:StopSound("Hero_Morphling.MorphStrengh")
end

--[[ ============================================================================================================
	Called at a regular interval while Revert is toggled on.  Converts Agility into Intelligence, as long as
	Caster has the required mana.
	Additional parameters: keys.PointsPerTick, keys.ManaCostPerSecond, and keys.ShiftRate
================================================================================================================= ]]
function modifier_revert_on_interval_think(keys)
	local mana_cost = keys.ManaCostPerSecond * keys.ShiftRate
	
	if keys.caster:IsRealHero() and keys.caster:GetMana() >= mana_cost then  --If Caster has the required mana.
		if keys.caster:GetBaseAgility() >= keys.PointsPerTick then
			keys.caster:SpendMana(mana_cost, keys.ability)  --Mana is not spent if Agility has bottomed out.
			keys.caster:SetBaseAgility(keys.caster:GetBaseAgility() - keys.PointsPerTick)
			keys.caster:SetBaseIntellect(keys.caster:GetBaseIntellect() + keys.PointsPerTick)
			keys.caster:CalculateStatBonus()  --This is needed to update Caster's stats
		end
	end
end