function SpawnSerpentWard(event)
    local caster = event.caster
	local ability = event.ability

	local ability_lvl = ability:GetLevel()
	local fv = caster:GetForwardVector()
	local position = caster:GetAbsOrigin() + fv * 200

	local duration = ability:GetLevelSpecialValueFor("duration", ability_lvl - 1)

	local wardNames = {
		[1] = "npc_dota_shadow_shaman_ward_1",
		[2] = "npc_dota_shadow_shaman_ward_2",
		[3] = "npc_dota_shadow_shaman_ward_3",
		[4] = "npc_dota_shadow_shaman_ward_4",
	}

	local ward = CreateUnitByName(wardNames[ability_lvl], position, true, caster, caster, caster:GetTeamNumber())
	FindClearSpaceForUnit(ward, position, false)
	ward:SetOwner(caster:GetOwner())
	ward:SetControllableByPlayer(caster:GetPlayerID(), true)
	ward:AddNewModifier(caster, ability, "modifier_kill", {duration = duration})
	ward:SetForwardVector(fv)
end
