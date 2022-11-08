-- Selects targets in a radius randomly and creates tracking projectile for them
-- Called OnDestroy modifier_roulette_caster_buff
function RouletteStart(keys)
	local caster = keys.caster
	local ability = keys.ability

	local caster_location = caster:GetAbsOrigin()
	local caster_team = caster:GetTeamNumber()
	local ability_level = ability:GetLevel() - 1

	local radius = ability:GetLevelSpecialValueFor("radius", ability_level)
	local chance_to_hit = ability:GetLevelSpecialValueFor("chance_to_hit", ability_level)

	local target_type = bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)

	local units = FindUnitsInRadius(caster_team, caster_location, nil, radius, DOTA_UNIT_TARGET_TEAM_BOTH, target_type, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
	for _, unit in pairs(units) do
		local random_number_for_unit = RandomFloat(0, 100.0)
		if random_number_for_unit < chance_to_hit then
			local projectile_info = {
				Target = unit,
				Source = caster,
				Ability = ability,
				EffectName = "particles/units/heroes/hero_sniper/sniper_assassinate.vpcf",
				bDodgeable = true,
				bProvidesVision = true,
				iMoveSpeed = 550,
			--	iVisionRadius = vision_radius,
			--	iVisionTeamNumber = caster:GetTeamNumber(),
				iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_HITLOCATION
			}

			ProjectileManager:CreateTrackingProjectile(projectile_info)
		end
	end
end

-- Called OnProjectileHitUnit
function RouletteProjectileHit(keys)
	local caster = keys.caster
	local ability = keys.ability
	local unit = keys.target

	local ability_level = ability:GetLevel() - 1

	local base_damage = ability:GetLevelSpecialValueFor("base_damage", ability_level)
	local level_multiplier = ability:GetLevelSpecialValueFor("level_multiplier", ability_level)

	local damage_table = {}
	damage_table.attacker = caster
	damage_table.damage_type = ability:GetAbilityDamageType()
	damage_table.ability = ability
	damage_table.victim = unit

	if unit:IsRealHero() then
		damage_table.damage = math.ceil(base_damage + level_multiplier*(unit:GetLevel()))

		local symbol = 2 -- Unhappy Smiley
		local color = Vector(255, 1, 1) -- Red
		local lifetime = 2
		local digits = string.len(damage_table.damage) + 1
		local particleName = "particles/units/heroes/hero_alchemist/alchemist_lasthit_msg_gold.vpcf"
		local particle = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN, unit)
		ParticleManager:SetParticleControl(particle, 1, Vector(symbol, damage_table.damage, 0))
		ParticleManager:SetParticleControl(particle, 2, Vector(lifetime, digits, 0))
		ParticleManager:SetParticleControl(particle, 3, color)
		ParticleManager:ReleaseParticleIndex(particle)
	else
		damage_table.damage = base_damage
	end

	ApplyDamage(damage_table)
end
