-- Called OnSpellStart
function AbsorbMana(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	
	-- Checking if target has spell block, if target has spell block, there is no need to execute the spell
	if not target:TriggerSpellAbsorb(ability) then
		if target:IsIllusion() then
			target:Kill(ability, caster) -- This gives the kill credit to the caster
		else
			local target_mana = target:GetMana()
			if target_mana > 0 then
				local mana_to_transfer_percent = ability:GetLevelSpecialValueFor("mana_transfered", ability:GetLevel() - 1)
				local mana_to_transfer = mana_to_transfer_percent*target_mana*0.01
				if caster:HasScepter() then
					local mana_to_transfer_percent_scepter = ability:GetLevelSpecialValueFor("mana_transfered_scepter", ability:GetLevel() - 1)
					mana_to_transfer = mana_to_transfer_percent_scepter*target_mana*0.01
					if caster:GetMaxMana() < mana_to_transfer then
						-- Adding bonus mana to the caster
						ability:ApplyDataDrivenModifier(caster, caster, "modifier_absorb_bonus_mana_scepter", {})
					end
				end
				-- Transfering mana
				target:ReduceMana(mana_to_transfer)
				caster:GiveMana(mana_to_transfer)
				-- Particles
				ability:ApplyDataDrivenModifier(caster, caster, "modifier_absorb_mana_caster", {})
				ability:ApplyDataDrivenModifier(caster, target, "modifier_absorb_mana_target", {})
				-- Sound
				target:EmitSound("Hero_Terrorblade.Sunder.Target")
			end
		end
	end
end