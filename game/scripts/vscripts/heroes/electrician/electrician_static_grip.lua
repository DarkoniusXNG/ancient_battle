electrician_static_grip = class({})

LinkLuaModifier("modifier_electrician_static_grip", "heroes/electrician/electrician_static_grip.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_electrician_static_grip_movement", "heroes/electrician/electrician_static_grip.lua", LUA_MODIFIER_MOTION_HORIZONTAL)
LinkLuaModifier("modifier_electrician_static_grip_debuff_tracker", "heroes/electrician/electrician_static_grip.lua", LUA_MODIFIER_MOTION_NONE)

function electrician_static_grip:GetChannelTime()
  local caster = self:GetCaster()

  -- Talent that makes Static Grip non-channel (pseudo-channel)
  local talent = caster:FindAbilityByName("special_bonus_electrician_static_grip_non_channel")
  if talent and talent:GetLevel() > 0 then
    return 0
  end

  if self.modGrip and not self.modGrip:IsNull() then
    return self.modGrip:GetDuration()
  end

  return 0
end

function electrician_static_grip:GetBehavior()
  local caster = self:GetCaster()

  -- Talent that makes Static Grip non-channel (pseudo-channel)
  local talent = caster:FindAbilityByName("special_bonus_electrician_static_grip_non_channel")
  if talent and talent:GetLevel() > 0 then
    return DOTA_ABILITY_BEHAVIOR_UNIT_TARGET
  end

  return DOTA_ABILITY_BEHAVIOR_UNIT_TARGET + DOTA_ABILITY_BEHAVIOR_CHANNELLED
end

function electrician_static_grip:OnSpellStart()
  local caster = self:GetCaster()
  local target = self:GetCursorTarget()

  if not target or not caster then
    return
  end

  -- Check for spell block and spell immunity (latter because of lotus)
  if target:TriggerSpellAbsorb(self) or target:IsMagicImmune() then
    return
  end

  local durationMax = self:GetSpecialValueFor("channel_time")

  -- Status Resistance fix
  durationMax = target:GetValueChangedByStatusResistance(durationMax)

  -- create the stun modifier on target
  target:AddNewModifier(caster, self, "modifier_electrician_static_grip", {duration = durationMax})

  -- create the movement modifier on caster if he doesn't have the talent
  local talent = caster:FindAbilityByName("special_bonus_electrician_static_grip_non_channel")
  if talent and talent:GetLevel() > 0 then
    caster:AddNewModifier(caster, self, "modifier_electrician_static_grip_debuff_tracker", {duration = durationMax})
  else
    caster:AddNewModifier(caster, self, "modifier_electrician_static_grip_movement", {target = target:entindex(), duration = durationMax})
  end
end

function electrician_static_grip:OnChannelFinish(interrupted)
  -- destroy the stun modifier if the channel is interrupted
  if self.modGrip and not self.modGrip:IsNull() then
    self.modGrip:Destroy()
  end
end

---------------------------------------------------------------------------------------------------

modifier_electrician_static_grip = class({})

function modifier_electrician_static_grip:IsDebuff()
  return true
end

function modifier_electrician_static_grip:IsHidden()
  return false
end

function modifier_electrician_static_grip:IsPurgable()
  return true
end

function modifier_electrician_static_grip:IsStunDebuff()
  return true
end

function modifier_electrician_static_grip:GetPriority()
  return MODIFIER_PRIORITY_ULTRA
end

--function modifier_electrician_static_grip:GetAttributes()
  --return MODIFIER_ATTRIBUTE_MULTIPLE
--end

function modifier_electrician_static_grip:CheckState()
  return {
    [MODIFIER_STATE_STUNNED] = true,
    [MODIFIER_STATE_INVISIBLE] = false,
    [MODIFIER_STATE_FROZEN] = true,
  }
end

function modifier_electrician_static_grip:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PROVIDES_FOW_POSITION,
  }
end

function modifier_electrician_static_grip:GetModifierProvidesFOWVision()
  return 1
end

