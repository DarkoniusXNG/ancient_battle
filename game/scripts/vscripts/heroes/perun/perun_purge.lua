-- Called OnSpellStart
function PurgeStart(event)
	local target = event.target
	local caster = event.caster
	local ability = event.ability

	-- Checking if target has spell block, and if its an enemy
	if not target:TriggerSpellAbsorb(ability) and target:GetTeamNumber() ~= caster:GetTeamNumber()  then
		local ability_level = ability:GetLevel() - 1

		local hero_duration = ability:GetLevelSpecialValueFor("slow_hero_duration", ability_level)
		local creep_duration = ability:GetLevelSpecialValueFor("slow_creep_duration", ability_level)
		local base_damage = ability:GetLevelSpecialValueFor("base_damage", ability_level)
		local summon_damage = ability:GetLevelSpecialValueFor("summon_damage", ability_level)

		local damage_table = {}
		damage_table.attacker = caster
		damage_table.victim = target
		damage_table.damage_type = ability:GetAbilityDamageType()
		damage_table.ability = ability

		if target:IsRealHero() then
			ability:ApplyDataDrivenModifier(caster, target, "modifier_purge_enemy_hero", {["duration"] = hero_duration})
			damage_table.damage = base_damage
			ApplyDamage(damage_table)
		else
			ability:ApplyDataDrivenModifier(caster, target, "modifier_purge_enemy_creep", {["duration"] = creep_duration})

			if target:IsSummoned() or target:IsDominated() or (target:IsIllusion() and not target:IsStrongIllusionCustom()) then
				damage_table.damage = base_damage + summon_damage
				ApplyDamage(damage_table)
			else
				damage_table.damage = base_damage
				ApplyDamage(damage_table)
			end
		end
	end
end

-- Called OnCreated modifier_purge_ally
function StrongDispelAlly(event)
	local target = event.target

	SuperStrongDispel(target, true, false)
end

-- Called OnCreated modifier_purge_enemy_hero or modifier_purge_enemy_creep
function StrongDispelEnemy(event)
	local target = event.target

	-- Basic Dispel (Buffs)
	local RemovePositiveBuffs = true
	local RemoveDebuffs = false
	local BuffsCreatedThisFrameOnly = false
	local RemoveStuns = false
	local RemoveExceptions = false
	target:Purge(RemovePositiveBuffs, RemoveDebuffs, BuffsCreatedThisFrameOnly, RemoveStuns, RemoveExceptions)
end
