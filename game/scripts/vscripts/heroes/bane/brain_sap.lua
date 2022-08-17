if bane_custom_brain_sap == nil then
	bane_custom_brain_sap = class({})
end

LinkLuaModifier("modifier_custom_brain_sap_int_loss", "heroes/bane/modifier_custom_brain_sap_int_loss.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_custom_brain_sap_int_gain", "heroes/bane/modifier_custom_brain_sap_int_gain.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_custom_brain_sap_int_loss_counter", "heroes/bane/modifier_custom_brain_sap_int_loss_counter.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_custom_brain_sap_int_gain_counter", "heroes/bane/modifier_custom_brain_sap_int_gain_counter.lua", LUA_MODIFIER_MOTION_NONE)

function bane_custom_brain_sap:CastFilterResultTarget(target)
	local caster = self:GetCaster()
	local default_result = self.BaseClass.CastFilterResultTarget(self, target)

	if default_result == UF_FAIL_MAGIC_IMMUNE_ENEMY then
		if caster:HasScepter() then
			return UF_SUCCESS
		end

		return UF_FAIL_MAGIC_IMMUNE_ENEMY
	end

	return default_result
end

function bane_custom_brain_sap:GetCastPoint()
	local caster = self:GetCaster()
	local delay = self.BaseClass.GetCastPoint(self)

	if caster:HasScepter() then
		delay = self:GetSpecialValueFor("scepter_cast_point")
	end

	return delay
end

function bane_custom_brain_sap:GetCooldown(nLevel)
	local caster = self:GetCaster()
	local cooldown = self.BaseClass.GetCooldown(self, nLevel)

	if caster:HasScepter() then
		cooldown = self:GetSpecialValueFor("scepter_cooldown")
	end

	return cooldown
end

function bane_custom_brain_sap:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	if not caster or not target then
		return nil
	end

	-- Sound on caster
	caster:EmitSound("Hero_Bane.BrainSap")

	if not target:TriggerSpellAbsorb(self) then

		-- Sound on target
		target:EmitSound("Hero_Bane.BrainSap.Target")

		-- Particle
		local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_bane/bane_sap.vpcf", PATTACH_CUSTOMORIGIN, target)
		ParticleManager:SetParticleControlEnt(particle, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
		ParticleManager:SetParticleControlEnt(particle, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
		ParticleManager:ReleaseParticleIndex(particle)

		local damage_and_heal = self:GetSpecialValueFor("damage_and_heal")

		-- Talent that increases damage and heal of Brain Sap
		local talent = caster:FindAbilityByName("special_bonus_unique_bane_custom_2")
		if talent and talent:GetLevel() > 0 then
			damage_and_heal = damage_and_heal + talent:GetSpecialValueFor("value")
		end

		-- Apply intelligence loss/gain modifiers before the damage
		if target:IsRealHero() and not target:IsClone() then
			local int_steal_duration = self:GetSpecialValueFor("int_steal_duration")

			target:AddNewModifier(caster, self, "modifier_custom_brain_sap_int_loss_counter", {duration = int_steal_duration})
			target:AddNewModifier(caster, self, "modifier_custom_brain_sap_int_loss", {duration = int_steal_duration})
			caster:AddNewModifier(caster, self, "modifier_custom_brain_sap_int_gain_counter", {duration = int_steal_duration})
			caster:AddNewModifier(caster, self, "modifier_custom_brain_sap_int_gain", {duration = int_steal_duration})
		end

		local damage_table = {}
		damage_table.victim = target
		damage_table.attacker = caster
		damage_table.damage = damage_and_heal
		damage_table.damage_type = self:GetAbilityDamageType()
		damage_table.ability = self
		ApplyDamage(damage_table)

		-- Heal
		caster:Heal(damage_and_heal, self)
	end
end

function bane_custom_brain_sap:ProcsMagicStick()
	return true
end
