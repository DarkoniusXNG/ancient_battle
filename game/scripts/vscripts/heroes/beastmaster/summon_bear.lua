
function SpawnBear(event)
	local caster = event.caster
	local ability = event.ability

	local ability_lvl = ability:GetLevel()
	local fv = caster:GetForwardVector()
	local position = caster:GetAbsOrigin() + fv * 200

	local duration = ability:GetLevelSpecialValueFor("duration", ability_lvl - 1)

	local bearNames = {
		[1] = "npc_dota_lone_druid_bear1",
		[2] = "npc_dota_lone_druid_bear2",
		[3] = "npc_dota_lone_druid_bear3",
		[4] = "npc_dota_lone_druid_bear4",
	}

	local bear = CreateUnitByName(bearNames[ability_lvl], position, true, caster, caster, caster:GetTeamNumber())
	FindClearSpaceForUnit(bear, position, false)
	bear:SetOwner(caster:GetOwner())
	bear:SetControllableByPlayer(caster:GetPlayerID(), true)
	bear:AddNewModifier(caster, ability, "modifier_kill", {duration = duration})

	ability:ApplyDataDrivenModifier(caster, bear, "modifier_beastmaster_bear", {})
	bear:SetForwardVector(fv)
end

---------------------------------------------------------------------------------------------------

function Blink(event)
	local point = event.target_points[1]
	local caster = event.caster
	local ability = event.ability

	local casterPos = caster:GetAbsOrigin()
	local difference = point - casterPos
	local range = ability:GetLevelSpecialValueFor("blink_range", (ability:GetLevel() - 1))

	if difference:Length2D() > range then
		point = casterPos + (point - casterPos):Normalized() * range
	end

	FindClearSpaceForUnit(caster, point, false)
	Timers:CreateTimer(0.15, function()
		ParticleManager:CreateParticle("particles/units/heroes/hero_lone_druid/lone_druid_bear_blink_end.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	end)
end