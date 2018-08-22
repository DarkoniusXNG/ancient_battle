-- Particles and sounds
function BlizzardStart(event)
	local target = event.target
	local caster = event.caster
	
	-- Main Sound
	EmitSoundOn("Hero_Ancient_Apparition.IceVortex", target)
	
	-- Variables
	local target_position = target:GetAbsOrigin()
    local particleName = "particles/units/heroes/hero_crystalmaiden/maiden_freezing_field_explosion.vpcf"
    
    -- Explosion and Ice Shard particles
    local particle1 = ParticleManager:CreateParticle(particleName, PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(particle1, 0, target_position)

	Timers:CreateTimer(0.05,function()
		local particle2 = ParticleManager:CreateParticle(particleName, PATTACH_CUSTOMORIGIN, caster)
		ParticleManager:SetParticleControl(particle2, 0, target_position+RandomVector(100))
	end)

    Timers:CreateTimer(0.1,function()
		local particle3 = ParticleManager:CreateParticle(particleName, PATTACH_CUSTOMORIGIN, caster)
		ParticleManager:SetParticleControl(particle3, 0, target_position-RandomVector(100))
	end)

    Timers:CreateTimer(0.15,function()
		local particle4 = ParticleManager:CreateParticle(particleName, PATTACH_CUSTOMORIGIN, caster)
		ParticleManager:SetParticleControl(particle4, 0, target_position+RandomVector(RandomInt(50,100)))
	end)

    Timers:CreateTimer(0.2,function()
		local particle5 = ParticleManager:CreateParticle(particleName, PATTACH_CUSTOMORIGIN, caster)
		ParticleManager:SetParticleControl(particle5, 0, target_position-RandomVector(RandomInt(50,100)))
	end)
end

function BlizzardStopSound(event)
	local target = event.target
	
	StopSoundOn("Hero_Ancient_Apparition.IceVortex", target)
end

function BlizzardWave(event)
	local target = event.target
	local caster = event.caster
	
	local target_position = target:GetAbsOrigin()
    local particleName = "particles/units/heroes/hero_crystalmaiden/maiden_freezing_field_explosion.vpcf"
    
    -- Explosion and Ice Shard particles
    local particle1 = ParticleManager:CreateParticle(particleName, PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(particle1, 0, target_position)

	Timers:CreateTimer(0.05,function()
		local particle2 = ParticleManager:CreateParticle(particleName, PATTACH_CUSTOMORIGIN, caster)
		ParticleManager:SetParticleControl(particle2, 0, target_position+RandomVector(100))
	end)

    Timers:CreateTimer(0.1,function()
		local particle3 = ParticleManager:CreateParticle(particleName, PATTACH_CUSTOMORIGIN, caster)
		ParticleManager:SetParticleControl(particle3, 0, target_position-RandomVector(100))
	end)

    Timers:CreateTimer(0.15,function()
		local particle4 = ParticleManager:CreateParticle(particleName, PATTACH_CUSTOMORIGIN, caster)
		ParticleManager:SetParticleControl(particle4, 0, target_position+RandomVector(RandomInt(50,100)))
	end)

    Timers:CreateTimer(0.2,function()
		local particle5 = ParticleManager:CreateParticle(particleName, PATTACH_CUSTOMORIGIN, caster)
		ParticleManager:SetParticleControl(particle5, 0, target_position-RandomVector(RandomInt(50,100)))
	end)
end

-- Damage function
function BlizzardDamageBuildings(keys)
	local target = keys.target
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	
	local radius = ability:GetLevelSpecialValueFor("radius", ability_level)
	local damage_per_second = ability:GetLevelSpecialValueFor("damage", ability_level)
	
	local target_position = target:GetAbsOrigin()
	local damage_to_buildings = damage_per_second*0.25
	local caster_team = caster:GetTeamNumber()
	
	-- Damage enemy buildings in a radius
    local buildings = FindUnitsInRadius(caster_team, target_position, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_BUILDING, 0, 0, false)
	for k, enemy_building in pairs(buildings) do
		ApplyDamage({victim = enemy_building, attacker = caster, ability = ability, damage = damage_to_buildings, damage_type = DAMAGE_TYPE_MAGICAL})
	end
end