LinkLuaModifier("modifier_item_custom_heart_passive", "items/heart.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_custom_heart_active", "items/heart.lua", LUA_MODIFIER_MOTION_NONE)

item_custom_heart = class({})

function item_custom_heart:GetIntrinsicModifierName()
  return "modifier_item_custom_heart_passive"
end

function item_custom_heart:OnSpellStart()
  local caster = self:GetCaster()
  local buff_duration = self:GetSpecialValueFor("buff_duration")

  -- Apply a Heart special buff to the caster
  caster:AddNewModifier(caster, self, "modifier_item_custom_heart_active", {duration = buff_duration})

  -- Find enemies
  local center = caster:GetAbsOrigin()
  local radius = self:GetSpecialValueFor("radius")
  local enemies = FindUnitsInRadius(
    caster:GetTeamNumber(),
    center,
    nil,
    radius,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER,
    false
  )

  -- Havoc Particle
  local particle = ParticleManager:CreateParticle("particles/items5_fx/havoc_hammer.vpcf", PATTACH_ABSORIGIN, caster)
  ParticleManager:SetParticleControl(particle, 1, Vector(radius, radius, radius))
  ParticleManager:ReleaseParticleIndex(particle)

  -- Havoc Sound
  caster:EmitSound("DOTA_Item.HavocHammer.Cast")

  -- Havoc Knockback
  local knockback_table = {
    should_stun = 0,
    center_x = center.x,
    center_y = center.y,
    center_z = center.z,
    duration = self:GetSpecialValueFor("knockback_duration"),
    knockback_duration = self:GetSpecialValueFor("knockback_duration"),
    knockback_distance = self:GetSpecialValueFor("knockback_distance"),
  }

  -- Knockback enemies
  for _, enemy in pairs(enemies) do
    if enemy and not enemy:IsNull() then
      --knockback_table.knockback_distance = radius - (center - enemy:GetAbsOrigin()):Length2D()
      enemy:AddNewModifier(caster, self, "modifier_knockback", knockback_table)
    end
  end

  -- Havoc Damage
  local havoc_damage = self:GetSpecialValueFor("nuke_base_dmg")
  if caster:IsHero() then
    havoc_damage = self:GetSpecialValueFor("nuke_base_dmg") + caster:GetStrength() * self:GetSpecialValueFor("nuke_str_dmg")
  end

  local damage_table = {
    attacker = caster,
    damage = havoc_damage,
    damage_type = DAMAGE_TYPE_MAGICAL,
    damage_flags = DOTA_DAMAGE_FLAG_NONE,
    ability = self,
  }

  -- Damage enemies
  for _, enemy in pairs(enemies) do
    if enemy and not enemy:IsNull() then
      damage_table.victim = enemy
      ApplyDamage(damage_table)
    end
  end
end

function item_custom_heart:ProcsMagicStick()
  return false
end

---------------------------------------------------------------------------------------------------

modifier_item_custom_heart_passive = class({})

function modifier_item_custom_heart_passive:IsHidden()
  return true
end

function modifier_item_custom_heart_passive:IsDebuff()
  return false
end

function modifier_item_custom_heart_passive:IsPurgable()
  return false
end

function modifier_item_custom_heart_passive:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_custom_heart_passive:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.str = ability:GetSpecialValueFor("bonus_strength")
    self.hp = ability:GetSpecialValueFor("bonus_health")
    self.regen = ability:GetSpecialValueFor("health_regen_pct")
  end
end

modifier_item_custom_heart_passive.OnRefresh = modifier_item_custom_heart_passive.OnCreated

function modifier_item_custom_heart_passive:IsFirstItemInInventory()
  local parent = self:GetParent()
  local ability = self:GetAbility()
  
  if not IsServer() then
    return true
  end

  local same_items = {}
  for item_slot = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6 do
    local item = parent:GetItemInSlot(item_slot)
    if item then
      if item:GetAbilityName() == ability:GetAbilityName() then
        table.insert(same_items, item)
      end
    end
  end

  if #same_items <= 1 then
    return true
  end

  if same_items[1] == ability then
    return true
  end

  return false
end

function modifier_item_custom_heart_passive:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    MODIFIER_PROPERTY_HEALTH_BONUS,
    MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE,
  }
end

function modifier_item_custom_heart_passive:GetModifierBonusStats_Strength()
  return self.str or self:GetAbility():GetSpecialValueFor("bonus_strength")
end

function modifier_item_custom_heart_passive:GetModifierHealthBonus()
  return self.hp or self:GetAbility():GetSpecialValueFor("bonus_health")
end

function modifier_item_custom_heart_passive:GetModifierHealthRegenPercentage()
  if self:IsFirstItemInInventory() then
    return self.regen or self:GetAbility():GetSpecialValueFor("health_regen_pct")
  end
end

---------------------------------------------------------------------------------------------------

modifier_item_custom_heart_active = class({})

function modifier_item_custom_heart_active:IsHidden() -- needs tooltip
  return false
end

function modifier_item_custom_heart_active:IsDebuff()
  return false
end

function modifier_item_custom_heart_active:IsPurgable()
  return false
end

function modifier_item_custom_heart_active:AllowIllusionDuplicate()
  return true
end

function modifier_item_custom_heart_active:OnCreated()
  local parent = self:GetParent()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.str = ability:GetSpecialValueFor("buff_bonus_strength")
    self.bonus_damage = ability:GetSpecialValueFor("buff_bonus_base_damage")
  end

  if IsServer() and parent:IsHero() then
    parent:CalculateStatBonus(true)
  end
end

modifier_item_custom_heart_active.OnRefresh = modifier_item_custom_heart_active.OnCreated

function modifier_item_custom_heart_active:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    MODIFIER_PROPERTY_BASEATTACK_BONUSDAMAGE,
  }
end

function modifier_item_custom_heart_active:GetModifierBonusStats_Strength()
  return self.str
end

function modifier_item_custom_heart_active:GetModifierBaseAttack_BonusDamage()
  return self.bonus_damage
end

function modifier_item_custom_heart_active:GetEffectName()
  return "particles/econ/courier/courier_greevil_red/courier_greevil_red_ambient_3.vpcf"
end

function modifier_item_custom_heart_active:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_item_custom_heart_active:GetTexture()
  return "item_heart"
end