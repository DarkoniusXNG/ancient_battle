guardian_angel_immunity = guardian_angel_immunity or class({})

LinkLuaModifier("modifier_custom_guardian_angel_summon", "heroes/paladin/guardian_angel_immunity.lua", LUA_MODIFIER_MOTION_NONE)

function guardian_angel_immunity:IsStealable()
	return false
end

function guardian_angel_immunity:GetIntrinsicModifierName()
	return "modifier_custom_guardian_angel_summon"
end

---------------------------------------------------------------------------------------------------

modifier_custom_guardian_angel_summon = class({})

function modifier_custom_guardian_angel_summon:IsHidden()
	return true
end

function modifier_custom_guardian_angel_summon:IsDebuff()
	return false
end

function modifier_custom_guardian_angel_summon:IsPurgable()
	return false
end

function modifier_custom_guardian_angel_summon:OnCreated()
	local parent = self:GetParent()
	local part_name_1 = "particles/frostivus_herofx/holdout_guardian_angel_wings.vpcf"
	local part_name_2 = "particles/units/heroes/hero_omniknight/omniknight_guardian_angel_halo_buff.vpcf"
	local sound_name = "Hero_Omniknight.GuardianAngel"

	if IsServer() then
		-- Sound
		parent:EmitSound(sound_name)

		-- Particle
		self.particle1 = ParticleManager:CreateParticle(part_name_1, PATTACH_ROOTBONE_FOLLOW, parent)
		--ParticleManager:SetParticleControlEnt(self.particle1, 0, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", Vector(0, 0, 200), false)
		self.particle2 = ParticleManager:CreateParticle(part_name_2, PATTACH_OVERHEAD_FOLLOW, parent)
	end
end

function modifier_custom_guardian_angel_summon:OnDestroy()
	if IsServer() then
		if self.particle1 then
			ParticleManager:DestroyParticle(self.particle1, false)
			ParticleManager:ReleaseParticleIndex(self.particle1)
		end
		if self.particle2 then
			ParticleManager:DestroyParticle(self.particle2, false)
			ParticleManager:ReleaseParticleIndex(self.particle2)
		end
	end
end

function modifier_custom_guardian_angel_summon:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
	}
end

function modifier_custom_guardian_angel_summon:GetAbsoluteNoDamagePhysical()
	return 1
end

function modifier_custom_guardian_angel_summon:GetModifierMagicalResistanceBonus()
  return self:GetAbility():GetSpecialValueFor("magic_resist")
end

function modifier_custom_guardian_angel_summon:GetEffectName()
	return "particles/units/heroes/hero_omniknight/omniknight_guardian_angel_ally.vpcf"
end

function modifier_custom_guardian_angel_summon:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_custom_guardian_angel_summon:GetStatusEffectName()
	return "particles/status_fx/status_effect_ghost.vpcf"
end

function modifier_custom_guardian_angel_summon:StatusEffectPriority()
	return MODIFIER_PRIORITY_SUPER_ULTRA
end
