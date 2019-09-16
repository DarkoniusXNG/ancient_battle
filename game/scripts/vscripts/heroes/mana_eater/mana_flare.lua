-- Called OnSpellStart
function ManaFlareStart(event)
	local caster = event.caster

	caster:StartGesture(ACT_DOTA_RUN)
end

-- Called OnChannelFinish or OnChannelInterrupted
function ManaFlareEnd(event)
	local caster = event.caster

	caster:RemoveGesture(ACT_DOTA_RUN)
	caster:InterruptChannel()
	caster:StopSound("Hero_Juggernaut.HealingWard.Loop")

	if caster:HasModifier("modifier_mana_flare_armor_buff") then
		caster:RemoveModifierByName("modifier_mana_flare_armor_buff")
	end

	if caster:HasModifier("modifier_mana_flare_aura_applier") then
		caster:RemoveModifierByName("modifier_mana_flare_aura_applier")
	end
end

-- Called OnSpentMana inside modifier_mana_flare_debuff
function ManaFlareDamage(event)
	local caster = event.caster
	local unit = event.unit
	local ability = event.ability
	local ability_cast = event.event_ability
	local mana_cost = ability_cast:GetManaCost(-1)
	local damage_per_used_mana = ability:GetLevelSpecialValueFor("damage_per_used_mana", ability:GetLevel() - 1)
	local damage_type = ability:GetAbilityDamageType()

	-- If the ability or item has no mana cost -> do nothing
	if mana_cost == 0 then
		return
	end

	if not unit or unit:IsNull() then
		return
	end
	-- Basic particles
	--local particle_name = "particles/units/heroes/hero_pugna/pugna_ward_attack.vpcf"
	--local particle = ParticleManager:CreateParticle(particle_name, PATTACH_ABSORIGIN_FOLLOW, caster)
	--ParticleManager:SetParticleControl(particle, 1, unit:GetAbsOrigin())
	--ParticleManager:ReleaseParticleIndex(particle)

	-- Additional particles
	local caster_loc = caster:GetAbsOrigin()
	if mana_cost < 200 then
		local light = "particles/econ/items/pugna/pugna_ward_ti5/pugna_ward_attack_light_ti_5.vpcf"
		local light_particle = ParticleManager:CreateParticle(light, PATTACH_ABSORIGIN, unit)
		ParticleManager:SetParticleControlEnt(light_particle, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster_loc, true)
		ParticleManager:SetParticleControlEnt(light_particle, 1, unit, PATTACH_POINT_FOLLOW, "attach_hitloc", unit:GetAbsOrigin(), true)
		--ParticleManager:SetParticleControl(light_particle, 1, unit:GetAbsOrigin())
		ParticleManager:ReleaseParticleIndex(light_particle)
	elseif mana_cost < 400 then
		local medium = "particles/econ/items/pugna/pugna_ward_ti5/pugna_ward_attack_medium_ti_5.vpcf"
		local medium_particle = ParticleManager:CreateParticle(medium, PATTACH_ABSORIGIN, unit)
		ParticleManager:SetParticleControlEnt(medium_particle, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster_loc, true)
		ParticleManager:SetParticleControlEnt(medium_particle, 1, unit, PATTACH_POINT_FOLLOW, "attach_hitloc", unit:GetAbsOrigin(), true)
		--ParticleManager:SetParticleControl(medium_particle, 1, unit:GetAbsOrigin())
		ParticleManager:ReleaseParticleIndex(medium_particle)
	else
		local heavy = "particles/econ/items/pugna/pugna_ward_ti5/pugna_ward_attack_heavy_ti_5.vpcf"
		local heavy_particle = ParticleManager:CreateParticle(heavy, PATTACH_ABSORIGIN, unit)
		ParticleManager:SetParticleControlEnt(heavy_particle, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster_loc, true)
		ParticleManager:SetParticleControlEnt(heavy_particle, 1, unit, PATTACH_POINT_FOLLOW, "attach_hitloc", unit:GetAbsOrigin(), true)
		--ParticleManager:SetParticleControl(heavy_particle, 1, unit:GetAbsOrigin())
		ParticleManager:ReleaseParticleIndex(heavy_particle)
	end

	-- Sounds
	unit:EmitSound("Hero_Pugna.NetherWard.Target")
	caster:EmitSound("Hero_Pugna.NetherWard.Attack")

	-- Calculating and applying damage
	local mana_flare_damage = mana_cost*damage_per_used_mana
	ApplyDamage({victim = unit, attacker = caster, ability = ability, damage = mana_flare_damage, damage_type = damage_type})
end
