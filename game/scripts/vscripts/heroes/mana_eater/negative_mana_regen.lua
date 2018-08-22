-- Called OnCreated and OnIntervalThink passive
function ChangeManaRegen(event)
    local caster = event.caster
	
	-- caster:GetStatsBasedManaRegen() is REMOVED!
	-- caster:GetConstantBasedManaRegen() is REMOVED!
	-- caster:GetPercentageBasedManaRegen() is REMOVED!
	-- caster:GetManaRegen() gives TOTAL MANA REGEN!
	local flat_mana_regen = caster:GetBonusManaRegen() 	-- This Mana regen is derived from constant bonuses like Basilius
	local mana_multiplier = caster:GetManaRegenMultiplier()
	local new_base_mana_regen = -5/mana_multiplier-flat_mana_regen
	
	caster:SetBaseManaRegen(new_base_mana_regen)
end