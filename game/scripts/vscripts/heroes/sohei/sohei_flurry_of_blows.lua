﻿sohei_flurry_of_blows = class({})

LinkLuaModifier("modifier_sohei_flurry_self", "heroes/sohei/sohei_flurry_of_blows.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_sohei_flurry_of_blows_damage", "heroes/sohei/sohei_flurry_of_blows.lua", LUA_MODIFIER_MOTION_NONE)

function sohei_flurry_of_blows:OnSpellStart()
  local caster = self:GetCaster()
  local target_loc = self:GetCursorPosition()
  local radius = self:GetSpecialValueFor("flurry_radius")
  local max_attacks = self:GetSpecialValueFor("max_attacks")
  local max_duration = self:GetSpecialValueFor("max_duration")
  local attack_interval = self:GetSpecialValueFor("attack_interval")

  -- Bonus AoE talent
  local talent = caster:FindAbilityByName("special_bonus_sohei_fob_radius")
  if talent and talent:GetLevel() > 0 then
    radius = radius + talent:GetSpecialValueFor("value")
  end

  -- Talent that increases max number of attacks and max duration
  -- local talent2 = caster:FindAbilityByName("special_bonus_unique_sohei_8")
  -- if talent2 and talent2:GetLevel() > 0 then
    -- max_attacks = max_attacks + talent2:GetSpecialValueFor("value")
    -- max_duration = max_duration + talent2:GetSpecialValueFor("value2")
  -- end

  -- Emit sound
  caster:EmitSound("Hero_EmberSpirit.FireRemnant.Cast")

  -- Remove the particle of the previous instance if it still exists
  if caster.flurry_ground_pfx then
    ParticleManager:DestroyParticle(caster.flurry_ground_pfx, false)
    ParticleManager:ReleaseParticleIndex(caster.flurry_ground_pfx)
  end

  -- Default particle
  caster.flurry_ground_pfx = ParticleManager:CreateParticle("particles/hero/sohei/flurry_of_blows_ground.vpcf", PATTACH_CUSTOMORIGIN, nil)
  ParticleManager:SetParticleControl(caster.flurry_ground_pfx, 0, target_loc)
  ParticleManager:SetParticleControl(caster.flurry_ground_pfx, 10, Vector(radius+10, 0, 0))

  -- Disjoint projectiles
  ProjectileManager:ProjectileDodge(caster)

  -- Put caster in the middle of the circle little above ground
  caster:SetAbsOrigin(target_loc + Vector(0, 0, 200))

  -- Add a modifier that does actual spell effect
  caster:AddNewModifier(caster, self, "modifier_sohei_flurry_self", {
    duration = max_duration,
    radius = radius,
    attack_interval = attack_interval,
    max_attacks = max_attacks,
  })
end

function sohei_flurry_of_blows:GetAOERadius()
  local caster = self:GetCaster()
  local radius = self:GetSpecialValueFor("flurry_radius")

  -- Bonus AoE talent
  local talent = caster:FindAbilityByName("special_bonus_sohei_fob_radius")
  if talent and talent:GetLevel() > 0 then
    radius = radius + talent:GetSpecialValueFor("value")
  end

  return radius
end

---------------------------------------------------------------------------------------------------
-- Flurry of Blows' self buff
modifier_sohei_flurry_self = class({})

function modifier_sohei_flurry_self:IsHidden()
  return false
end

function modifier_sohei_flurry_self:IsDebuff()
  return false
end

function modifier_sohei_flurry_self:IsPurgable()
  return false
end

-- function modifier_sohei_flurry_self:StatusEffectPriority()
  -- return 20
-- end

-- function modifier_sohei_flurry_self:GetStatusEffectName()
  -- return "particles/status_fx/status_effect_omnislash.vpcf"
-- end

function modifier_sohei_flurry_self:CheckState()
  return {
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    [MODIFIER_STATE_INVULNERABLE] = true,
    [MODIFIER_STATE_NO_HEALTH_BAR] = true,
    [MODIFIER_STATE_MAGIC_IMMUNE] = true,
    [MODIFIER_STATE_DISARMED] = true,
    [MODIFIER_STATE_ROOTED] = true,
    [MODIFIER_STATE_FORCED_FLYING_VISION] = true,
  }
end

function modifier_sohei_flurry_self:OnCreated(event)
  if not IsServer() then
    return
  end
  local parent = self:GetParent()

  -- Data sent with AddNewModifier (not available on the client)
  self.radius = event.radius
  self.remaining_attacks = event.max_attacks
  self.attack_interval = event.attack_interval

  self.center = GetGroundPosition(parent:GetAbsOrigin(), parent)

  self:StartIntervalThink(self.attack_interval)
