sohei_dash = class({})

LinkLuaModifier("modifier_sohei_dash_movement", "heroes/sohei/sohei_dash.lua", LUA_MODIFIER_MOTION_HORIZONTAL)
LinkLuaModifier("modifier_sohei_dash_slow", "heroes/sohei/sohei_dash.lua", LUA_MODIFIER_MOTION_NONE)

---------------------------------------------------------------------------------------------------

function sohei_dash:OnSpellStart()
  local caster = self:GetCaster()
  local caster_loc = caster:GetAbsOrigin() -- or  GetOrigin()
  local target_loc = self:GetCursorPosition()
  local speed = self:GetSpecialValueFor("dash_speed")
  local width = self:GetSpecialValueFor("dash_width")

  -- Calculate direction
  local direction = target_loc - caster_loc
  direction.z = 0.0
  direction = direction:Normalized()

  -- Calculate distance
  local distance = (target_loc - caster_loc):Length2D()

  -- Calculate duration
  local duration = distance / speed

  caster:RemoveModifierByName("modifier_sohei_dash_movement")
  caster:EmitSound("Sohei.Dash")
  caster:StartGesture(ACT_DOTA_RUN)

  caster:AddNewModifier(caster, self, "modifier_sohei_dash_movement", {
    duration = duration,
    distance = distance,
    speed = speed,
	direction_x = direction.x,
	direction_y = direction.y,
	width = width,
  } )

  local talent = caster:FindAbilityByName("special_bonus_sohei_dash_invulnerable")

  if talent and talent:GetLevel() > 0 then
    ProjectileManager:ProjectileDodge(caster)
  end
end

function sohei_dash:OnUnStolen()
  local caster = self:GetCaster()
  local modifier_charges = caster:FindModifierByName("modifier_sohei_dash_charges")
  if modifier_charges then
    caster:RemoveModifierByName("modifier_sohei_dash_charges")
  end
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
  return false
end

function modifier_sohei_dash_movement:IsStunDebuff()
  return false
end

function modifier_sohei_dash_movement:GetPriority()
  return DOTA_MOTION_CONTROLLER_PRIORITY_HIGHEST
end

function modifier_sohei_dash_movement:CheckState()
  local state = {
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    [MODIFIER_STATE_NO_HEALTH_BAR] = true
  }

  local caster = self:GetParent()
  local talent = caster:FindAbilityByName("special_bonus_sohei_dash_invulnerable")

  if talent and talent:GetLevel() > 0 then
    state[MODIFIER_STATE_INVULNERABLE] = true
    state[MODIFIER_STATE_MAGIC_IMMUNE] = true
  end

  return state
end