function modifier_electrician_static_grip:OnCreated(event)
  local ability = self:GetAbility()

	-- link modifier to ability
	-- this can't be done in OnSpellStuff as that's server-side only
	-- so we have to make sure that at least this part of OnCreated
	-- is ran on the client
  ability.modGrip = self

  if IsServer() then
    local parent = self:GetParent()
    local caster = self:GetCaster()

    -- grab ability specials
    local damageInterval = ability:GetSpecialValueFor("damage_interval")
    local damage_per_second = ability:GetSpecialValueFor("damage_per_second")
    -- Bonus damage talent
    local talent = caster:FindAbilityByName("special_bonus_electrician_static_grip_damage")
    if talent and talent:GetLevel() > 0 then
      damage_per_second = damage_per_second + talent:GetSpecialValueFor("value")
    end
    self.damagePerInterval = damage_per_second * damageInterval
    self.damageType = ability:GetAbilityDamageType()

    -- create the particle
    self.part = ParticleManager:CreateParticle( "particles/units/heroes/hero_stormspirit/stormspirit_electric_vortex.vpcf", PATTACH_POINT_FOLLOW, caster )
    ParticleManager:SetParticleControlEnt( self.part, 0, caster, PATTACH_POINT_FOLLOW, "attach_attack1", caster:GetAbsOrigin(), true )
    ParticleManager:SetParticleControlEnt( self.part, 1, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true )

    -- play sound
    parent:EmitSound("Hero_StormSpirit.ElectricVortex")

    -- cast animation
    --caster:StartGesture( ACT_DOTA_CAST_ABILITY_3 )

    -- Apply first damage tick immediately
    self:OnIntervalThink()

    -- start thinking
    self:StartIntervalThink(damageInterval)
  end
end

function modifier_electrician_static_grip:OnRefresh(event)
  local ability = self:GetAbility()
  local parent = self:GetParent()
  local caster = self:GetCaster()

  local damageInterval = 0.25
  local damage_per_second = 50
  local damage_type = DAMAGE_TYPE_MAGICAL
  if ability and not ability:IsNull() then
    -- link modifier to ability
    -- this can't be done in OnSpellStuff as that's server-side only
    -- so we have to make sure that at least this part of OnRefresh
    -- is ran on the client
    ability.modGrip = self

    damageInterval = ability:GetSpecialValueFor("damage_interval")
    damage_per_second = ability:GetSpecialValueFor("damage_per_second")

    if IsServer() then
      damage_type = ability:GetAbilityDamageType()
    end
  end

  if caster and not caster:IsNull() then
    -- Bonus damage talent
    local talent = caster:FindAbilityByName("special_bonus_electrician_static_grip_damage")
    if talent and talent:GetLevel() > 0 then
      damage_per_second = damage_per_second + talent:GetSpecialValueFor("value")
    end
  end

  if IsServer() then
    -- play sound
    parent:EmitSound("Hero_StormSpirit.ElectricVortex")
  end

  self.damagePerInterval = damage_per_second * damageInterval
  self.damageType = damage_type
end

if IsServer() then
  function modifier_electrician_static_grip:OnDestroy()
    local caster = self:GetCaster()
    local parent = self:GetParent()

    -- clean up the particle
    if self.part then
      ParticleManager:DestroyParticle( self.part, false )
      ParticleManager:ReleaseParticleIndex( self.part )
    end

    -- end the sound prematurely
    parent:StopSound( "Hero_StormSpirit.ElectricVortex" )

    -- remove modifiers on the caster
    caster:RemoveModifierByName("modifier_electrician_static_grip_movement")
    caster:RemoveModifierByName("modifier_electrician_static_grip_debuff_tracker")
  end

  function modifier_electrician_static_grip:OnIntervalThink()
    local parent = self:GetParent()
    local caster = self:GetCaster()
    local ability = self:GetAbility()

    if parent:IsMagicImmune() or parent:IsInvulnerable() then
      self:StartIntervalThink(-1)
      self:Destroy()
      return
    end

    ApplyDamage( {
      victim = parent,
      attacker = caster,
      damage = self.damagePerInterval,
      damage_type = self.damageType,
      damage_flags = DOTA_DAMAGE_FLAG_NONE,
      ability = ability,
    } )
  end
end

