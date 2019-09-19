-- Called OnSpellStart
-- Purges summons and illusions, dispels buffs from enemies, dispels debuffs from allies and slows everything in the area
function Negate(keys)
	local point = keys.target_points[1]
	local caster = keys.caster
	local caster_team = caster:GetTeamNumber()
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local radius = ability:GetLevelSpecialValueFor("radius", ability_level)
	local summon_damage = 99999
	local blink_disable_damage = 50

	-- Targetting constants
	local target_type = bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
	local target_flags = DOTA_UNIT_TARGET_FLAG_INVULNERABLE

	-- Apply the slow modifier and purge enemies around point and kill all summons and illusions
	local enemies = FindUnitsInRadius(caster_team, point, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, target_type, target_flags, 0, false)
	for k, enemy in pairs(enemies) do
		if enemy then
			enemy:RemoveModifierByName("modifier_brewmaster_storm_cyclone")
			enemy:RemoveModifierByName("modifier_eul_cyclone")

			-- Basic Dispel (Removes Buffs)
			local RemovePositiveBuffs1 = true
			local RemoveDebuffs1 = false
			local BuffsCreatedThisFrameOnly1 = false
			local RemoveStuns1 = false
			local RemoveExceptions1 = false
			enemy:Purge(RemovePositiveBuffs1, RemoveDebuffs1, BuffsCreatedThisFrameOnly1, RemoveStuns1, RemoveExceptions1)

			ability:ApplyDataDrivenModifier(caster, enemy, "item_modifier_negate_slow", nil)

			if enemy:IsDominated() or enemy:IsSummoned() or enemy:IsIllusion() then
				ApplyDamage({victim = enemy, attacker = caster, ability = ability, damage = summon_damage, damage_type = ability:GetAbilityDamageType()})
			else
				ApplyDamage({victim = enemy, attacker = caster, ability = ability, damage = blink_disable_damage, damage_type = ability:GetAbilityDamageType()})
			end
		end
	end
	
	-- Apply the basic dispel to allies around point
	local allies = FindUnitsInRadius(caster_team, point, nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, target_type, target_flags, 0, false)
	for k, ally in pairs(allies) do
		if ally then
			-- Basic Dispel (Removes normal debuffs)
			local RemovePositiveBuffs = false
			local RemoveDebuffs = true
			local BuffsCreatedThisFrameOnly = false
			local RemoveStuns = false
			local RemoveExceptions = false
			ally:Purge( RemovePositiveBuffs, RemoveDebuffs, BuffsCreatedThisFrameOnly, RemoveStuns, RemoveExceptions)
		end
	end
	
	-- Sound
	EmitSoundOnLocationWithCaster( point, "DOTA_Item.RodOfAtos.Target", caster ) -- DOTA_Item.RodOfAtos.Activate
end

function Staff_Mana_Break(keys)
	local caster = keys.caster
	local attacker = keys.attacker
	local target = keys.target
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	-- If better version of mana break is present, do nothing
	if caster:HasModifier("modifier_item_true_manta_mana_break") then
		return nil
	end

	-- To prevent crashes:
	if not target then
		return
	end

	if target:IsNull() then
		return
	end

	-- Check for existence of GetUnitName method to determine if target is a unit or an item
    -- items don't have that method -> nil; if the target is an item, don't continue
    if target.GetUnitName == nil then
		return
    end

	-- Don't affect buildings, wards and illusions
	if target:IsTower() or target:IsBarracks() or target:IsBuilding() or target:IsOther() or target:IsIllusion() then
		return
	end

	-- Parameters
	local mana_burn = ability:GetLevelSpecialValueFor("mana_burn", ability_level)
	if attacker:IsIllusion() then
		if attacker:IsRangedAttacker() then
			mana_burn = ability:GetLevelSpecialValueFor("mana_burn_illusion_ranged", ability_level)
		else
			mana_burn = ability:GetLevelSpecialValueFor("mana_burn_illusion_melee", ability_level)
		end
	end

	-- Burn mana if target is not magic immune
	if not target:IsMagicImmune() then

		-- Burn mana
		local target_mana = target:GetMana()
		target:ReduceMana(mana_burn)

		-- Deal bonus damage (Damage_per_burned_mana = 1)
		if target_mana > mana_burn then
			ApplyDamage({attacker = caster, victim = target, ability = ability, damage = mana_burn, damage_type = DAMAGE_TYPE_PHYSICAL})
		else
			ApplyDamage({attacker = caster, victim = target, ability = ability, damage = target_mana, damage_type = DAMAGE_TYPE_PHYSICAL})
		end
	end

	-- Sound and effect
	if not target:IsMagicImmune() and target:GetMana() > 1 then
		-- Plays the particle
		local manaburn_fx = ParticleManager:CreateParticle("particles/generic_gameplay/generic_manaburn.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
		ParticleManager:SetParticleControl(manaburn_fx, 0, target:GetAbsOrigin() )
		ParticleManager:ReleaseParticleIndex(manaburn_fx)
	end
end
