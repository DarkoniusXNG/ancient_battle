-- Called OnSpellStart
function ElectromagneticPulse(keys)
	local caster = keys.caster
	local ability = keys.ability

	local ability_level = ability:GetLevel() - 1

	local mana_to_burn_percent = ability:GetLevelSpecialValueFor("mana_burned", ability_level)
	local delay = ability:GetLevelSpecialValueFor("delay", ability_level)
	local radius = ability:GetLevelSpecialValueFor("radius", ability_level)
	local damage_per_burned_mana_percent = ability:GetLevelSpecialValueFor("damage_per_mana_burned", ability_level)
	local mana_gained_percent = ability:GetLevelSpecialValueFor("mana_gained_per_mana_burned", ability_level)

	-- Sounds
	caster:EmitSound("Hero_Invoker.EMP.Cast")
	caster:EmitSound("Hero_Invoker.EMP.Charge")

	-- Particles
	local emp_effect = ParticleManager:CreateParticle("particles/units/heroes/hero_invoker/invoker_emp.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)

	-- Explode the EMP after the delay has passed.
	Timers:CreateTimer({
		endTime = delay,
		callback = function()
			ParticleManager:DestroyParticle(emp_effect, false)
			ParticleManager:ReleaseParticleIndex(emp_effect)
			local emp_explosion_effect = ParticleManager:CreateParticle("particles/units/heroes/hero_invoker/invoker_emp_explode.vpcf", PATTACH_ABSORIGIN, caster)
			ParticleManager:ReleaseParticleIndex(emp_explosion_effect)

			caster:EmitSound("Hero_Invoker.EMP.Discharge")

			local target_type = bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)

			local nearby_enemy_units = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, target_type, DOTA_UNIT_TARGET_FLAG_MANA_ONLY, FIND_ANY_ORDER, false)
			for _, unit in pairs(nearby_enemy_units) do
				if unit then
					if unit:IsIllusion() and not unit:IsStrongIllusionCustom() then
						unit:Kill(ability, caster) -- This gives the kill credit to the caster
					else
						-- Calculating mana burn value
						local unit_current_mana = unit:GetMana()
						local unit_max_mana = unit:GetMaxMana()
						local mana_to_burn_on_unit = math.min(unit_current_mana, unit_max_mana*mana_to_burn_percent*0.01)

						-- Burning Mana (Reducing mana) of the unit
						unit:ReduceMana(mana_to_burn_on_unit, ability)

						-- Calculating damage and applying damage to the unit
						local damage_on_unit = damage_per_burned_mana_percent*mana_to_burn_on_unit
						ApplyDamage({victim = unit, attacker = caster, ability = ability, damage = damage_on_unit, damage_type = DAMAGE_TYPE_PURE})

						-- Restore some of the burnt mana to the caster
						local mana_gained_from_unit = mana_gained_percent*mana_to_burn_on_unit*0.01
						caster:GiveMana(mana_gained_from_unit)
					end
				end
			end
		end
	})
end
