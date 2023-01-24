LinkLuaModifier("modifier_item_splash_cannon_passive", "items/splash_cannon.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_splash_cannon_thinker", "items/splash_cannon.lua", LUA_MODIFIER_MOTION_NONE)

item_splash_cannon = class({})

function item_splash_cannon:GetAOERadius()
  return self:GetSpecialValueFor("active_radius")
end

function item_splash_cannon:GetIntrinsicModifierName()
  return "modifier_item_splash_cannon_passive"
end

function item_splash_cannon:OnSpellStart()
  local caster = self:GetCaster()
  local target = self:GetCursorPosition()

  if not target then
    return
  end

  -- 'Fix' for the caster not turning to cast this item at the location
  -- Items are weird because they are not supposed to have cast points or to require facing
  -- See Gleipnir in vanilla for reference
  caster:FaceTowards(target)

  -- KVs
  local projectile_speed = self:GetSpecialValueFor("projectile_speed")
  local projectile_vision_radius = self:GetSpecialValueFor("knockback_distance")
  local recoil_distance = self:GetSpecialValueFor("recoil_distance")
  local recoil_duration = self:GetSpecialValueFor("recoil_duration")

  -- Other variables
  local caster_team = caster:GetTeamNumber()
  local caster_loc = caster:GetAbsOrigin()

  -- Calculate projectile stuff
  local distance = (caster_loc - target):Length2D()
  local projectile_duration = distance / projectile_speed + 0.1

  -- Create a dummy for the tracking projectile
  local dummy = CreateModifierThinker(caster, self, "modifier_item_splash_cannon_thinker", {duration = projectile_duration}, target, caster_team, false)

  -- Tracking projectile info
  local projectile = {
    EffectName = "particles/base_attacks/ranged_tower_bad.vpcf",
    Ability = self,
    Source = caster,
    vSourceLoc = caster_loc,
    Target = dummy,
    iMoveSpeed = projectile_speed,
    bDodgeable = false,
    bVisibleToEnemies = true,
    bProvidesVision = true,
    iVisionRadius = projectile_vision_radius,
    iVisionTeamNumber = caster_team,
    iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1,
  }
  -- Create a tracking projectile
  ProjectileManager:CreateTrackingProjectile(projectile)

  -- Sound
  caster:EmitSound("Splash_Cannon.Launch")

  -- Initialize knockback table for recoil
  local knockback_table = {
    should_stun = 0,
    center_x = target.x,
    center_y = target.y,
    center_z = target.z,
    duration = recoil_duration,
    knockback_duration = recoil_duration,
    knockback_distance = recoil_distance,
    --knockback_height = recoil_distance / 2,
  }

  -- Apply Recoil to the caster
  caster:AddNewModifier(caster, self, "modifier_knockback", knockback_table)
end

function item_splash_cannon:OnProjectileHit(target, location)
  if not target or not location then
    return
  end

  local caster = self:GetCaster()
  local origin = target:GetAbsOrigin()

  -- Ability constants
  local targetTeam = self:GetAbilityTargetTeam()
  local targetType = self:GetAbilityTargetType()
  local targetFlags = self:GetAbilityTargetFlags()
  local damageType = self:GetAbilityDamageType()

  -- KVs
  local radius = self:GetSpecialValueFor("active_radius")
  local attack_damage_percent = self:GetSpecialValueFor("active_splash_percent")
  local bonus_damage = self:GetSpecialValueFor("active_damage")
  local distance = self:GetSpecialValueFor("knockback_distance")
  local duration = self:GetSpecialValueFor("knockback_duration")

  -- Initialize knockback table
  local knockback_table = {
    should_stun = 0,
    center_x = origin.x,
    center_y = origin.y,
    center_z = origin.z,
    duration = duration,
    knockback_duration = duration,
    knockback_distance = distance,
    knockback_height = distance / 2,
  }

  -- Initialize damage table
  local damage_table = {
    attacker = caster,
    damage_type = damageType or DAMAGE_TYPE_PHYSICAL,
    damage_flags = bit.bor(DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL, DOTA_DAMAGE_FLAG_BYPASSES_BLOCK),
    ability = self,
  }

  local splash_damage = caster:GetAverageTrueAttackDamage(nil) * attack_damage_percent * 0.01
  if caster:IsRangedAttacker() then
    damage_table.damage = bonus_damage + splash_damage
  else
    -- Melee casters don't apply splash
    damage_table.damage = bonus_damage
  end

  -- find units around the target location
  local units = FindUnitsInRadius(
    caster:GetTeamNumber(),
    origin,
    nil,
    radius,
    targetTeam,
    targetType,
    targetFlags,
    FIND_ANY_ORDER,
    false
  )

  -- Particles
  local part = ParticleManager:CreateParticle("particles/econ/items/clockwerk/clockwerk_paraflare/clockwerk_para_rocket_flare_explosion.vpcf", PATTACH_CUSTOMORIGIN, caster)
  ParticleManager:SetParticleControl(part, 3, origin)
  ParticleManager:ReleaseParticleIndex(part)
  local explosion = ParticleManager:CreateParticle("particles/units/heroes/hero_batrider/batrider_flamebreak_explosion.vpcf", PATTACH_WORLDORIGIN, caster)
  --ParticleManager:SetParticleControl(explosion, 0, origin)
  ParticleManager:SetParticleControl(explosion, 5, origin)
  ParticleManager:ReleaseParticleIndex(explosion)

  -- iterate through all targets
  for _, unit in pairs(units) do
    if unit and not unit:IsNull() then
      if not unit:IsMagicImmune() and not unit:IsAttackImmune() then
        -- Apply knockback
        unit:AddNewModifier(caster, self, "modifier_knockback", knockback_table)
      end

      -- Apply damage
      damage_table.victim = unit
      ApplyDamage(damage_table)
    end
  end

  -- Destroy trees
  GridNav:DestroyTreesAroundPoint(origin, radius, false)

  -- Sound
  EmitSoundOnLocationWithCaster(location, "Splash_Cannon.Explosion", caster)

  return true
