-- Called OnIntervalThink; Adds all base intelligence to base strength.
function ScepterBuff(keys)
	local caster = keys.caster
	if caster:IsRealHero() and caster:HasScepter() then
		local intelligence_old = caster:GetBaseIntellect()
		local strength_old = caster:GetBaseStrength()
		
		if (caster.old_strength == nil) and (caster.old_level == nil) then
			-- This will happen only when the modifier is created
			caster.old_strength = strength_old
			caster.old_level = caster:GetLevel()
		end
		if intelligence_old > 1 then
			local intelligence_new = 1
			local strength_new = strength_old + intelligence_old - 1
			caster:SetBaseIntellect(intelligence_new)
			caster:SetBaseStrength(strength_new)
			caster:CalculateStatBonus()  -- This is needed to update Caster's bonuses from stats
		end
	end	
end
-- Called OnDestroy (and OnDeath); Reverts everything back if needed
function ScepterBuffEnd(keys)
	local caster = keys.caster
	if caster:IsRealHero() and caster.old_strength and caster.old_level then
		local level = caster:GetLevel()
		local StrGain = caster:GetStrengthGain()
		
		local strength_old = caster.old_strength
		local level_old = caster.old_level
		caster.old_strength = nil
		caster.old_level = nil
		
		local level_difference = level - level_old -- caster can level up during the duration of the modifier
		local strength_new = strength_old + level_difference*StrGain
		local intelligence_new = caster:GetBaseStrength() - strength_new + 1
		
		caster:SetBaseIntellect(intelligence_new)
		caster:SetBaseStrength(strength_new)
		caster:CalculateStatBonus()
	end
end
