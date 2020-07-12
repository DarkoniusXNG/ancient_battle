--[[ ============================================================================================================
	Called when Caster dies and has leveled this ability.  Untoggles this ability if its toggled on.
================================================================================================================= ]]
function elokvenciranost_on_owner_died(keys)
	if keys.ability:GetToggleState() == true then
		keys.ability:ToggleAbility()
		keys.caster:StopSound("Hero_Morphling.MorphAgility")
	end
end

--[[ ============================================================================================================
	Called when Caster toggles on this ability.  Applies a modifier, starts a sound, and toggles off
	other toggles if they are toggled on.
================================================================================================================= ]]
function elokvenciranost_on_toggle_on(keys)
	local other_toggle_ability = keys.caster:FindAbilityByName("mimic_revert")
	if other_toggle_ability ~= nil then
		if other_toggle_ability:GetToggleState() == true then
			other_toggle_ability:ToggleAbility()
		end
	end
	
	keys.ability:ApplyDataDrivenModifier(keys.caster, keys.caster, "modifier_elokvenciranost_toggled_on", {duration = -1})
	keys.caster:EmitSound("Hero_Morphling.MorphAgility")
end

--[[ ============================================================================================================
	Called when Caster toggles off this ability.  Removes a modifier and stops a sound.
================================================================================================================= ]]
function elokvenciranost_on_toggle_off(keys)
	keys.caster:RemoveModifierByName("modifier_elokvenciranost_toggled_on")
	keys.caster:StopSound("Hero_Morphling.MorphAgility")
end

--[[ ============================================================================================================
	Called at a regular interval while this ability is toggled on. Converts Intelligence into Agility, so long as
	Caster has the required mana.
	Additional parameters: keys.PointsPerTick, keys.ManaCostPerSecond, and keys.ShiftRate
================================================================================================================= ]]
function modifier_elokvenciranost_on_interval_think(keys)
	local mana_cost = keys.ManaCostPerSecond * keys.ShiftRate -- In this case its zero
	
	if keys.caster:IsRealHero() and keys.caster:GetMana() >= mana_cost then  --If Caster has the required mana.
		local intelligence_old = keys.caster:GetBaseIntellect()
		local agility_old = keys.caster:GetBaseAgility()
		keys.caster:SpendMana(mana_cost, keys.ability)
		if intelligence_old > 1 then
			local intelligence_new = 1
			local agility_new = agility_old + intelligence_old -1
			keys.caster:SetBaseIntellect(intelligence_new)
			keys.caster:SetBaseAgility(agility_new)
			keys.caster:CalculateStatBonus()  --This is needed to update Caster's bonuses from stats
		end
	end
end

function IntGain( keys )
	local caster = keys.caster
	local ability = keys.ability
	local intGainModifier = "modifier_elokvenciranost_int_gain_bonus"
	local intGainStackModifier = "modifier_elokvenciranost_int_gain_aura"
	local assists = caster:GetAssists()
	local kills = caster:GetKills()

	for i = 1, (assists + kills) do
		ability:ApplyDataDrivenModifier(caster, caster, intGainModifier, {})
		print("Current number: " .. i)
	end

	caster:SetModifierStackCount(intGainStackModifier, ability, (assists + kills))
end

--[[Increases the stack count of Int Gain.]]
function StackCountIncrease( keys )
	local caster = keys.caster
	local ability = keys.ability
	local intGainStackModifier = "modifier_elokvenciranost_int_gain_aura"
	local currentStacks = caster:GetModifierStackCount(intGainStackModifier, ability)

	caster:SetModifierStackCount(intGainStackModifier, ability, (currentStacks + 1))
end

function GiveInt ( keys )
	local gain_intelligence_old = keys.caster:GetBaseIntellect()
	local gain_intelligence_new = gain_intelligence_old + keys.IntGain
	keys.caster:SetBaseIntellect(gain_intelligence_new)
end
