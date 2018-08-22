function TeleportStart(trigger)
	--print(trigger.activator)
	--print(trigger.caller)
	local activator = trigger.activator
	local teleport_trigger = trigger.caller
   
    local teleport_destination_ent = Entities:FindByName(nil, "teleport_destination1")
	local teleport_destination
	if teleport_destination_ent then
		teleport_destination = teleport_destination_ent:GetAbsOrigin()
	else 
		teleport_destination = Vector(0,0,0)
	end
    if activator == nil then
		return
    end
	
	local player = activator:GetPlayerID()
	local particle = ParticleManager:CreateParticle("particles/econ/events/ti6/teleport_start_ti6_lvl3.vpcf", PATTACH_ABSORIGIN_FOLLOW, activator)
	activator.teleporter_particle = particle
	
	Timers:CreateTimer(3.0, function()
		local radius = 200
		local heroes_nearby = FindUnitsInRadius(DOTA_TEAM_GOODGUYS, teleport_trigger:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
		for _,hero in pairs(heroes_nearby) do
			if hero == activator then
				FindClearSpaceForUnit(activator, teleport_destination, false)
				activator:Stop()
				PlayerResource:SetCameraTarget(player, activator)
				StartSoundEvent("Portal.Hero_Appear", activator)
				Timers:CreateTimer(0.2, function()
					PlayerResource:SetCameraTarget(player, nil)
				end)
				ParticleManager:DestroyParticle(particle, false)
			end
		end
	end)
end
 
function TeleportEnd(trigger)
	--print(trigger.activator)
	--print(trigger.caller)
	local activator = trigger.activator
	local particle = activator.teleporter_particle
	Timers:CreateTimer(0.1, function()
		ParticleManager:DestroyParticle(particle, true)
	end)
end

function TeleportStart2(trigger)
	--print(trigger.activator)
	--print(trigger.caller)
	local activator = trigger.activator
	local teleport_trigger = trigger.caller
   
    local teleport_destination_ent = Entities:FindByName(nil,"teleport_destination2")
	local teleport_destination
	if teleport_destination_ent then
		teleport_destination = teleport_destination_ent:GetAbsOrigin()
	else 
		teleport_destination = Vector(0,0,0)
	end
    if activator == nil then
		return
    end
	
	local player = activator:GetPlayerID()
	local particle = ParticleManager:CreateParticle("particles/econ/events/ti6/teleport_start_ti6_lvl3.vpcf", PATTACH_ABSORIGIN_FOLLOW, activator)
	activator.teleporter_particle = particle
	
	Timers:CreateTimer(3.0, function()
		local radius = 200
		local heroes_nearby = FindUnitsInRadius(DOTA_TEAM_GOODGUYS,teleport_trigger:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
		for _,hero in pairs(heroes_nearby) do
			if hero == activator then
				FindClearSpaceForUnit(activator, teleport_destination, false)
				activator:Stop()
				PlayerResource:SetCameraTarget(player, activator)
				StartSoundEvent("Portal.Hero_Appear", activator)
				Timers:CreateTimer(0.2, function()
					PlayerResource:SetCameraTarget(player, nil)
				end)
				
				ParticleManager:DestroyParticle(particle, false)
			end
		end
	end)
end
 
function TeleportEnd2(trigger)
	--print(trigger.activator)
	--print(trigger.caller)
	local activator = trigger.activator
	local particle = activator.teleporter_particle
	Timers:CreateTimer(0.1, function()
		ParticleManager:DestroyParticle(particle, true)
	end)
end