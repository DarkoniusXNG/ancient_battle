function MassTeleportStart(event)
	local caster = event.caster
	local target = event.target
	local ability = event.ability
	local max_duration = ability:GetLevelSpecialValueFor("channel_time", ability:GetLevel() - 1)
	
	local particle_caster = ParticleManager:CreateParticle("particles/custom/mass_teleport_start.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	local casterPos = caster:GetAbsOrigin()
	ParticleManager:SetParticleControl(particle_caster, 0, casterPos)
	ParticleManager:SetParticleControl(particle_caster, 2, Vector(255,255,255)) -- color
	ParticleManager:SetParticleControl(particle_caster, 3, casterPos)
	ParticleManager:SetParticleControl(particle_caster, 4, casterPos)
	ParticleManager:SetParticleControl(particle_caster, 5, casterPos)
	ParticleManager:SetParticleControl(particle_caster, 6, casterPos)
	ability.particle_caster = particle_caster
	
	-- Remove the particle on caster after channel duration
	Timers:CreateTimer(max_duration, function ()
		if ability.particle_caster or particle_caster then
			ParticleManager:DestroyParticle(particle_caster, true)
		end
	end)
	
	local particle_target = ParticleManager:CreateParticle("particles/items2_fx/teleport_end.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
	ParticleManager:SetParticleControl(particle_target, 2, Vector(255, 255, 255))
	ability.particle_target = particle_target
	ability.particle_timer = Timers:CreateTimer(function ()
		local target_position_at_the_moment = target:GetAbsOrigin()
		ParticleManager:SetParticleControl(particle_target, 0, target_position_at_the_moment)
		ParticleManager:SetParticleControl(particle_target, 1, target_position_at_the_moment)
		ParticleManager:SetParticleControl(particle_target, 4, target_position_at_the_moment)
		return 0.02
	end)
	
	-- Sound on target
	target:EmitSound("Hero_KeeperOfTheLight.Recall.Cast")
end

-- Stops the channeling sound and removes particles on target and caster
function MassTeleportStop(event)
	local caster = event.caster
	local ability = event.ability
	local target = event.target
	
	-- Stop Sound on caster
	caster:StopSound("Hero_KeeperOfTheLight.Recall.Cast")
	
	-- Remove particle from target
	Timers:RemoveTimer(ability.particle_timer)
	ParticleManager:DestroyParticle(ability.particle_target, true)
	ParticleManager:ReleaseParticleIndex(ability.particle_target)
	
	-- Stop Sound on target
	target:StopSound("Hero_KeeperOfTheLight.Recall.Cast")
	
	-- Remove particle on caster
	if ability.particle_caster then
		ParticleManager:DestroyParticle(ability.particle_caster, true)
		ParticleManager:ReleaseParticleIndex(ability.particle_caster)
	end
end

-- Teleports units affected by the aura to the target destination
function MassTeleport(event)
	local caster = event.caster
	local target = event.target
	local ability = event.ability
	
	local caster_location = caster:GetAbsOrigin()
	local target_location = target:GetAbsOrigin()
	local radius = 100 + ability:GetLevelSpecialValueFor("radius", ability:GetLevel() - 1)
	
	local target_type = bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
	local units_to_teleport = FindUnitsInRadius(caster:GetTeamNumber(), caster_location, nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, target_type, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
	
	-- Teleport allied units if they are not channeling
    for _,unit in pairs(units_to_teleport) do
		if unit:HasModifier("modifier_mass_teleport_aura_effect") and not unit:IsChanneling() then
			FindClearSpaceForUnit(unit, target_location, true)
			unit:Stop()
			ProjectileManager:ProjectileDodge(unit)
		end
    end
	
    -- Teleports the caster
	FindClearSpaceForUnit(caster, target_location, true)
	ProjectileManager:ProjectileDodge(caster)
	
	MassTeleportStop(event)
end
