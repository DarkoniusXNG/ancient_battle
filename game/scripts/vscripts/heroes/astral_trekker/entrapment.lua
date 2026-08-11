astral_trekker_entrapment = class({})

LinkLuaModifier("modifier_astral_trekker_entrapment_debuff", "heroes/astral_trekker/entrapment.lua", LUA_MODIFIER_MOTION_NONE)

function astral_trekker_entrapment:CastFilterResultTarget(target)
	local default_result = self.BaseClass.CastFilterResultTarget(self, target)

	if target:IsCustomWardTypeUnit() then
		return UF_FAIL_CUSTOM
	end

	return default_result
end

function astral_trekker_entrapment:GetCustomCastErrorTarget(target)
	if target:IsCustomWardTypeUnit() then
		return "#dota_hud_error_cant_cast_on_other"
	end
	return ""
end

function astral_trekker_entrapment:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	if not target or not caster then
		return
	end

	-- KVs
	local vision_radius = self:GetSpecialValueFor("net_vision")
	local speed = self:GetSpecialValueFor("net_speed")
	if caster:HasShardCustom() then
		speed = self:GetSpecialValueFor("shard_net_speed")
	end

	local info = {
		EffectName = "particles/units/heroes/hero_siren/siren_net_projectile.vpcf",
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
	caster:EmitSound("Hero_NagaSiren.Ensnare.Cast")
end

function astral_trekker_entrapment:OnProjectileHit(target, location)
	-- If target doesn't exist (disjointed), don't continue
	if not target or target:IsNull() then
		return
	end

	-- Check for spell block; pierces spell immunity
	if not target:TriggerSpellAbsorb(self) then
		local caster = self:GetCaster()

		-- Sound on target
		target:EmitSound("Hero_NagaSiren.Ensnare.Target")

		-- KVs
		local duration = self:GetSpecialValueFor("duration")

		-- Status resistance fix
		duration = target:GetValueChangedByStatusResistance(duration)

		-- Apply debuff
		target:AddNewModifier(caster, self, "modifier_astral_trekker_entrapment_debuff", {duration = duration})

		-- Mini-stun
		target:Interrupt()
	end

	return true
end

function astral_trekker_entrapment:ProcsMagicStick()
	return true
end

---------------------------------------------------------------------------------------------------

modifier_astral_trekker_entrapment_debuff = modifier_astral_trekker_entrapment_debuff or class({})

function modifier_astral_trekker_entrapment_debuff:IsHidden()
	return false
end

function modifier_astral_trekker_entrapment_debuff:IsDebuff()
	return true
end

function modifier_astral_trekker_entrapment_debuff:IsPurgable()
	return false
end

function modifier_astral_trekker_entrapment_debuff:OnCreated()
	local caster = self:GetCaster()
	local ability = self:GetAbility()

	self.heal_reduction = 0
	self.apply_break = false

	-- Check for Shard
	if ability and not ability:IsNull() and caster:HasShardCustom() then
		self.heal_reduction = ability:GetSpecialValueFor("shard_heal_reduction")
		self.apply_break = true
	end
end

modifier_astral_trekker_entrapment_debuff.OnRefresh = modifier_astral_trekker_entrapment_debuff.OnCreated

function modifier_astral_trekker_entrapment_debuff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
		MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET,
		MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE,
		MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE,
	}
end

function modifier_astral_trekker_entrapment_debuff:GetModifierHPRegenAmplify_Percentage()
	return 0 - math.abs(self.heal_reduction)
end

function modifier_astral_trekker_entrapment_debuff:GetModifierHealAmplify_PercentageTarget()
	return 0 - math.abs(self.heal_reduction)
end

function modifier_astral_trekker_entrapment_debuff:GetModifierLifestealRegenAmplify_Percentage()
	return 0 - math.abs(self.heal_reduction)
end

function modifier_astral_trekker_entrapment_debuff:GetModifierSpellLifestealRegenAmplify_Percentage()
	return 0 - math.abs(self.heal_reduction)
end

function modifier_astral_trekker_entrapment_debuff:CheckState()
	local state = {
		[MODIFIER_STATE_ROOTED] = true,
		[MODIFIER_STATE_INVISIBLE] = false,
	}
	if self.apply_break then
		state[MODIFIER_STATE_PASSIVES_DISABLED] = true
	end

	return state
end

function modifier_astral_trekker_entrapment_debuff:GetPriority()
	return MODIFIER_PRIORITY_ULTRA
end

function modifier_astral_trekker_entrapment_debuff:GetEffectName()
	return "particles/units/heroes/hero_siren/siren_net.vpcf"
end

function modifier_astral_trekker_entrapment_debuff:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end
