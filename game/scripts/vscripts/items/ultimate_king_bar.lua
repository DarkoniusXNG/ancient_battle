-- Called OnSpellStart
function BKBPurge(keys)
    local caster = keys.caster

	-- Basic dispel
	local RemovePositiveBuffs = false
	local RemoveDebuffs = true
	local BuffsCreatedThisFrameOnly = false
	local RemoveStuns = false
	local RemoveExceptions = false

    caster:Purge(RemovePositiveBuffs, RemoveDebuffs, BuffsCreatedThisFrameOnly, RemoveStuns, RemoveExceptions)
end
