sohei_dash = class({})

LinkLuaModifier("modifier_sohei_dash_movement", "heroes/sohei/sohei_dash.lua", LUA_MODIFIER_MOTION_HORIZONTAL)
LinkLuaModifier("modifier_sohei_dash_slow", "heroes/sohei/sohei_dash.lua", LUA_MODIFIER_MOTION_NONE)

---------------------------------------------------------------------------------------------------

function sohei_dash:OnSpellStart()
  local caster = self:GetCaster()
  local target_loc = self:GetCursorPosition()
  local caster_loc = caster:GetAbsOrigin()
  local width = self:GetSpecialValueFor("dash_width")
  local max_speed = self:GetSpecialValueFor("dash_speed")
  local move_speed_multiplier = self:GetSpecialValueFor("move_speed_multiplier")
  local range = self:GetSpecialValueFor("dash_range")

  -- Bonus dash range talent
  local talent = caster:FindAbilityByName("special_bonus_sohei_dash_cast_range")
  if talent and talent:GetLevel() > 0 then
    range = range + talent:GetSpecialValueFor("value")
  end

  -- Calculate range with cast range bonuses
  range = range + caster:GetCastRangeBonus()

  -- Calculate direction
  local direction = target_loc - caster_loc

  -- Calculate and cap the distance
  local distance = direction:Length2D()
  if distance > range then
    distance = range
  end

  -- Calculate speed - it's based on caster's movement speed
  local speed = math.min(caster:GetIdealSpeed() * move_speed_multiplier, max_speed)

  -- Normalize direction
  direction.z = 0
  direction = direction:Normalized()

  -- Interrupt existing motion controllers (it should also interrupt existing instances of Dash)
  if caster:IsCurrentlyHorizontalMotionControlled() then
    caster:InterruptMotionControllers(false)
  end

  -- Dash sound
  caster:EmitSound("Sohei.Dash")

  -- Apply motion controller
  caster:AddNewModifier(caster, self, "modifier_sohei_dash_movement", {
    distance = distance,
    speed = speed,
    direction_x = direction.x,
    direction_y = direction.y,
    width = width,
  })
end

---------------------------------------------------------------------------------------------------

-- Dash movement modifier
modifier_sohei_dash_movement = class({})

function modifier_sohei_dash_movement:IsDebuff()
  return false
end

function modifier_sohei_dash_movement:IsHidden()
  return true
end

function modifier_sohei_dash_movement:IsPurgable()
  return true
end

function modifier_sohei_dash_movement:IsStunDebuff()
  return false
end

function modifier_sohei_dash_movement:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
  }
end

function modifier_sohei_dash_movement:GetOverrideAnimation()
  return ACT_DOTA_RUN
end

function modifier_sohei_dash_movement:GetPriority()
  return DOTA_MOTION_CONTROLLER_PRIORITY_HIGHEST
end

function modifier_sohei_dash_movement:CheckState()
  return {
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
    --[MODIFIER_STATE_NO_HEALTH_BAR] = true,
    --[MODIFIER_STATE_INVULNERABLE] = true,
    [MODIFIER_STATE_MAGIC_IMMUNE] = true,
  }
end