end

function item_splash_cannon:ProcsMagicStick()
  return false
end

---------------------------------------------------------------------------------------------------

modifier_item_splash_cannon_passive = class({})

function modifier_item_splash_cannon_passive:IsHidden()
  return true
end

function modifier_item_splash_cannon_passive:IsDebuff()
  return false
end

function modifier_item_splash_cannon_passive:IsPurgable()
  return false
end

function modifier_item_splash_cannon_passive:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_splash_cannon_passive:OnCreated()
  self:OnRefresh()
  if IsServer() then
    self:StartIntervalThink(0.1)
  end
end

function modifier_item_splash_cannon_passive:OnRefresh()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.bonus_health = ability:GetSpecialValueFor("bonus_health")
    self.bonus_health_regen = ability:GetSpecialValueFor("bonus_health_regen")
    self.bonus_strength = ability:GetSpecialValueFor("bonus_strength")
    self.bonus_agility = ability:GetSpecialValueFor("bonus_agility")
    self.bonus_intellect = ability:GetSpecialValueFor("bonus_intellect")
    self.bonus_damage = ability:GetSpecialValueFor("bonus_damage")
    self.attack_range = ability:GetSpecialValueFor("bonus_attack_range")
  end

  if IsServer() then
    self:OnIntervalThink()
  end
end

function modifier_item_splash_cannon_passive:OnIntervalThink()
  if self:IsFirstItemInInventory() then
    self:SetStackCount(2)
  else
    self:SetStackCount(1)
  end
end

function modifier_item_splash_cannon_passive:IsFirstItemInInventory()
  local parent = self:GetParent()
  local ability = self:GetAbility()

  if parent:IsNull() or ability:IsNull() then
    return false
  end

  if not IsServer() then
    return
  end

  return parent:FindAllModifiersByName(self:GetName())[1] == self
end

function modifier_item_splash_cannon_passive:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_HEALTH_BONUS,
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
    MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
    MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
end

function modifier_item_splash_cannon_passive:GetModifierHealthBonus()
  return self.bonus_health or self:GetAbility():GetSpecialValueFor("bonus_health")
end

function modifier_item_splash_cannon_passive:GetModifierConstantHealthRegen()
  return self.bonus_health_regen or self:GetAbility():GetSpecialValueFor("bonus_health_regen")
end

function modifier_item_splash_cannon_passive:GetModifierBonusStats_Strength()
  return self.bonus_strength or self:GetAbility():GetSpecialValueFor("bonus_strength")
end

function modifier_item_splash_cannon_passive:GetModifierBonusStats_Agility()
  return self.bonus_agility or self:GetAbility():GetSpecialValueFor("bonus_agility")
end

function modifier_item_splash_cannon_passive:GetModifierBonusStats_Intellect()
  return self.bonus_intellect or self:GetAbility():GetSpecialValueFor("bonus_intellect")
