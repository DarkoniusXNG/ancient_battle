alchemist_custom_acid_bomb = class({})

LinkLuaModifier("modifier_custom_acid_bomb_stun", "heroes/alchemist/acid_bomb.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_custom_acid_bomb_debuff", "heroes/alchemist/acid_bomb.lua", LUA_MODIFIER_MOTION_NONE)

function alchemist_custom_acid_bomb:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function alchemist_custom_acid_bomb:CastFilterResultTarget(target)
	local default_result = self.BaseClass.CastFilterResultTarget(self, target)

	if target:IsCustomWardTypeUnit() then
		return UF_FAIL_CUSTOM
	end

	return default_result
end

function alchemist_custom_acid_bomb:GetCustomCastErrorTarget(target)
	if target:IsCustomWardTypeUnit() then
		return "#dota_hud_error_cant_cast_on_other"
	end
	return ""
end

function alchemist_custom_acid_bomb:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	if not target or not caster then
		return
	end

	-- KVs
	local vision_radius = self:GetSpecialValueFor("bomb_vision")
	local speed = self:GetSpecialValueFor("bomb_speed")

	local info = {
		EffectName = "particles/units/heroes/hero_alchemist/alchemist_unstable_concoction_projectile.vpcf",
		Ability = self,
		iMoveSpeed = speed,
		Source = caster,
		Target = target,
		bDodgeable = true,
		bProvidesVision = true,
		iVisionTeamNumber = caster:GetTeamNumber(),
		iVisionRadius = vision_radius,
		iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1, --DOTA_PROJECTILE_ATTACHMENT_ATTACK_3
	}

	ProjectileManager:CreateTrackingProjectile(info)

	-- Sound on caster
	caster:EmitSound("Hero_Alchemist.UnstableConcoction.Throw")
end

function alchemist_custom_acid_bomb:OnProjectileHit(target, location)
	-- If target doesn't exist (disjointed), don't continue
	if not target or target:IsNull() then
		return
	end

	-- Checking if target has spell block, if target has spell block, there is no need to execute the spell
	if not target:TriggerSpellAbsorb(self) and not target:IsMagicImmune() then
		local caster = self:GetCaster()
		local caster_team = caster:GetTeamNumber()
		local target_pos = target:GetAbsOrigin()

		-- Sound on target
		target:EmitSound("Hero_Alchemist.UnstableConcoction.Stun")

		-- Particle on target
		local particle_name = "particles/units/heroes/hero_alchemist/alchemist_unstable_concoction_explosion.vpcf"
		--local particle_name = "particles/units/heroes/hero_witchdoctor/witchdoctor_cask_explosion_flash.vpcf"
		local particle1 = ParticleManager:CreateParticle(particle_name, PATTACH_ABSORIGIN_FOLLOW, target)
		ParticleManager:SetParticleControlEnt(particle1, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target_pos, true)
		ParticleManager:ReleaseParticleIndex(particle1)

		-- KVs
		local stun_duration = self:GetSpecialValueFor("stun_duration")
		local debuff_duration = self:GetSpecialValueFor("debuff_duration")
		local radius = self:GetSpecialValueFor("radius")
		local target_team = self:GetAbilityTargetTeam() or DOTA_UNIT_TARGET_TEAM_ENEMY
		local target_type = self:GetAbilityTargetType() or bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
		local target_flags = self:GetAbilityTargetFlags() or DOTA_UNIT_TARGET_FLAG_NONE

		-- Status resistance fix
		stun_duration = target:GetValueChangedByStatusResistance(stun_duration)

		-- Apply a stun to the main target
		target:AddNewModifier(caster, self, "modifier_custom_acid_bomb_stun", {duration = stun_duration})

		-- AoE particle
		local particle2 = ParticleManager:CreateParticle("particles/units/heroes/hero_witchdoctor/witchdoctor_maledict_aoe.vpcf", PATTACH_ABSORIGIN, caster)
		ParticleManager:SetParticleControl(particle2, 0, target_pos)
		ParticleManager:SetParticleControl(particle2, 1, Vector(radius, radius, radius))
		ParticleManager:ReleaseParticleIndex(particle2)

		-- Apply debuff to enemies in a radius around the target
		local enemies = FindUnitsInRadius(caster_team, target_pos, nil, radius, target_team, target_type, target_flags, FIND_ANY_ORDER, false)
		for _, enemy in pairs(enemies) do
			if enemy and not enemy:IsNull() and not enemy:IsCustomWardTypeUnit() then
				enemy:AddNewModifier(caster, self, "modifier_custom_acid_bomb_debuff", {duration = debuff_duration})
			end
		end
	end

	return true
