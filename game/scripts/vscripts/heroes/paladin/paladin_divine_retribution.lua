-- Called OnDeath modifier_retribution_aura_effect
function RetributionStart(keys)
	local caster = keys.caster
	local unit = keys.unit
	local ability = keys.ability

	local buff_duration = ability:GetLevelSpecialValueFor("buff_duration", ability:GetLevel() - 1)
	local modifier_name = "modifier_retribution_buff"

	if caster and unit then
		if unit:IsRealHero() and caster:IsRealHero() then

			-- Sound on caster (owner of the aura)
			caster:EmitSound("Hero_Medusa.StoneGaze.Target")

			ability:ApplyDataDrivenModifier(caster, caster, modifier_name, {["duration"] = buff_duration})
		end
	end
end
