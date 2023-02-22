function DoomStart(event)

end

function DoomEnd( event )
	local caster = event.caster
	local target = event.unit

	local position = target:GetAbsOrigin()

	local summon_name = "npc_dota_neutral_mud_golem_split_doom"

	local doom_guard = CreateUnitByName(summon_name, position, true, caster, caster, caster:GetTeamNumber())
	FindClearSpaceForUnit(doom_guard, position, false)
	doom_guard:SetOwner(caster:GetOwner())
	doom_guard:SetControllableByPlayer(caster:GetPlayerID(), true)

	local p1 = ParticleManager:CreateParticle("particles/units/heroes/hero_doom_bringer/doom_bringer_lvl_death.vpcf", PATTACH_ABSORIGIN_FOLLOW, doom_guard)
	local p2 = ParticleManager:CreateParticle("particles/econ/items/doom/doom_f2p_death_effect/doom_bringer_f2p_death.vpcf", PATTACH_ABSORIGIN_FOLLOW, doom_guard)
	ParticleManager:ReleaseParticleIndex(p1)
	ParticleManager:ReleaseParticleIndex(p2)

	doom_guard:EmitSound("Hero_DoomBringer.LvlDeath")
	target:StopSound("Hero_DoomBringer.Doom")
end