end

function modifier_sohei_flurry_self:OnIntervalThink()
  if not IsServer() then
    return
  end

  if self.remaining_attacks <= 0 then
    self:StartIntervalThink(-1)
    self:Destroy()
    return
  end

  local caster = self:GetCaster() or self:GetParent()
  local ability = self:GetAbility()

  -- Find enemies in a radius
  local enemies = FindUnitsInRadius(
    caster:GetTeamNumber(),
    self.center,
    nil,
    self.radius,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
    bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE, DOTA_UNIT_TARGET_FLAG_NO_INVIS, DOTA_UNIT_TARGET_FLAG_NOT_ATTACK_IMMUNE),
    FIND_ANY_ORDER,
    false
  )

  -- Check if its a stolen spell (by Rubick) so we use actual projectile
  local bUseProjectile = false
  if ability and ability:IsStolen() then
    bUseProjectile = true
  end

  -- Find a random unit to attack
  local unit_to_attack
  for _, enemy in pairs(enemies) do
    if enemy and not enemy:IsNull() then
      unit_to_attack = enemy
      break
    end
  end

  -- Change attacker's position and facing and attack the unit
  if unit_to_attack and not unit_to_attack:IsNull() then
    local unit_origin = unit_to_attack:GetAbsOrigin()
    --local unit_facing = unit_to_attack:GetForwardVector()
    local new_origin = unit_origin + RandomVector(1) * 150

    caster:SetAbsOrigin(new_origin)
    caster:FaceTowards(unit_origin)

    -- Animations
    --ACT_DOTA_CHANNEL_ABILITY_4 -- spinning
    --ACT_DOTA_OVERRIDE_ABILITY_4 -- omnislash
    caster:RemoveGesture(ACT_DOTA_CHANNEL_ABILITY_4)
    caster:StartGesture(ACT_DOTA_OVERRIDE_ABILITY_4)

    -- Add a bonus damage buff before the instant attack
    local buff = caster:AddNewModifier(caster, ability, "modifier_sohei_flurry_of_blows_damage", {})

    -- Instant attack
    caster:PerformAttack(unit_to_attack, true, true, true, false, bUseProjectile, false, true)

    -- Remove bonus damage buff when the instant attack is over
    buff:Destroy()

    self.remaining_attacks = self.remaining_attacks - 1
  else
    -- Put caster in the middle of the circle little above ground
    caster:SetAbsOrigin(self.center + Vector(0, 0, 200))

    -- Animations
    caster:RemoveGesture(ACT_DOTA_OVERRIDE_ABILITY_4)
    caster:StartGestureWithPlaybackRate(ACT_DOTA_CHANNEL_ABILITY_4, 1.15)
  end
end

function modifier_sohei_flurry_self:OnDestroy()
  if IsServer() then
    local caster = self:GetCaster()

    -- Unstuck the caster at the center
    FindClearSpaceForUnit(caster, self.center, false)

    -- Animations
    caster:RemoveGesture(ACT_DOTA_OVERRIDE_ABILITY_4)
    caster:RemoveGesture(ACT_DOTA_CHANNEL_ABILITY_4)

    if caster.flurry_ground_pfx then
      ParticleManager:DestroyParticle(caster.flurry_ground_pfx, false)
      ParticleManager:ReleaseParticleIndex(caster.flurry_ground_pfx)
      caster.flurry_ground_pfx = nil
    end
  end
end

---------------------------------------------------------------------------------------------------

modifier_sohei_flurry_of_blows_damage = class({})

function modifier_sohei_flurry_of_blows_damage:IsHidden()
  return true
end

function modifier_sohei_flurry_of_blows_damage:IsDebuff()
  return false
end

function modifier_sohei_flurry_of_blows_damage:IsPurgable()
  return false
end

function modifier_sohei_flurry_of_blows_damage:RemoveOnDeath()
  return true
end

function modifier_sohei_flurry_of_blows_damage:OnCreated(event)
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.bonus_damage = ability:GetSpecialValueFor("bonus_damage")
  end
end

function modifier_sohei_flurry_of_blows_damage:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_MAGICAL,
  }
end

if IsServer() then
  function modifier_sohei_flurry_of_blows_damage:GetModifierProcAttack_BonusDamage_Magical(event)
    local target = event.target

    -- Check if attacked entity exists
    if not target or target:IsNull() then
      return 0
    end

    -- Check if attacked entity is an item, rune or something weird
    if target.GetUnitName == nil then
      return 0
    end

    SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, target, self.bonus_damage, nil)

    return self.bonus_damage
  end
end