oracle_ironical_healing = class({})

LinkLuaModifier("modifier_oracle_ironical_healing", "heroes/oracle/oracle_ironical_healing.lua", LUA_MODIFIER_MOTION_NONE)

function oracle_ironical_healing:CastFilterResultTarget(target)
	local default_result = self.BaseClass.CastFilterResultTarget(self, target)

	if target:IsCustomWardTypeUnit() then
		return UF_FAIL_CUSTOM
	end

	return default_result
end

function oracle_ironical_healing:GetCustomCastErrorTarget(target)
	if target:IsCustomWardTypeUnit() then
		return "#dota_hud_error_cant_cast_on_other"
	end
	return ""
end

function oracle_ironical_healing:GetCooldown(level)
	local caster = self:GetCaster()
	local base_cooldown = self.BaseClass.GetCooldown(self, level)

	-- Talent that decreases cooldown
	local talent = caster:FindAbilityByName("special_bonus_unique_ironical_healing_cd")
	if talent and talent:GetLevel() > 0 then
		return base_cooldown - math.abs(talent:GetSpecialValueFor("value"))
	end

	return base_cooldown
end

function oracle_ironical_healing:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	local lethal = DOTA_DAMAGE_FLAG_NONE
	if target:GetTeamNumber() ~= caster:GetTeamNumber() then
		-- Check for spell block and spell immunity (latter because of lotus)
		if target:TriggerSpellAbsorb(self) or target:IsMagicImmune() then
			return
		end
	else
		lethal = DOTA_DAMAGE_FLAG_NON_LETHAL
	end

	local base_damage = self:GetSpecialValueFor("base_damage")
	local damage_pct = self:GetSpecialValueFor("damage_pct")
	local duration = self:GetSpecialValueFor("duration")

	-- Calculate damage
	local total_damage = base_damage + target:GetMaxHealth() * damage_pct / 100

	-- Particles
	local purifying_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_oracle/oracle_purifyingflames_hit.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
	ParticleManager:SetParticleControlEnt(purifying_particle, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:ReleaseParticleIndex(purifying_particle)

	local purifying_cast_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_oracle/oracle_purifyingflames_cast.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControlEnt(purifying_cast_particle, 1, caster, PATTACH_POINT_FOLLOW, "attach_attack1", caster:GetAbsOrigin(), true)
	ParticleManager:ReleaseParticleIndex(purifying_cast_particle)

	-- Sound
	target:EmitSound("Hero_Oracle.PurifyingFlames.Damage")

	-- Apply damage
	local damage_table = {
		victim = target,
		attacker = caster,
		damage = total_damage,
		damage_type = self:GetAbilityDamageType(),
		ability = self,
		damage_flags = lethal,
	}

	ApplyDamage(damage_table)

	-- Apply health regen buff
	if target and target:IsAlive() then
		target:AddNewModifier(caster, self, "modifier_oracle_ironical_healing", {duration = duration, damage = total_damage})
	end
end

---------------------------------------------------------------------------------------------------

modifier_oracle_ironical_healing = class({})

function modifier_oracle_ironical_healing:IsHidden()
	return false
end

function modifier_oracle_ironical_healing:IsDebuff()
	return false
end

function modifier_oracle_ironical_healing:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_oracle_ironical_healing:IsPurgable()
	return true
end

function modifier_oracle_ironical_healing:OnCreated( kv )
	if IsServer() then
		self.regen = kv.damage / kv.duration
		self:SetStackCount( self.regen )
	end
end

function modifier_oracle_ironical_healing:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
	}
end

function modifier_oracle_ironical_healing:GetModifierConstantHealthRegen()
	return self:GetStackCount()
end

function modifier_oracle_ironical_healing:GetEffectName()
	return "particles/units/heroes/hero_oracle/oracle_purifyingflames.vpcf"
end

function modifier_oracle_ironical_healing:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end