if IsServer() then
  function modifier_sohei_dash_movement:OnCreated(event)
    local parent = self:GetParent()

    -- Data sent with AddNewModifier (not available on the client)
    self.direction = Vector(event.direction_x, event.direction_y, 0)
    self.distance = event.distance + 1
    self.speed = event.speed
    self.width = event.width

    ProjectileManager:ProjectileDodge(parent)

    if self:ApplyHorizontalMotionController() == false then
      self:Destroy()
      return
    end

    self.start_pos = parent:GetAbsOrigin()
    local end_pos = self.start_pos + self.direction * self.distance

    -- Trail particle
    local particleName = "particles/hero/sohei/sohei_trail.vpcf"
    local trail_pfx = ParticleManager:CreateParticle(particleName, PATTACH_CUSTOMORIGIN, parent)
    ParticleManager:SetParticleControl(trail_pfx, 0, self.start_pos)
    ParticleManager:SetParticleControl(trail_pfx, 1, end_pos)
    ParticleManager:ReleaseParticleIndex(trail_pfx)
  end

  function modifier_sohei_dash_movement:OnDestroy()
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local ability = self:GetAbility()
    local parent_origin = parent:GetAbsOrigin()
    local caster_team = caster:GetTeamNumber()

    parent:RemoveHorizontalMotionController(self)

    -- Unstuck the parent
    FindClearSpaceForUnit(parent, parent_origin, false)
    ResolveNPCPositions(parent_origin, 128)

    -- Change facing of the parent
    parent:FaceTowards(parent_origin + 128*self.direction)

    local damage = ability:GetSpecialValueFor("damage")

    -- Talent that increases damage
    local talent = caster:FindAbilityByName("special_bonus_unique_sohei_7")
    if talent and talent:GetLevel() > 0 then
      damage = damage + talent:GetSpecialValueFor("value")
    end

    local damage_table = {}
    damage_table.attacker = caster
    damage_table.damage_type = ability:GetAbilityDamageType()
    damage_table.ability = ability
    damage_table.damage = damage

    -- Damage enemies in a line
    local enemies = FindUnitsInLine(caster_team, self.start_pos, parent_origin, nil, self.width, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE)
    for _, enemy in pairs(enemies) do
      if enemy and not enemy:IsNull() then
        -- Apply debuff first
        enemy:AddNewModifier(caster, ability, "modifier_sohei_dash_slow", {duration = ability:GetSpecialValueFor("slow_duration")})
        -- Then damage
        damage_table.victim = enemy
        ApplyDamage(damage_table)
      end
    end
  end

  function modifier_sohei_dash_movement:UpdateHorizontalMotion(parent, deltaTime)
    if not parent or parent:IsNull() or not parent:IsAlive() then
      return
    end

    -- Check if rooted or leashed
    local isRootedOrLeashed = parent:IsRooted() or parent:IsLeashedCustom()
    -- Check if affected by continous dispel
    local isNullified = parent:HasModifier("modifier_item_nullifier_mute")

    if isRootedOrLeashed or isNullified then
      self:Destroy()
      return
    end

    local parentOrigin = parent:GetAbsOrigin()

    local tickTraveled = deltaTime * self.speed
    tickTraveled = math.min(tickTraveled, self.distance)
    if tickTraveled <= 0 then
      self:Destroy()
    end
    local tickOrigin = parentOrigin + tickTraveled * self.direction
    tickOrigin = Vector(tickOrigin.x, tickOrigin.y, GetGroundHeight(tickOrigin, parent))

    parent:SetAbsOrigin(tickOrigin)

    self.distance = self.distance - tickTraveled

    GridNav:DestroyTreesAroundPoint(tickOrigin, self.width, false)
  end

  function modifier_sohei_dash_movement:OnHorizontalMotionInterrupted()
    self:Destroy()
  end
end

---------------------------------------------------------------------------------------------------

-- Dash slow debuff
modifier_sohei_dash_slow = class({})

function modifier_sohei_dash_slow:IsDebuff()
  return true
end

function modifier_sohei_dash_slow:IsHidden()
  return false
end

function modifier_sohei_dash_slow:IsPurgable()
  return true
end

function modifier_sohei_dash_slow:IsStunDebuff()
  return false
end

function modifier_sohei_dash_slow:OnCreated()
  local parent = self:GetParent()
  local movement_slow = self:GetAbility():GetSpecialValueFor("move_speed_slow_pct")
  local attack_slow = self:GetAbility():GetSpecialValueFor("attack_speed_slow")

  -- Talent that increases the slow amount
  local talent = self:GetCaster():FindAbilityByName("special_bonus_sohei_dash_slow")
  if talent and talent:GetLevel() > 0 then
    movement_slow = movement_slow + talent:GetSpecialValueFor("value")
  end

  if IsServer() then
    -- Slow is reduced with Status Resistance
    self.slow = parent:GetValueChangedByStatusResistance(movement_slow)
    self.attack_speed = parent:GetValueChangedByStatusResistance(attack_slow)
  else
    self.slow = movement_slow
    self.attack_speed = attack_slow
  end
end

function modifier_sohei_dash_slow:OnRefresh()
  self:OnCreated()
end

function modifier_sohei_dash_slow:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
  }
end

function modifier_sohei_dash_slow:GetModifierMoveSpeedBonus_Percentage()
  return 0 - math.abs(self.slow)
end

function modifier_sohei_dash_slow:GetModifierAttackSpeedBonus_Constant()
  return 0 - math.abs(self.attack_speed)
end
