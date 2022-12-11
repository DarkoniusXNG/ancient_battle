-- Called OnAttackLanded
function DesolateCheck(event)
	local caster = event.caster
	local target = event.target
	local ability = event.ability

	-- To prevent crashes:
	if not target or target:IsNull() then
		return
	end

	-- Check for existence of GetUnitName method to determine if target is a unit or an item
    -- items don't have that method -> nil; if the target is an item, don't continue
    if target.GetUnitName == nil then
		return
    end

	-- Don't affect buildings and wards
	if target:IsTower() or target:IsBarracks() or target:IsBuilding() or target:IsOther() then
		return
	end

	local target_location = target:GetAbsOrigin()
	local ability_level = ability:GetLevel() - 1

	local radius = ability:GetLevelSpecialValueFor("radius", ability_level)
	local agi_dmg_multiplier = ability:GetLevelSpecialValueFor("damage_multiplier", ability_level)

	-- Calculate damage
	local caster_agility = caster:GetAgility()
	local desolate_damage = math.ceil(caster_agility*agi_dmg_multiplier)

	local damage_table = {}
	damage_table.attacker = caster
	damage_table.damage_type = ability:GetAbilityDamageType()
	damage_table.ability = ability
	damage_table.victim = target
	damage_table.damage = desolate_damage
	damage_table.damage_flags = DOTA_DAMAGE_FLAG_BYPASSES_BLOCK -- bit.bor(DOTA_DAMAGE_FLAG_BYPASSES_BLOCK, DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL)

	-- Targetting constants
	local target_team = DOTA_UNIT_TARGET_TEAM_FRIENDLY
	local target_type = bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
	local target_flags = DOTA_UNIT_TARGET_FLAG_NONE		-- bit.bor(DOTA_UNIT_TARGET_FLAG_INVULNERABLE, DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD) -- this will affect dummies

	-- Finding target's allies in a radius
	local enemies = FindUnitsInRadius(target:GetTeamNumber(), target_location, nil, radius, target_team, target_type, target_flags, FIND_ANY_ORDER, false)

	-- Number of target's allies around the target hero or unit (including the target itself)
	local number_of_nearby_enemies = #enemies
	if number_of_nearby_enemies < 2 then

		-- Applying the damage
		ApplyDamage(damage_table)

		-- Particle
		local particle_name = "particles/units/heroes/hero_riki/riki_backstab.vpcf"
		local particle = ParticleManager:CreateParticle(particle_name, PATTACH_ABSORIGIN_FOLLOW, target)
		Timers:CreateTimer(1.0, function()
			ParticleManager:DestroyParticle(particle, false)
			ParticleManager:ReleaseParticleIndex(particle)
		end)

		-- Sound
		caster:EmitSound("Hero_Riki.Backstab")
	end
end
