
function SpawnWolves(event)
    local caster = event.caster
	local ability = event.ability

	local ability_lvl = ability:GetLevel()
	local fv = caster:GetForwardVector()
	local position = caster:GetAbsOrigin() + fv * 200

	local duration = ability:GetLevelSpecialValueFor("wolf_duration", ability_lvl - 1)
	local count = 2 --ability:GetLevelSpecialValueFor("wolf_count", ability_lvl - 1)

	local wolfNames = {
		[1] = "npc_dota_lycan_wolf1",
		[2] = "npc_dota_lycan_wolf2",
		[3] = "npc_dota_lycan_wolf3",
		[4] = "npc_dota_lycan_wolf4",
	}

	-- Gets 2 points facing a distance away from the caster origin and separated from each other at 30 degrees left and right
    local positions = {}
    positions[1] = RotatePosition(caster:GetAbsOrigin(), QAngle(0, 30, 0), position)
    positions[2] = RotatePosition(caster:GetAbsOrigin(), QAngle(0, -30, 0), position)

	-- Summon 2 wolves
    for i = 1, count do
		local wolf = CreateUnitByName(wolfNames[ability_lvl], positions[i], true, caster, caster, caster:GetTeamNumber())
		FindClearSpaceForUnit(wolf, positions[i], false)
		wolf:SetOwner(caster:GetOwner())
		wolf:SetControllableByPlayer(caster:GetPlayerID(), true)
		wolf:AddNewModifier(caster, ability, "modifier_kill", {duration = duration})
		wolf:SetForwardVector(fv)

		local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_lycan/lycan_summon_wolves_spawn.vpcf", PATTACH_ABSORIGIN_FOLLOW, wolf)
		ParticleManager:ReleaseParticleIndex(particle)
	end
end
