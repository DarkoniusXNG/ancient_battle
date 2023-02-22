brewmaster_custom_drunken_haze = class({})

LinkLuaModifier("modifier_custom_drunken_haze_debuff", "heroes/brewmaster/drunken_haze.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_drunken_haze_fizzle", "heroes/brewmaster/drunken_haze.lua", LUA_MODIFIER_MOTION_NONE)

function brewmaster_custom_drunken_haze:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function brewmaster_custom_drunken_haze:CastFilterResultTarget(target)
	local default_result = self.BaseClass.CastFilterResultTarget(self, target)

	if target:IsCustomWardTypeUnit() then
		return UF_FAIL_CUSTOM
	end

	return default_result
end

function brewmaster_custom_drunken_haze:GetCustomCastErrorTarget(target)
	if target:IsCustomWardTypeUnit() then
		return "#dota_hud_error_cant_cast_on_other"
	end
	return ""
end

function brewmaster_custom_drunken_haze:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	if not target or not caster then
		return
	end

	-- KVs
	--local vision_radius = self:GetSpecialValueFor("projectile_vision")
	local speed = self:GetSpecialValueFor("projectile_speed")

	local info = {
		EffectName = "particles/custom/brewmaster_drunken_haze.vpcf",
		Ability = self,
		iMoveSpeed = speed,
		Source = caster,
		Target = target,
		bDodgeable = true,
		bProvidesVision = false,
		--iVisionTeamNumber = caster:GetTeamNumber(),
		--iVisionRadius = vision_radius,
		iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1, -- DOTA_PROJECTILE_ATTACHMENT_ATTACK_2
	}

	ProjectileManager:CreateTrackingProjectile(info)

	-- Sound on caster
	caster:EmitSound("Hero_Brewmaster.CinderBrew.Cast") -- "Hero_Brewmaster.DrunkenHaze.Cast"
end

function brewmaster_custom_drunken_haze:OnProjectileHit(target, location)
	-- If target doesn't exist (disjointed), don't continue
	if not target or target:IsNull() then
		return
	end

	-- Check for spell block and spell immunity (latter because of lotus)
	if not target:TriggerSpellAbsorb(self) and not target:IsMagicImmune() then
		local caster = self:GetCaster()

		-- Sound on target
		target:EmitSound("Hero_Brewmaster.CinderBrew.Target") -- "Hero_Brewmaster.DrunkenHaze.Target"

		-- KVs
		local hero_duration = self:GetSpecialValueFor("duration_heroes")
		local creep_duration = self:GetSpecialValueFor("duration_creeps")
		local radius = self:GetSpecialValueFor("radius")
		local target_team = self:GetAbilityTargetTeam() or DOTA_UNIT_TARGET_TEAM_ENEMY
		local target_type = self:GetAbilityTargetType() or bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
		local target_flags = self:GetAbilityTargetFlags() or DOTA_UNIT_TARGET_FLAG_NONE

		-- Talent that applies spell fizzle
		local talent = caster:FindAbilityByName("special_bonus_unique_brewmaster_drunken_haze_fizzle")
		local has_talent = talent and talent:GetLevel() > 0

		local enemies = FindUnitsInRadius(
			caster:GetTeamNumber(),
			target:GetAbsOrigin(),
			nil,
			radius,
			target_team,
			target_type,
			target_flags,
			FIND_ANY_ORDER,
			false
		)

		for _, enemy in pairs(enemies) do
			if enemy and not enemy:IsNull() and not enemy:IsMagicImmune() and not enemy:IsCustomWardTypeUnit() then
				if enemy:IsRealHero() then
					enemy:AddNewModifier(caster, self, "modifier_custom_drunken_haze_debuff", {duration = hero_duration})
					if has_talent then
						enemy:AddNewModifier(caster, self, "modifier_drunken_haze_fizzle", {duration = hero_duration})
					end
				else
					enemy:AddNewModifier(caster, self, "modifier_custom_drunken_haze_debuff", {duration = creep_duration})
				end
			end
		end
	end

	return true
end

function brewmaster_custom_drunken_haze:ProcsMagicStick()
	return true
end

---------------------------------------------------------------------------------------------------

if modifier_custom_drunken_haze_debuff == nil then
	modifier_custom_drunken_haze_debuff = class({})
end

function modifier_custom_drunken_haze_debuff:IsHidden() -- needs tooltip
	return false
end

function modifier_custom_drunken_haze_debuff:IsDebuff()
	return true
end

function modifier_custom_drunken_haze_debuff:IsPurgable()
	return true
end

function modifier_custom_drunken_haze_debuff:RemoveOnDeath()
	return true
end

function modifier_custom_drunken_haze_debuff:OnCreated()
	local parent = self:GetParent()
	local ability = self:GetAbility()

	local movement_slow = 15
	self.blind_pct = 50

	if ability and not ability:IsNull() then
		movement_slow = ability:GetSpecialValueFor("movement_slow")
		self.blind_pct = ability:GetSpecialValueFor("miss_chance")
	end

	if IsServer() then
		-- Slow is reduced with Status Resistance
		self.slow = parent:GetValueChangedByStatusResistance(movement_slow)
	else
		self.slow = movement_slow
	end
end

function modifier_custom_drunken_haze_debuff:OnRefresh()
	self:OnCreated()
end

function modifier_custom_drunken_haze_debuff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_MISS_PERCENTAGE,
	}
end

function modifier_custom_drunken_haze_debuff:GetModifierMoveSpeedBonus_Percentage()
	return 0 - math.abs(self.slow)
end

function modifier_custom_drunken_haze_debuff:GetModifierMiss_Percentage()
	return self.blind_pct
end

function modifier_custom_drunken_haze_debuff:GetStatusEffectName()
	return "particles/status_fx/status_effect_brewmaster_cinder_brew.vpcf"
end

function modifier_custom_drunken_haze_debuff:StatusEffectPriority()
	return 5
end

function modifier_custom_drunken_haze_debuff:GetEffectName()
	return "particles/units/heroes/hero_brewmaster/brewmaster_cinder_brew_debuff.vpcf"
end

function modifier_custom_drunken_haze_debuff:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW -- follow_origin
end

---------------------------------------------------------------------------------------------------

if modifier_drunken_haze_fizzle == nil then
	modifier_drunken_haze_fizzle = class({})
end

function modifier_drunken_haze_fizzle:IsHidden()
	return true
end

function modifier_drunken_haze_fizzle:IsDebuff()
	return true
end

function modifier_drunken_haze_fizzle:IsPurgable()
	return true
end

function modifier_drunken_haze_fizzle:RemoveOnDeath()
	return true
end
