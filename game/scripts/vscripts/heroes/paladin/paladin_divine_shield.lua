-- Called OnSpellStart
function DivineShield(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability

	local shield_duration = ability:GetLevelSpecialValueFor("shield_duration", ability:GetLevel() - 1)

	-- Strong Dispel (Debuffs and Stuns)
	local RemovePositiveBuffs = false
	local RemoveDebuffs = true
	local BuffsCreatedThisFrameOnly = false
	local RemoveStuns = true
	local RemoveExceptions = false
	target:Purge(RemovePositiveBuffs, RemoveDebuffs, BuffsCreatedThisFrameOnly, RemoveStuns, RemoveExceptions)

	-- Checking if the caster has Aghanim Scepter or not and applying modifiers accordingly
	if caster:HasScepter() then
		SuperStrongDispel(target, true, false)
		ability:ApplyDataDrivenModifier(caster, target, "modifier_paladin_divine_shield_upgraded", {["duration"] = shield_duration})
	else
		ability:ApplyDataDrivenModifier(caster, target, "modifier_paladin_divine_shield", {["duration"] = shield_duration})
	end
end