---------------------------------------------------------------------------------------------------

modifier_electrician_static_grip_movement = class({})

function modifier_electrician_static_grip_movement:IsDebuff()
  return false
end

function modifier_electrician_static_grip_movement:IsHidden()
  return true
end

function modifier_electrician_static_grip_movement:IsPurgable()
  return false
end

function modifier_electrician_static_grip_movement:GetPriority()
  return DOTA_MOTION_CONTROLLER_PRIORITY_MEDIUM
end

function modifier_electrician_static_grip_movement:CheckState()
  return {
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
  }
end

if IsServer() then
  function modifier_electrician_static_grip_movement:OnCreated(event)
    local ability = self:GetAbility()
    self.target = EntIndexToHScript(event.target)
    self.speed = ability:GetSpecialValueFor("pull_speed")
    self.pullBuffer = ability:GetSpecialValueFor("pull_buffer")

    if self:ApplyHorizontalMotionController() == false then
      self:Destroy()
    end
  end

  function modifier_electrician_static_grip_movement:OnDestroy()
    local parent = self:GetParent()

    parent:RemoveHorizontalMotionController(self)
    ResolveNPCPositions(parent:GetAbsOrigin(), 128)
  end

  function modifier_electrician_static_grip_movement:UpdateHorizontalMotion(parent, deltaTime)
    -- we're aiming to drag the caster towards a point on the map
    -- which is an offset of the target's location pullBuffer distance away
    -- thus, first we need to get the vector from the target to the caster
    local parentOrigin = parent:GetAbsOrigin()
    local targetOrigin = self.target:GetAbsOrigin()
    local distance = (targetOrigin - parentOrigin):Length2D()

    -- if we're already at or past the buffer, we don't need to do any of this
    if distance > self.pullBuffer then
      local dA = parentOrigin
      dA.z = 0
      local dB = targetOrigin
      dB.z = 0
      -- then we need to create the actual end location, by Normalizing the vector
      -- from target to caster ( setting its distance to 1 ) and then multiplying it
      -- by pullBuffer so that make it the proper length
      -- then we offset it from the target origin by adding it to it
      local endOrigin = dB + ( ( dA - dB ):Normalized() * self.pullBuffer )
      -- now that we know the end location, set up the vector from the parent origin
      -- to it
      local travelVector = endOrigin - dA
      local direction = travelVector:Normalized()
      local distanceBuffer = travelVector:Length2D()

      local tickSpeed = self.speed * deltaTime
      tickSpeed = math.min(tickSpeed, distanceBuffer)
      local tickOrigin = parentOrigin + ( tickSpeed * direction )

      parent:SetAbsOrigin(tickOrigin)
      parent:FaceTowards(targetOrigin)
    end
  end

  function modifier_electrician_static_grip_movement:OnHorizontalMotionInterrupted()
    self:Destroy()
  end
end

---------------------------------------------------------------------------------------------------

modifier_electrician_static_grip_debuff_tracker = class({})

function modifier_electrician_static_grip_debuff_tracker:IsHidden()
  return true
end

function modifier_electrician_static_grip_debuff_tracker:IsDebuff()
  return false
end

function modifier_electrician_static_grip_debuff_tracker:IsPurgable()
  return false
end

function modifier_electrician_static_grip_debuff_tracker:OnCreated()
  if not IsServer() then
    return
  end
  -- start thinking
  self:StartIntervalThink(0)
end

function modifier_electrician_static_grip_debuff_tracker:OnIntervalThink()
  if not IsServer() then
    return
  end

  local ability = self:GetAbility()
  if not ability or ability:IsNull() then
    self:StartIntervalThink(-1)
    self:Destroy()
    return
  end

  local modifier = ability.modGrip
  if not modifier or modifier:IsNull() then
    self:StartIntervalThink(-1)
    self:Destroy()
    return
  end

  local parent = self:GetParent()
  if parent:IsSilenced() or parent:IsStunned() or parent:IsHexed() then
    modifier:Destroy()
    self:StartIntervalThink(-1)
    self:Destroy()
  end
end

function modifier_electrician_static_grip_debuff_tracker:CheckState()
  return {
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
  }
end
