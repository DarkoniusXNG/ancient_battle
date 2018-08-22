-- Called OnSpellStart
function AbsorbLife(keys)
    local caster = keys.caster
	local point = keys.target_points[1]
	local ability = keys.ability
	
	local caster_team = caster:GetTeamNumber()
	local caster_location = caster:GetAbsOrigin()
	local ability_level = ability:GetLevel() - 1
	
	local radius = ability:GetLevelSpecialValueFor("radius", ability_level)
	local base_damage = ability:GetLevelSpecialValueFor("base_damage", ability_level)
	local current_hp_percent_damage = ability:GetLevelSpecialValueFor("hp_percent_damage", ability_level)
	
	-- Radius Particle
	local absorb_life_radius = ParticleManager:CreateParticle("particles/units/heroes/hero_undying/undying_decay.vpcf", PATTACH_POINT, caster)
	ParticleManager:SetParticleControl(absorb_life_radius, 0, point)
	ParticleManager:SetParticleControl(absorb_life_radius, 1, Vector(radius, radius, radius))
	ParticleManager:SetParticleControl(absorb_life_radius, 2, point)
	
	local total_heal = 0
	local enemies = FindUnitsInRadius(caster_team, point, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, 0, 0, false)
	for k, enemy in pairs(enemies) do
		local enemy_current_hp = enemy:GetHealth()
		local enemy_location = enemy:GetAbsOrigin()
		local damage_on_enemy = base_damage + current_hp_percent_damage*enemy_current_hp*0.01
		ApplyDamage({victim = enemy, attacker = caster, ability = ability, damage = damage_on_enemy, damage_type = ability:GetAbilityDamageType()})
		total_heal = total_heal + damage_on_enemy
		
		-- Link Particle
		local absorb_life_link = ParticleManager:CreateParticle("particles/econ/items/undying/undying_pale_augur/undying_pale_augur_decay_fakeprojectile_glow.vpcf", PATTACH_POINT_FOLLOW, enemy)
		ParticleManager:SetParticleControlEnt(absorb_life_link, 0, enemy, PATTACH_POINT_FOLLOW, "attach_hitloc", enemy_location, true)
		ParticleManager:SetParticleControlEnt(absorb_life_link, 1, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster_location, true)
		ParticleManager:SetParticleControlEnt(absorb_life_link, 3, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", (caster_location + enemy_location)/2, true)
		
	end
	-- Heal the caster
	caster:Heal(total_heal, caster)
	SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, caster, total_heal, nil)
	-- Sound
	EmitSoundOn("Hero_Undying.SoulRip.Cast", caster)
end