if IsServer() then
  function modifier_sohei_dash_movement:OnCreated( event )
    -- Movement parameters
    local parent = self:GetParent()
    local ability = self:GetAbility()
    self.start_pos = parent:GetAbsOrigin()
    -- Data sent by AddNewModifier
    self.direction = Vector(event.direction_x, event.direction_y, 0)
    self.distance = event.distance + 1
    self.speed = event.speed
    self.width = event.width

    if self:ApplyHorizontalMotionController() == false then
      self:Destroy()
      return
    end

    local particleName = "particles/hero/sohei/sohei_trail.vpcf"

    if parent:HasModifier('modifier_arcana_dbz') then
      particleName = "particles/hero/sohei/arcana/dbz/sohei_trail_dbz.vpcf"
    elseif parent:HasModifier('modifier_arcana_pepsi') then
      particleName = "particles/hero/sohei/arcana/pepsi/sohei_trail_pepsi.vpcf"
    end

    local end_pos = self.start_pos + self.direction * self.distance

    -- Trail particle
    local trail_pfx = ParticleManager:CreateParticle( particleName, PATTACH_CUSTOMORIGIN, parent )
    ParticleManager:SetParticleControl( trail_pfx, 0, self.start_pos )
    ParticleManager:SetParticleControl( trail_pfx, 1, end_pos )
    ParticleManager:ReleaseParticleIndex( trail_pfx )
  end

  function modifier_sohei_dash_movement:OnDestroy()
    local parent = self:GetParent()
    local ability = self:GetAbility()
    local parent_origin = parent:GetAbsOrigin()

    parent:FadeGesture(ACT_DOTA_RUN)
    parent:RemoveHorizontalMotionController(self)
    ResolveNPCPositions(parent_origin, 128)
    parent:FaceTowards(parent_origin + 128*self.direction)

    local enemies = FindUnitsInLine(parent:GetTeamNumber(), self.start_pos, parent_origin, nil, self.width, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE)
    local damage_table = {}
    damage_table.attacker = parent
    damage_table.damage_type = ability:GetAbilityDamageType()
    damage_table.ability = ability
    damage_table.damage = ability:GetSpecialValueFor("damage")

    for _,unit in pairs(enemies) do
      if unit and not unit:IsNull() then
        unit:AddNewModifier(parent, ability, "modifier_sohei_dash_slow", { duration = ability:GetSpecialValueFor("slow_duration") })
        damage_table.victim = unit
        ApplyDamage(damage_table)
      end
    end

    -- Dash with Scepter heals allies
    if parent:HasScepter() then
      local do_sound = false
      local allies = FindUnitsInLine(parent:GetTeamNumber(), self.start_pos, parent_origin, nil, self.width, DOTA_UNIT_TARGET_TEAM_FRIENDLY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE)
      for _,ally in pairs(allies) do
        if ally and not ally:IsNull() and ally ~= parent then
          do_sound = true
          local base_heal_amount = ability:GetSpecialValueFor("scepter_base_heal")
          local hp_as_heal = ability:GetSpecialValueFor("scepter_hp_as_heal")
          local heal_amount_based_on_hp = parent:GetHealth() * hp_as_heal/100

          ally:Heal(base_heal_amount+heal_amount_based_on_hp, ability)

          local part = ParticleManager:CreateParticle("particles/units/heroes/hero_omniknight/omniknight_purification.vpcf", PATTACH_ABSORIGIN_FOLLOW, ally)
          ParticleManager:SetParticleControl(part, 0, ally:GetAbsOrigin())
          ParticleManager:SetParticleControl(part, 1, Vector(ally:GetModelRadius(), 1, 1 ))
          ParticleManager:ReleaseParticleIndex(part)

          SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, ally, base_heal_amount+heal_amount_based_on_hp, nil)
        end
      end
      if do_sound then
        parent:EmitSound("Sohei.PalmOfLife.Heal")
      end
    end
  end

  function modifier_sohei_dash_movement:UpdateHorizontalMotion( parent, deltaTime )
    local parentOrigin = parent:GetAbsOrigin()

    local tickSpeed = self.speed * deltaTime
    tickSpeed = math.min( tickSpeed, self.distance )
    local tickOrigin = parentOrigin + ( tickSpeed * self.direction )

    parent:SetAbsOrigin( tickOrigin )

    self.distance = self.distance - tickSpeed

    GridNav:DestroyTreesAroundPoint( tickOrigin, self.width, false )
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

function modifier_sohei_dash_slow:OnCreated(event)
  local parent = self:GetParent()
  local movement_slow = self:GetAbility():GetSpecialValueFor("move_speed_slow_pct")
  if IsServer() then
    -- Slow is reduced with Status Resistance
    self.slow = parent:GetValueChangedByStatusResistance(movement_slow)
  else
    self.slow = movement_slow
  end
end

function modifier_sohei_dash_slow:OnRefresh(event)
  local parent = self:GetParent()
  local movement_slow = self:GetAbility():GetSpecialValueFor("move_speed_slow_pct")
  if IsServer() then
    -- Slow is reduced with Status Resistance
    self.slow = parent:GetValueChangedByStatusResistance(movement_slow)
  else
    self.slow = movement_slow
  end
end

function modifier_sohei_dash_slow:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
  }

  return funcs
end

function modifier_sohei_dash_slow:GetModifierMoveSpeedBonus_Percentage()
  return self.slow
end
