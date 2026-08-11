paladin_storm_hammer = paladin_storm_hammer or class({})

LinkLuaModifier("modifier_paladin_storm_hammer", "heroes/paladin/paladin_storm_hammer.lua", LUA_MODIFIER_MOTION_NONE)

function paladin_storm_hammer:GetAOERadius()
	return self:GetSpecialValueFor("bolt_aoe")
end

function paladin_storm_hammer:CastFilterResultTarget(target)
	local default_result = self.BaseClass.CastFilterResultTarget(self, target)

	if target:IsCustomWardTypeUnit() then
		return UF_FAIL_CUSTOM
	end

	return default_result
end

function paladin_storm_hammer:GetCustomCastErrorTarget(target)
	if target:IsCustomWardTypeUnit() then
		return "#dota_hud_error_cant_cast_on_other"
	end
	return ""
end

function paladin_storm_hammer:GetCooldown(level)
	local caster = self:GetCaster()
	local base_cooldown = self.BaseClass.GetCooldown(self, level)

	-- Talent that decreases cooldown
	local talent = caster:FindAbilityByName("special_bonus_unique_paladin_8")
	if talent and talent:GetLevel() > 0 then
		return base_cooldown - math.abs(talent:GetSpecialValueFor("value"))
	end

	return base_cooldown
end

function paladin_storm_hammer:OnSpellStart()
	local vision_radius = self:GetSpecialValueFor("vision_radius")
	local bolt_speed = self:GetSpecialValueFor("bolt_speed")
	local caster = self:GetCaster()

	local info = {
		EffectName = "particles/units/heroes/hero_sven/sven_spell_storm_bolt.vpcf",
		Ability = self,
		iMoveSpeed = bolt_speed,
		Source = caster,
		Target = self:GetCursorTarget(),
		bDodgeable = true,
		bProvidesVision = true,
		iVisionTeamNumber = caster:GetTeamNumber(),
		iVisionRadius = vision_radius,
		iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_2,
	}

	ProjectileManager:CreateTrackingProjectile(info)

	-- Sound on caster
	caster:EmitSound("Hero_Sven.StormBolt")
end

function paladin_storm_hammer:OnProjectileHit(target, location)
	-- If target doesn't exist (disjointed), don't continue
	if not target or target:IsNull() then
		return
	end

	-- Check for spell block
	if not target:TriggerSpellAbsorb(self) then
		local caster = self:GetCaster()

		-- Sound on target
		target:EmitSound("Hero_Sven.StormBoltImpact")

		-- KVs
		local bolt_aoe = self:GetSpecialValueFor("bolt_aoe")
		local bolt_damage = self:GetSpecialValueFor("bolt_damage")
		local bolt_stun_duration = self:GetSpecialValueFor("bolt_stun_duration")

		-- Talent that increases stun duration
		local talent_1 = caster:FindAbilityByName("special_bonus_unique_paladin_7")
		if talent_1 and talent_1:GetLevel() > 0 then
			bolt_stun_duration = bolt_stun_duration + talent_1:GetSpecialValueFor("value")
		end

		-- Talent that dispels enemies
		local has_dispel = false
		local talent_2 = caster:FindAbilityByName("special_bonus_unique_paladin_4")
		if talent_2 and talent_2:GetLevel() > 0 then
			has_dispel = true
			self:DispelEnemy(target) -- here because if target is invulnerable it won't be dispelled later
		end

		-- Targetting constants
		local target_team = self:GetAbilityTargetTeam() or DOTA_UNIT_TARGET_TEAM_ENEMY
		local target_type = self:GetAbilityTargetType() or bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
		local target_flags = self:GetAbilityTargetFlags() or DOTA_UNIT_TARGET_FLAG_NONE

		local enemies = FindUnitsInRadius(caster:GetTeamNumber(), target:GetOrigin(), target, bolt_aoe, target_team, target_type, target_flags, FIND_ANY_ORDER, false)
		for _, enemy in pairs(enemies) do
			if enemy and not enemy:IsMagicImmune() then
				-- Calculate stun duration with status resistance in mind
				local stun_duration = enemy:GetValueChangedByStatusResistance(bolt_stun_duration)
				enemy:AddNewModifier(caster, self, "modifier_paladin_storm_hammer", {duration = stun_duration})

				-- Dispel enemies if not the target and if caster has the talent
				if has_dispel and enemy ~= target then
					self:DispelEnemy(enemy)
				end

				local damage_table = {}
				damage_table.victim = enemy
				damage_table.attacker = caster
				damage_table.damage = bolt_damage
				damage_table.damage_type = self:GetAbilityDamageType()
				damage_table.ability = self

				ApplyDamage(damage_table)
			end
		end
	end

	return true
end

function paladin_storm_hammer:ProcsMagicStick()
	return true
end

function paladin_storm_hammer:DispelEnemy(target)
	target:RemoveModifierByName("modifier_brewmaster_storm_cyclone")

	-- Basic Dispel (Buffs)
	local RemovePositiveBuffs = true
	local RemoveDebuffs = false
	local BuffsCreatedThisFrameOnly = false
	local RemoveStuns = false
	local RemoveExceptions = false
	target:Purge(RemovePositiveBuffs, RemoveDebuffs, BuffsCreatedThisFrameOnly, RemoveStuns, RemoveExceptions)

	-- Kill the target if its summoned, dominated or an illusion
	if target:IsSummoned() or target:IsDominated() or (target:IsIllusion() and not target:IsStrongIllusionCustom()) then
		target:Kill(self, self:GetCaster())
	end
end

---------------------------------------------------------------------------------------------------

modifier_paladin_storm_hammer = modifier_paladin_storm_hammer or class({})

function modifier_paladin_storm_hammer:IsHidden() -- needs tooltip
	return false
end

function modifier_paladin_storm_hammer:IsDebuff()
	return true
end

function modifier_paladin_storm_hammer:IsStunDebuff()
	return true
end

function modifier_paladin_storm_hammer:IsPurgable()
	return true
end

function modifier_paladin_storm_hammer:GetEffectName()
	return "particles/generic_gameplay/generic_stunned.vpcf"
end

function modifier_paladin_storm_hammer:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end

function modifier_paladin_storm_hammer:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
	}
end

function modifier_paladin_storm_hammer:GetOverrideAnimation()
	return ACT_DOTA_DISABLED
end

function modifier_paladin_storm_hammer:CheckState()
	return {
		[MODIFIER_STATE_STUNNED] = true,
	}
end
