modifier_astral_charge_buff = modifier_astral_charge_buff or class({})

function modifier_astral_charge_buff:IsHidden()
	return false
end

function modifier_astral_charge_buff:IsDebuff()
	return false
end

function modifier_astral_charge_buff:IsPurgable()
	return false
end

function modifier_astral_charge_buff:RemoveOnDeath()
	return true
end

function modifier_astral_charge_buff:CheckState()
	return {
		[MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
	}
end

function modifier_astral_charge_buff:OnCreated()
	if IsServer() then
		local ability = self:GetAbility()
		local parent = self:GetParent()
		local position = parent:GetAbsOrigin()

		local particle_name = "particles/units/heroes/hero_stormspirit/stormspirit_ball_lightning.vpcf"
		self.particle_index = ParticleManager:CreateParticle(particle_name, PATTACH_CUSTOMORIGIN, parent)
		ParticleManager:SetParticleControlEnt(self.particle_index, 0, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", position, true)
		ParticleManager:SetParticleControlEnt(self.particle_index, 1, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", position, true)

		-- Destroy trees around the parent
		local tree_radius = ability:GetSpecialValueFor("tree_destroy_radius")
		GridNav:DestroyTreesAroundPoint(position, tree_radius, false)

		local think_interval = ability:GetSpecialValueFor("tree_destroy_interval")
		self:StartIntervalThink(think_interval)
	end
end

function modifier_astral_charge_buff:OnIntervalThink()
	if IsServer() then
		local ability = self:GetAbility()
		local parent = self:GetParent()

		-- Destroy trees around the parent
		local position = parent:GetAbsOrigin()
		if ability and not ability:IsNull() then
			local tree_radius = ability:GetSpecialValueFor("tree_destroy_radius")
			GridNav:DestroyTreesAroundPoint(position, tree_radius, false)
		end
	end
end

function modifier_astral_charge_buff:OnDestroy()
	local parent = self:GetParent()
	local loop_sound_name = "Hero_StormSpirit.BallLightning.Loop"

	parent.astral_charge_is_running = false

	if IsServer() then
		if parent and not parent:IsNull() then
			parent:StopSound(loop_sound_name)
			parent:SetDayTimeVisionRange(1800)
			parent:SetNightTimeVisionRange(800)
		end
		if self.particle_index then
			ParticleManager:DestroyParticle(self.particle_index, false)
			ParticleManager:ReleaseParticleIndex(self.particle_index)
		end
	end
end
