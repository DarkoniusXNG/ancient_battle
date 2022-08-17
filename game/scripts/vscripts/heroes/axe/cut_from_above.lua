LinkLuaModifier("modifier_axe_leap_from_above", "heroes/axe/cut_from_above.lua", LUA_MODIFIER_MOTION_BOTH)
LinkLuaModifier("modifier_axe_custom_cut_from_above_buff", "heroes/axe/cut_from_above.lua", LUA_MODIFIER_MOTION_NONE)

axe_custom_cut_from_above = class({})

function axe_custom_cut_from_above:GetAOERadius()
  return self:GetSpecialValueFor("radius")
end

function axe_custom_cut_from_above:GetCastRange(location, target)
  local caster = self:GetCaster()
  local base_cast_range = self.BaseClass.GetCastRange(self, location, target)

  if caster:HasScepter() then
    return base_cast_range + self:GetSpecialValueFor("scepter_bonus_cast_range")
  end

  return base_cast_range
end

function axe_custom_cut_from_above:OnSpellStart()
  local caster = self:GetCaster()
  local target_point = self:GetCursorPosition()

  local direction = target_point - caster:GetAbsOrigin()
  local distance = direction:Length2D()
  local max_duration = self:GetSpecialValueFor("leap_duration")
  local speed = self:GetSpecialValueFor("leap_speed")
  local duration = math.min(distance / speed, max_duration)
  local x_motion_tick = direction.x * 0.03 / duration
  local y_motion_tick = direction.y * 0.03 / duration
  local height = self:GetSpecialValueFor("leap_height")
  height = math.max(height, height * distance / 300)

  -- Interrupt existing motion controllers
  if caster:IsCurrentlyHorizontalMotionControlled() then
    caster:InterruptMotionControllers(false)
  end
  
  -- Apply motion controller
  caster:AddNewModifier(caster, self, "modifier_axe_leap_from_above", {
    duration = duration + 0.03,
    x_tick = x_motion_tick,
    y_tick = y_motion_tick,
    height = height,
    z_max_time = duration,
    distance = distance
  })
end

---------------------------------------------------------------------------------------------------

modifier_axe_leap_from_above = class({})

function modifier_axe_leap_from_above:IsHidden()
  return true
end

function modifier_axe_leap_from_above:IsDebuff()
  return false
end

function modifier_axe_leap_from_above:IsPurgable()
  return false
end

function modifier_axe_leap_from_above:GetPriority()
  return DOTA_MOTION_CONTROLLER_PRIORITY_HIGHEST
end

function modifier_axe_leap_from_above:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
    MODIFIER_PROPERTY_OVERRIDE_ANIMATION_RATE,
    MODIFIER_PROPERTY_DISABLE_TURNING
  }
end

function modifier_axe_leap_from_above:GetModifierDisableTurning()
  return 1
end

function modifier_axe_leap_from_above:GetOverrideAnimation()
  return ACT_DOTA_CAST_ABILITY_4
end

function modifier_axe_leap_from_above:GetOverrideAnimationRate()
  return 0.833
end

function modifier_axe_leap_from_above:CheckState()
  return {
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
  }
end

