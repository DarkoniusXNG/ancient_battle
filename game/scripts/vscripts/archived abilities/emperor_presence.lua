function IntGain( keys )
	local caster = keys.caster
	local ability = keys.ability
	local intGainModifier = "modifier_int_gain_bonus"
	local intGainStackModifier = "modifier_int_gain_aura"
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
	local intGainStackModifier = "modifier_int_gain_aura"
	local currentStacks = caster:GetModifierStackCount(intGainStackModifier, ability)

	caster:SetModifierStackCount(intGainStackModifier, ability, (currentStacks + 1))
end