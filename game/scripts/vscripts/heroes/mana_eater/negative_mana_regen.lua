-- Called OnCreated and OnIntervalThink passive
function ChangeManaRegen(event)
    local caster = event.caster

	-- caster:GetStatsBasedManaRegen() is REMOVED!
	-- caster:GetConstantBasedManaRegen() is REMOVED!
	-- caster:GetPercentageBasedManaRegen() is REMOVED!
	-- caster:GetManaRegenMultiplier() is REMOVED!
	-- caster:GetManaRegen() gives TOTAL MANA REGEN!
	local flat_mana_regen = caster:GetBonusManaRegen() 	-- This Mana regen is derived from constant bonuses like Basilius

	--local intelligence = caster:GetIntellect()
	--local mana_regen_per_int = 0.05
	--local total_int_mana_regen = intelligence*mana_regen_per_int

	caster:SetBaseManaRegen(-5-flat_mana_regen)
end