if IsServer() then
  function modifier_axe_leap_from_above:OnCreated(keys)
    self.x_tick = keys.x_tick
    self.y_tick = keys.y_tick
    self.z_max_time = keys.z_max_time
    self.z_time = 0

    self.origin = self:GetParent():GetAbsOrigin()
    self.direction = self:GetParent():GetForwardVector()
    self.velocity = keys.distance / keys.z_max_time
    self.jump = 0
    self.height = keys.height

    if self:ApplyHorizontalMotionController() == false then
      self:Destroy()
      return
    end

    if self:ApplyVerticalMotionController() == false then
      self:Destroy()
      return
    end
  end

  function modifier_axe_leap_from_above:OnHorizontalMotionInterrupted()
    self:Destroy()
  end

  function modifier_axe_leap_from_above:OnVerticalMotionInterrupted()
    self:Destroy()
  end

  function modifier_axe_leap_from_above:UpdateHorizontalMotion(parent, delta_time)
    parent:SetAbsOrigin(parent:GetAbsOrigin() + Vector(self.x_tick, self.y_tick, self.jump))
  end

  function modifier_axe_leap_from_above:UpdateVerticalMotion(parent, delta_time)
    self.z_time = self.z_time + delta_time
    local origin = parent:GetAbsOrigin()
    local ground_position = GetGroundPosition(origin, parent)
    self.jump = 4 * self.height * self.z_time * (self.z_max_time - self.z_time)
    parent:SetAbsOrigin(ground_position + Vector(0, 0, self.jump))
  end

  function modifier_axe_leap_from_above:OnDestroy()
    local caster = self:GetParent()
    local ability = self:GetAbility()
    local landing_point = caster:GetAbsOrigin()

    local damage = ability:GetSpecialValueFor("damage_kill_threshold")
    local damage_radius = ability:GetSpecialValueFor("radius")
    local buff_duration = ability:GetSpecialValueFor("buff_duration")
    local buff_radius = ability:GetSpecialValueFor("buff_radius")
    if caster:HasScepter() then
      damage = ability:GetSpecialValueFor("scepter_damage_kill_threshold")
    end

    caster:RemoveHorizontalMotionController(self)
    caster:RemoveVerticalMotionController(self)
    ResolveNPCPositions(landing_point, 128)
    GridNav:DestroyTreesAroundPoint(landing_point, damage_radius, false)

    local units = FindUnitsInRadius(
      caster:GetTeamNumber(),
      landing_point,
      nil,
      damage_radius,
      ability:GetAbilityTargetTeam(),
      ability:GetAbilityTargetType(),
      ability:GetAbilityTargetFlags(),
      FIND_ANY_ORDER,
      false
    )

    local hit_something = #units > 0
    local killed_something = false
    local killed_a_hero = false
    for _, unit in pairs(units) do
      if unit and not unit:IsNull() then
        if unit:GetHealth() <= damage * (1 + (caster:GetSpellAmplification(false) * 0.01)) then
          -- Kill the unit
          unit:Kill(ability, caster)
          killed_something = true
          -- Axe Chop Sound with Cut From Above (Culling Blade) when he kills heroes (not illusions)
          if unit:IsRealHero() then
            caster:EmitSound("Hero_Axe.Culling_Blade_Success")
            killed_a_hero = true
          end
        else
          ApplyDamage({
            victim = unit,
            attacker = caster,
            damage = damage,
            damage_type = ability:GetAbilityDamageType(),
            ability = ability,
          })
        end
      end
    end

    if killed_something then
      local allies = FindUnitsInRadius(
        caster:GetTeamNumber(),
        landing_point,
        nil,
        buff_radius,
        DOTA_UNIT_TARGET_TEAM_FRIENDLY,
        bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
        DOTA_UNIT_TARGET_FLAG_INVULNERABLE,
        FIND_ANY_ORDER,
        false
      )
      for _, ally in pairs(allies) do
        if ally and not ally:IsNull() then
          ally:AddNewModifier(caster, ability, "modifier_axe_custom_cut_from_above_buff", {duration = buff_duration})
        end
      end
      -- Particle
      local direction = (self.direction or caster:GetForwardVector()):Normalized()
      local culling_kill_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_axe/axe_culling_blade_kill.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
      ParticleManager:SetParticleControl(culling_kill_particle, 4, landing_point)
      ParticleManager:SetParticleControlForward(culling_kill_particle, 3, direction)
      ParticleManager:SetParticleControlForward(culling_kill_particle, 4, direction)
      ParticleManager:ReleaseParticleIndex(culling_kill_particle)
    end

    if killed_a_hero then
      ability:EndCooldown()
    elseif killed_something then
      caster:EmitSound("Hero_Axe.Culling_Blade_Success")
    elseif hit_something then
      caster:EmitSound("Hero_Axe.Culling_Blade_Fail")
    end
  end
end

---------------------------------------------------------------------------------------------------

modifier_axe_custom_cut_from_above_buff = class({})

function modifier_axe_custom_cut_from_above_buff:IsHidden() -- needs tooltip
  return false
end

function modifier_axe_custom_cut_from_above_buff:IsDebuff()
  return false
end

function modifier_axe_custom_cut_from_above_buff:IsPurgable()
  return true
end

function modifier_axe_custom_cut_from_above_buff:OnCreated()
  self.move_speed = 20
  self.attack_speed = 20
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.move_speed = ability:GetSpecialValueFor("bonus_move_speed_on_kill")
    self.attack_speed = ability:GetSpecialValueFor("bonus_attack_speed_on_kill")
  end
end

function modifier_axe_custom_cut_from_above_buff:OnRefresh()
  self:OnCreated()
end

function modifier_axe_custom_cut_from_above_buff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
  }
end

function modifier_axe_custom_cut_from_above_buff:GetModifierMoveSpeedBonus_Percentage()
  return self.move_speed
end

function modifier_axe_custom_cut_from_above_buff:GetModifierAttackSpeedBonus_Constant()
  return self.attack_speed
end

function modifier_axe_custom_cut_from_above_buff:GetEffectName()
  return "particles/units/heroes/hero_axe/axe_cullingblade_sprint.vpcf"
end

function modifier_axe_custom_cut_from_above_buff:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end
