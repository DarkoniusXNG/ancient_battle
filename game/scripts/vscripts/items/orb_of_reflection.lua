-- Called OnSpellStart
function Reflect(keys)
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local buff_duration = ability:GetLevelSpecialValueFor("reflect_duration", ability_level)
	
	-- Basic Dispel (Removes normal debuffs)
	local RemovePositiveBuffs = false
	local RemoveDebuffs = true
	local BuffsCreatedThisFrameOnly = false
	local RemoveStuns = false
	local RemoveExceptions = false
	caster:Purge(RemovePositiveBuffs, RemoveDebuffs, BuffsCreatedThisFrameOnly, RemoveStuns, RemoveExceptions)
	
	caster:AddNewModifier(caster, ability, "modifier_item_lotus_orb_active", {duration = buff_duration})
end
