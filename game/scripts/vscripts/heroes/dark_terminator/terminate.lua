LinkLuaModifier("modifier_dark_terminator_terminate_target", "heroes/dark_terminator/terminate.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dark_terminator_terminate_stun", "heroes/dark_terminator/terminate.lua", LUA_MODIFIER_MOTION_NONE)

dark_terminator_terminate = class({})

function dark_terminator_terminate:GetCastPoint()
	local delay = self.BaseClass.GetCastPoint(self)
	local talent = self:GetCaster():FindAbilityByName("special_bonus_unique_dark_terminator_terminate")
	if talent and talent:GetLevel() > 0 then
		delay = delay - talent:GetSpecialValueFor("value")
	end
	return delay
end

function dark_terminator_terminate:OnAbilityPhaseStart()
  local caster = self:GetCaster()
  local target = self:GetCursorTarget()

  -- Sound
  caster:EmitSound("Ability.AssassinateLoad")

  -- Get locations
  local caster_origin = caster:GetAbsOrigin()
  local target_origin = target:GetAbsOrigin()

  -- Calculate travel time of the projectile
  local distance = (target_origin - caster_origin):Length2D()
  local speed = self:GetSpecialValueFor("projectile_speed")
  local travel_time = distance / speed

  -- Apply a modifier that reveals the target
  target:AddNewModifier(caster, self, "modifier_dark_terminator_terminate_target", {duration = self:GetCastPoint() + travel_time})

   -- Store the target(s) in self.storedTarget
  self.storedTarget = {}
  self.storedTarget[1] = target

  return true
end

function dark_terminator_terminate:OnAbilityPhaseInterrupted()
	-- Remove the crosshairs from the target(s)
	if self.storedTarget then
		for _, v in pairs(self.storedTarget) do
			if v then
				v:RemoveModifierByName("modifier_dark_terminator_terminate_target")
			end
		end
	end
end

function dark_terminator_terminate:OnSpellStart()
    local caster = self:GetCaster()

	-- Sound
	caster:EmitSound("Ability.Assassinate")

    -- When there is no cast point
	if not self.storedTarget then
        self.storedTarget = {}
    end

	-- For lotus Orb (and other reflecting stuff that skip cast time) and if list of targets is empty
	local target = self:GetCursorTarget()
	if #self.storedTarget < 1 then
		if target and not target:IsNull() then
			table.insert(self.storedTarget, target)
		else
			return
		end
	end

    -- Because we stored the targets in a table, it is easy to fire a projectile at all of them
    for _, v in pairs(self.storedTarget) do
        if v then
			local info = {
				EffectName = "particles/units/heroes/hero_sniper/sniper_assassinate.vpcf",
				Ability = self,
				Target = v,
				Source = caster,
				bDodgeable = true,
				bProvidesVision = true,
				vSpawnOrigin = caster:GetAbsOrigin(),
				iMoveSpeed = self:GetSpecialValueFor("projectile_speed"),
				iVisionRadius = 250,
				iVisionTeamNumber = caster:GetTeamNumber(),
				iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1
			}
			ProjectileManager:CreateTrackingProjectile(info)
		end
    end
end

function dark_terminator_terminate:OnProjectileHit(target, vLocation)
	local caster = self:GetCaster()

	if not target or target:IsNull() then
		return
	end

	-- Remove the crosshair+vision
    target:RemoveModifierByName("modifier_dark_terminator_terminate_target")

	for k, v in pairs(self.storedTarget) do
		if v == target then
			self.storedTarget[k] = nil
		end
	end

	--local sound_target = "Hero_Sniper.AssassinateProjectile"
	--target:EmitSound(sound_target)

	-- Check for Spell Block; pierces spell immunity partially
	if target:TriggerSpellAbsorb(self) then
		return true
	end

    -- Sound
	target:EmitSound("Hero_Sniper.AssassinateDamage")

	-- Actual stun or mini-stun
	if caster:HasScepter() then
		local stun_duration = target:GetValueChangedByStatusResistance(self:GetSpecialValueFor("scepter_stun_duration"))
		target:AddNewModifier(caster, self, "modifier_dark_terminator_terminate_stun", {duration = stun_duration})
	else
		-- Mini-stun
		target:Interrupt()
	end

	local damage = self:GetSpecialValueFor("damage")
	if caster:HasScepter() then
		damage = self:GetSpecialValueFor("scepter_damage")
	end

	-- Damage
	local damageTable = {
		victim = target,
		attacker = caster,
		damage = damage,
		damage_type = self:GetAbilityDamageType(),
	}

	if not target:IsMagicImmune() and not target:IsInvulnerable() then
		ApplyDamage(damageTable)
	end

    return true
end

---------------------------------------------------------------------------------------------------

modifier_dark_terminator_terminate_target = class({})

function modifier_dark_terminator_terminate_target:IsHidden()
    return false
end

function modifier_dark_terminator_terminate_target:IsDebuff()
    return true
end

function modifier_dark_terminator_terminate_target:IsPurgable()
    return false
end

function modifier_dark_terminator_terminate_target:GetEffectName()
    return "particles/units/heroes/hero_sniper/sniper_crosshair.vpcf"
end

function modifier_dark_terminator_terminate_target:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW
end

function modifier_dark_terminator_terminate_target:CheckState()
    return {
		[MODIFIER_STATE_INVISIBLE] = false,
		[MODIFIER_STATE_PROVIDES_VISION] = true,
    }
end

function modifier_dark_terminator_terminate_target:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PROVIDES_FOW_POSITION,
	}
end

function modifier_dark_terminator_terminate_target:GetModifierProvidesFOWVision()
	return 1
end

function modifier_dark_terminator_terminate_target:GetPriority()
	return MODIFIER_PRIORITY_ULTRA
end

---------------------------------------------------------------------------------------------------

modifier_dark_terminator_terminate_stun = class({})

function modifier_dark_terminator_terminate_stun:IsHidden()
    return false
end

function modifier_dark_terminator_terminate_stun:IsDebuff()
	return true
end

function modifier_dark_terminator_terminate_stun:IsStunDebuff()
	return true
end

function modifier_dark_terminator_terminate_stun:IsPurgable()
    return true
end

function modifier_dark_terminator_terminate_stun:GetEffectName()
	return "particles/generic_gameplay/generic_stunned.vpcf"
end

function modifier_dark_terminator_terminate_stun:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end

function modifier_dark_terminator_terminate_stun:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
	}
end

function modifier_dark_terminator_terminate_stun:GetOverrideAnimation()
	return ACT_DOTA_DISABLED
end

function modifier_dark_terminator_terminate_stun:CheckState()
	return {
		[MODIFIER_STATE_STUNNED] = true,
	}
end
