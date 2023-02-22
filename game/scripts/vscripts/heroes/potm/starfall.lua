function StarfallDamage(event)
    local ability = event.ability
    local caster = event.caster
    local wave_damage = ability:GetSpecialValueFor("wave_damage")
    --local building_damage = wave_damage * ability:GetSpecialValueFor("building_dmg_pct") * 0.01
    local radius = ability:GetSpecialValueFor("radius")
	local target_team = ability:GetAbilityTargetTeam() or DOTA_UNIT_TARGET_TEAM_ENEMY
	local target_type = ability:GetAbilityTargetType() or bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
	local target_flags = ability:GetAbilityTargetFlags() or DOTA_UNIT_TARGET_FLAG_NONE

	local delay = 0.57

	local enemies = FindUnitsInRadius(
		caster:GetTeamNumber(),
		caster:GetAbsOrigin(),
		nil,
		radius,
		target_team,
		target_type,
		target_flags,
		FIND_ANY_ORDER,
		false
	)

	-- Damage table constants
	local damage_table = {}
	damage_table.attacker = caster
	damage_table.damage = wave_damage
	damage_table.ability = ability
	damage_table.damage_type = ability:GetAbilityDamageType()

	for _, enemy in pairs(enemies) do
		if enemy then
			-- Particle on hit unit
			local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_mirana/mirana_starfall_attack.vpcf", PATTACH_ABSORIGIN_FOLLOW, enemy)
			ParticleManager:SetParticleControl(particle, 0, enemy:GetAbsOrigin())
			ParticleManager:SetParticleControl(particle, 1, enemy:GetAbsOrigin())
			ParticleManager:SetParticleControl(particle, 3, enemy:GetAbsOrigin())
			ParticleManager:ReleaseParticleIndex(particle)

			Timers:CreateTimer(delay, function()
				if enemy and not enemy:IsNull() and enemy:IsAlive() and not enemy:IsMagicImmune() and not enemy:IsInvulnerable() then
					-- Sound on hit unit
					enemy:EmitSound("Hero_Mirana.Starstorm.Impact") -- Ability.StarfallImpact

					-- Do damage
					damage_table.victim = enemy
					ApplyDamage(damage_table)
				end
			end)
		end
	end
end