end

function alchemist_custom_acid_bomb:ProcsMagicStick()
	return true
end

---------------------------------------------------------------------------------------------------

if modifier_custom_acid_bomb_stun == nil then
	modifier_custom_acid_bomb_stun = class({})
end

function modifier_custom_acid_bomb_stun:IsHidden() -- needs tooltip
	return false
end

function modifier_custom_acid_bomb_stun:IsDebuff()
	return true
end

function modifier_custom_acid_bomb_stun:IsStunDebuff()
	return true
end

function modifier_custom_acid_bomb_stun:IsPurgable()
	return true
end

function modifier_custom_acid_bomb_stun:GetEffectName()
	return "particles/generic_gameplay/generic_stunned.vpcf"
end

function modifier_custom_acid_bomb_stun:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end

function modifier_custom_acid_bomb_stun:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
	}
end

function modifier_custom_acid_bomb_stun:GetOverrideAnimation()
	return ACT_DOTA_DISABLED
end

function modifier_custom_acid_bomb_stun:CheckState()
	return {
		[MODIFIER_STATE_STUNNED] = true,
	}
end

---------------------------------------------------------------------------------------------------

if modifier_custom_acid_bomb_debuff == nil then
	modifier_custom_acid_bomb_debuff = class({})
end

function modifier_custom_acid_bomb_debuff:IsHidden() -- needs tooltip
	return false
end

function modifier_custom_acid_bomb_debuff:IsDebuff()
	return true
end

function modifier_custom_acid_bomb_debuff:IsStunDebuff()
	return true
end

function modifier_custom_acid_bomb_debuff:IsPurgable()
	return true
end

function modifier_custom_acid_bomb_debuff:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_custom_acid_bomb_debuff:OnCreated()
	local ability = self:GetAbility()

	self.armor_reduction = -4
	self.dps = 20
	self.interval = 1

	if ability and not ability:IsNull() then
		self.armor_reduction = ability:GetSpecialValueFor("armor_reduction")
		self.dps = ability:GetSpecialValueFor("damage_per_second")
		self.interval = ability:GetSpecialValueFor("damage_interval")
	end

	if not IsServer() then
		return
	end
	
	-- Start thinking
	self:OnIntervalThink()
	self:StartIntervalThink(self.interval)
end

function modifier_custom_acid_bomb_debuff:OnIntervalThink()
	if not IsServer() then
		return
	end

	local caster = self:GetCaster()
	local parent = self:GetParent()

	if not parent or parent:IsNull() or not parent:IsAlive() or not caster or caster:IsNull() then
		self:StartIntervalThink(-1)
		self:Destroy()
		return
	end

	-- Calculate damage
	local damage_per_interval = self.dps * self.interval

	local particle = ParticleManager:CreateParticle("particles/msg_fx/msg_poison.vpcf", PATTACH_OVERHEAD_FOLLOW, parent)
	local presymbol = 9
	local postsymbol = 6
	local lifetime = 1
	local digits = string.len(tostring(math.floor(damage_per_interval))) + 2
	local color = Vector(215, 50, 248) --Vector(170, 0, 250)
	ParticleManager:SetParticleControl(particle, 1, Vector(presymbol, damage_per_interval, postsymbol))
	ParticleManager:SetParticleControl(particle, 2, Vector(lifetime, digits, 0))
	ParticleManager:SetParticleControl(particle, 3, color)
	ParticleManager:ReleaseParticleIndex(particle)

	--SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_POISON_DAMAGE, parent, damage_per_interval, nil)

	local damage_table = {}
	damage_table.victim = parent
	damage_table.attacker = caster
	damage_table.ability = self:GetAbility()
	damage_table.damage = damage_per_interval
	damage_table.damage_type = DAMAGE_TYPE_PHYSICAL
	damage_table.damage_flags = DOTA_DAMAGE_FLAG_BYPASSES_BLOCK

	ApplyDamage(damage_table)
end

function modifier_custom_acid_bomb_debuff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
	}
end

function modifier_custom_acid_bomb_debuff:GetModifierPhysicalArmorBonus()
	return 0 - math.abs(self.armor_reduction)
end

function modifier_custom_acid_bomb_debuff:GetStatusEffectName()
	return "particles/status_fx/status_effect_maledict.vpcf"
end

function modifier_custom_acid_bomb_debuff:StatusEffectPriority()
	return 10
end
