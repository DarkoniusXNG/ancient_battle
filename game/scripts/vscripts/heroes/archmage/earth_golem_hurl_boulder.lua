if earth_golem_hurl_boulder == nil then
	earth_golem_hurl_boulder = class({})
end

LinkLuaModifier("modifier_earth_golem_hurl_boulder_stun", "heroes/archmage/earth_golem_hurl_boulder.lua", LUA_MODIFIER_MOTION_NONE)

function earth_golem_hurl_boulder:Spawn()
	-- Constants
	self.projectile_particle = "particles/neutral_fx/mud_golem_hurl_boulder.vpcf"
	self.caster_sound = "n_mud_golem.Boulder.Cast"
	self.target_sound = "n_mud_golem.Boulder.Target"
end

function earth_golem_hurl_boulder:CastFilterResultTarget(target)
	local default_result = self.BaseClass.CastFilterResultTarget(self, target)

	if target:IsCustomWardTypeUnit() then
		return UF_FAIL_CUSTOM
	end

	return default_result
end

function earth_golem_hurl_boulder:GetCustomCastErrorTarget(target)
	if target:IsCustomWardTypeUnit() then
		return "#dota_hud_error_cant_cast_on_other"
	end
	return ""
end

function earth_golem_hurl_boulder:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	if not target or not caster then
		return
	end

	-- KVs
	local vision_radius = self:GetSpecialValueFor("vision")
	local speed = self:GetSpecialValueFor("speed")

	local info = {
		EffectName = self.projectile_particle,
		Ability = self,
		iMoveSpeed = speed,
		Source = caster,
		Target = target,
		bDodgeable = true,
		bProvidesVision = true,
		iVisionTeamNumber = caster:GetTeamNumber(),
		iVisionRadius = vision_radius,
		iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1,
	}

	ProjectileManager:CreateTrackingProjectile(info)

	-- Sound on caster
	caster:EmitSound(self.caster_sound)
end

function earth_golem_hurl_boulder:OnProjectileHit(target, location)
	-- If target doesn't exist (disjointed), don't continue
	if not target or target:IsNull() then
		return
	end

	-- Check for spell block and spell immunity (latter because of lotus and if the target didn't become spell immune in the same frame when the projectile hit)
	if not target:TriggerSpellAbsorb(self) and not target:IsMagicImmune() then
		local caster = self:GetCaster()

		-- Sound on target
		target:EmitSound(self.target_sound)

		-- KVs
		local damage = self:GetSpecialValueFor("damage")
		local stun_duration = self:GetSpecialValueFor("duration")

		-- Status resistance fix
		stun_duration = target:GetValueChangedByStatusResistance(stun_duration)

		-- Apply debuff
		target:AddNewModifier(caster, self, "modifier_earth_golem_hurl_boulder_stun", {duration = stun_duration})

		-- Apply damage
		local damage_table = {}
		damage_table.victim = target
		damage_table.attacker = caster
		damage_table.damage = damage
		damage_table.damage_type = self:GetAbilityDamageType()
		damage_table.ability = self

		ApplyDamage(damage_table)
	end

	return true
end

function earth_golem_hurl_boulder:ProcsMagicStick()
	return true
end

---------------------------------------------------------------------------------------------------

if primal_split_earth_spirit_hurl_boulder == nil then
	primal_split_earth_spirit_hurl_boulder = earth_golem_hurl_boulder
end

function primal_split_earth_spirit_hurl_boulder:Spawn()
	-- Constants
	self.projectile_particle = "particles/units/heroes/hero_brewmaster/brewmaster_hurl_boulder.vpcf"
	self.caster_sound = "Brewmaster_Earth.Boulder.Cast"
	self.target_sound = "Brewmaster_Earth.Boulder.Target"
end

---------------------------------------------------------------------------------------------------

if modifier_earth_golem_hurl_boulder_stun == nil then
	modifier_earth_golem_hurl_boulder_stun = class({})
end

function modifier_earth_golem_hurl_boulder_stun:IsHidden()
	return false
end

function modifier_earth_golem_hurl_boulder_stun:IsDebuff()
	return true
end

function modifier_earth_golem_hurl_boulder_stun:IsStunDebuff()
	return true
end

function modifier_earth_golem_hurl_boulder_stun:IsPurgable()
	return true
end

function modifier_earth_golem_hurl_boulder_stun:GetEffectName()
	return "particles/generic_gameplay/generic_stunned.vpcf"
end

function modifier_earth_golem_hurl_boulder_stun:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end

function modifier_earth_golem_hurl_boulder_stun:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
	}
end

function modifier_earth_golem_hurl_boulder_stun:GetOverrideAnimation()
	return ACT_DOTA_DISABLED
end

function modifier_earth_golem_hurl_boulder_stun:CheckState()
	return {
		[MODIFIER_STATE_STUNNED] = true,
	}
end
