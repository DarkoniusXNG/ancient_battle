-- Called OnSpellStart
function DispelMagic(keys)
	local caster = keys.caster
	local point = keys.target_points[1]
	local ability = keys.ability
	
	local caster_team = caster:GetTeamNumber()
	local ability_level = ability:GetLevel() - 1
	
	local radius = ability:GetLevelSpecialValueFor("radius", ability_level)
	local damage_to_summons = ability:GetLevelSpecialValueFor("damage_to_summons", ability_level)
	
	-- Targetting constants
	local target_type = bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
	local target_flags = DOTA_UNIT_TARGET_FLAG_INVULNERABLE
	
	-- Apply the basic dispel to enemies around point and damage them if they are summoned, dominated or an illusion
	local enemies = FindUnitsInRadius(caster_team, point, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, target_type, target_flags, FIND_ANY_ORDER, false)
	for _, enemy in pairs(enemies) do
		enemy:RemoveModifierByName("modifier_brewmaster_storm_cyclone")
		-- Basic Dispel (Removes Buffs)
		local RemovePositiveBuffs1 = true
		local RemoveDebuffs1 = false
		local BuffsCreatedThisFrameOnly1 = false
		local RemoveStuns1 = false
		local RemoveExceptions1 = false
		enemy:Purge(RemovePositiveBuffs1, RemoveDebuffs1, BuffsCreatedThisFrameOnly1, RemoveStuns1, RemoveExceptions1)
		
		if enemy:IsDominated() or enemy:IsSummoned() or enemy:IsIllusion() then
			ApplyDamage({victim = enemy, attacker = caster, ability = ability, damage = damage_to_summons, damage_type = ability:GetAbilityDamageType()})
		end
	end
	
	-- Apply the basic dispel to allies around point
	local allies = FindUnitsInRadius(caster_team, point, nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, target_type, target_flags, FIND_ANY_ORDER, false)
	for _, ally in pairs(allies) do
		ally:RemoveModifierByName("modifier_brewmaster_storm_cyclone")
		-- Basic Dispel (Removes normal debuffs)
		local RemovePositiveBuffs = false
		local RemoveDebuffs = true
		local BuffsCreatedThisFrameOnly = false
		local RemoveStuns = false
		local RemoveExceptions = false
		ally:Purge(RemovePositiveBuffs, RemoveDebuffs, BuffsCreatedThisFrameOnly, RemoveStuns, RemoveExceptions)
	end
end