end

function modifier_item_splash_cannon_passive:GetModifierPreAttack_BonusDamage()
  return self.bonus_damage or self:GetAbility():GetSpecialValueFor("bonus_damage")
end

function modifier_item_splash_cannon_passive:GetModifierAttackRangeBonus()
  local parent = self:GetParent()
  if not parent:IsRangedAttacker() or self:GetStackCount() ~= 2 then
    return 0
  end

  -- Prevent stacking with Dragon Lance and Hurricane Pike
  if parent:HasModifier("modifier_item_dragon_lance") or parent:HasModifier("modifier_item_hurricane_pike") then
    return 0
  end

  return self.attack_range or self:GetAbility():GetSpecialValueFor("bonus_attack_range")
end

if IsServer() then
  function modifier_item_splash_cannon_passive:OnAttackLanded(event)
    local parent = self:GetParent()
    local attacker = event.attacker
    local target = event.target

    -- Prevent the code below from executing multiple times for no reason
    if not self:IsFirstItemInInventory() then
      return
    end

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return
    end

    -- Check if attacker has this modifier
    if attacker ~= parent then
      return
    end

    -- Splash doesn't work on illusions and melee units
    if parent:IsIllusion() or not parent:IsRangedAttacker() then
      return
    end

    -- Check if attacked unit exists
    if not target or target:IsNull() then
      return
    end

    -- Check if attacked entity is an item, rune or something weird
    if target.GetUnitName == nil then
      return
    end

    -- Don't affect buildings, wards and invulnerable units.
    if target:IsTower() or target:IsBarracks() or target:IsBuilding() or target:IsOther() or target:IsInvulnerable() then
      return
    end

    local ability = self:GetAbility()
    if not ability or ability:IsNull() then
      return
    end

    local origin = target:GetAbsOrigin()

    -- set the targeting requirements for the actual targets
    local targetTeam = ability:GetAbilityTargetTeam()
    local targetType = ability:GetAbilityTargetType()
    local targetFlags = ability:GetAbilityTargetFlags()

    -- Splash parameters
    local splash_radius = ability:GetSpecialValueFor("passive_splash_radius")
    local splash_percent = ability:GetSpecialValueFor("passive_splash_percent")

    -- find all appropriate targets around the initial target
    local units = FindUnitsInRadius(
      parent:GetTeamNumber(),
      origin,
      nil,
      splash_radius,
      targetTeam,
      targetType,
      targetFlags,
      FIND_ANY_ORDER,
      false
    )

    -- get the wearer's damage
    local damage = event.original_damage

    -- get the damage modifier
    local actual_damage = damage * splash_percent * 0.01

    -- Damage table
    local damage_table = {}
    damage_table.attacker = parent
    damage_table.damage_type = ability:GetAbilityDamageType() or DAMAGE_TYPE_PHYSICAL
    damage_table.ability = ability
    damage_table.damage = actual_damage
    damage_table.damage_flags = bit.bor(DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL)

    -- Show particle only if damage is above zero and only if there are units nearby
    if actual_damage > 0 and #units > 1 then
      local part = ParticleManager:CreateParticle("particles/econ/items/clockwerk/clockwerk_paraflare/clockwerk_para_rocket_flare_explosion.vpcf", PATTACH_CUSTOMORIGIN, parent)
      ParticleManager:SetParticleControl(part, 3, origin)
      ParticleManager:ReleaseParticleIndex(part)
    end

    -- iterate through all targets
    for _, unit in pairs(units) do
      if unit and not unit:IsNull() and not unit:IsCustomWardTypeUnit() and unit ~= target then
        damage_table.victim = unit
        ApplyDamage(damage_table)
      end
    end

    -- sound
    target:EmitSound("dota_fountain.ProjectileImpact")
  end
end

---------------------------------------------------------------------------------------------------

modifier_item_splash_cannon_thinker = class({})

function modifier_item_splash_cannon_thinker:IsHidden()
  return true
end

function modifier_item_splash_cannon_thinker:IsDebuff()
  return false
end

function modifier_item_splash_cannon_thinker:IsPurgable()
  return false
end

function modifier_item_splash_cannon_thinker:OnCreated()

end

function modifier_item_splash_cannon_thinker:OnDestroy()
  if not IsServer() then
    return
  end
  local parent = self:GetParent()
  if parent and not parent:IsNull() then
    parent:ForceKill(false)
  end
end
