-- Called OnTakeDamage inside modifier_frost_armor_autocast_attacked
function FrostArmorAutocast(event)
	local caster = event.caster
	local target = event.unit -- victim of the attack
	local ability = event.ability

	local modifier = "modifier_custom_lich_frost_armor_buff"

	if ability:GetAutoCastState() then
		if not caster:IsChanneling() then
			if not target:HasModifier(modifier) then
				-- always caster:Interrupt() before CastAbility functions ?
				if ability:IsFullyCastable() and not ability:IsInAbilityPhase() then
					caster:CastAbilityOnTarget(target, ability, caster:GetPlayerOwnerID())
				end
			end
		end
	end
end

-- Called OnCreated modifier_custom_lich_frost_armor_buff
function FrostArmorParticle(event)
	local target = event.target
	local particleName = "particles/units/heroes/hero_lich/lich_frost_armor.vpcf"

	Timers:CreateTimer(0.01, function()
		local target_location = target:GetAbsOrigin()
		local particle_local = ParticleManager:CreateParticle(particleName, PATTACH_OVERHEAD_FOLLOW, target)
		ParticleManager:SetParticleControl(particle_local, 0, target_location)
		ParticleManager:SetParticleControl(particle_local, 1, Vector(1,0,0))
		ParticleManager:SetParticleControlEnt(particle_local, 2, target, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", target_location, true)
		target.FrostArmorParticle = particle_local
	end)
end

-- Called OnDestroy modifier_custom_lich_frost_armor_buff
function EndFrostArmorParticle(event)
	local target = event.target
	ParticleManager:DestroyParticle(target.FrostArmorParticle,false)
	ParticleManager:ReleaseParticleIndex(target.FrostArmorParticle)
end
