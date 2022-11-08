LinkLuaModifier("modifier_item_infused_robe_passives", "items/infused_robe.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_infused_robe_damage_barrier", "items/infused_robe.lua", LUA_MODIFIER_MOTION_NONE)

item_infused_robe = class({})

function item_infused_robe:GetIntrinsicModifierName()
  return "modifier_item_infused_robe_passives"
end

function item_infused_robe:OnSpellStart()
  local caster = self:GetCaster()

  -- Apply barrier buff to the target
  caster:AddNewModifier(caster, self, "modifier_infused_robe_damage_barrier", {
    duration = self:GetSpecialValueFor("barrier_duration"),
    barrierHP = self:GetSpecialValueFor("barrier_block"),
  })
end

---------------------------------------------------------------------------------------------------

modifier_item_infused_robe_passives = class({})

function modifier_item_infused_robe_passives:IsHidden()
  return true
end

function modifier_item_infused_robe_passives:IsDebuff()
  return false
end

function modifier_item_infused_robe_passives:IsPurgable()
  return false
end

function modifier_item_infused_robe_passives:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_infused_robe_passives:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PHYSICAL_CONSTANT_BLOCK,
    MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK,
    MODIFIER_PROPERTY_HEALTH_BONUS,
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
    MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
    MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
  }
end

function modifier_item_infused_robe_passives:GetModifierPhysical_ConstantBlock(event)
  if not IsServer() then
    return
  end

  local parent = self:GetParent()
  local ability = self:GetAbility()

  if not ability or ability:IsNull() then
    return 0
  end

  if parent:HasModifier("modifier_infused_robe_damage_barrier") then
    return 0
  end

  local attacker = event.attacker
  if not attacker or attacker:IsNull() then
    return 0
  end

  if attacker:IsTower() or attacker:IsFountain() then
    return 0
  end

  local chance = ability:GetSpecialValueFor("passive_attack_damage_block_chance")

  if RollPseudoRandomPercentage(chance, ability:GetEntityIndex(), parent) then
    if parent:IsRangedAttacker() then
      return ability:GetSpecialValueFor("passive_attack_damage_block_ranged")
    else
      return ability:GetSpecialValueFor("passive_attack_damage_block_melee")
    end
  end

  return 0
end

function modifier_item_infused_robe_passives:GetModifierTotal_ConstantBlock(event)
  if not IsServer() then
    return
  end

  local parent = self:GetParent()
  local ability = self:GetAbility()

  if not ability or ability:IsNull() then
    return 0
  end

  -- Don't react on attacks
  if event.damage_category == DOTA_DAMAGE_CATEGORY_ATTACK then
    return 0
  end

  -- Don't react to damage with HP removal flag
  if bit.band(event.damage_flags, DOTA_DAMAGE_FLAG_HPLOSS) == DOTA_DAMAGE_FLAG_HPLOSS then
    return 0
  end

  -- Don't react on self damage
  if event.attacker == parent then
    return 0
  end

  if parent:HasModifier("modifier_infused_robe_damage_barrier") then
    return 0
  end

  local chance = ability:GetSpecialValueFor("passive_spell_damage_block_chance")

  if ability:PseudoRandom(chance) then
    -- Don't block more than the actual damage
    local block_amount = math.min(ability:GetSpecialValueFor("passive_spell_damage_block"), event.damage)

    if block_amount > 0 then
      -- Visual effect
      SendOverheadEventMessage(nil, OVERHEAD_ALERT_MAGICAL_BLOCK, parent, block_amount, nil)
    end

    return block_amount
  end

  return 0
end

function modifier_item_infused_robe_passives:GetModifierHealthBonus()
  return self:GetAbility():GetSpecialValueFor("bonus_hp")
end

function modifier_item_infused_robe_passives:GetModifierConstantHealthRegen()
  return self:GetAbility():GetSpecialValueFor("bonus_hp_regen")
end

function modifier_item_infused_robe_passives:GetModifierMagicalResistanceBonus()
  return self:GetAbility():GetSpecialValueFor("bonus_magic_resist")
end

function modifier_item_infused_robe_passives:GetModifierConstantManaRegen()
  return self:GetAbility():GetSpecialValueFor("bonus_mana_regen")
end

---------------------------------------------------------------------------------------------------
-- Anti-damage shell

modifier_infused_robe_damage_barrier = class({})

function modifier_infused_robe_damage_barrier:IsHidden() -- needs tooltip
  return false
end

function modifier_infused_robe_damage_barrier:IsDebuff()
  return false
end

function modifier_infused_robe_damage_barrier:IsPurgable()
  return false
end

function modifier_infused_robe_damage_barrier:OnCreated(event)
  local parent = self:GetParent()

  if IsServer() then
    if event.barrierHP then
      self:SetStackCount(event.barrierHP)
    end

    -- Sound
    parent:EmitSound("Hero_Abaddon.AphoticShield.Cast")
  end
end

function modifier_infused_robe_damage_barrier:OnRefresh(event)
  self:OnCreated(event)
end

function modifier_infused_robe_damage_barrier:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK,
  }
end

function modifier_infused_robe_damage_barrier:GetModifierTotal_ConstantBlock(event)
  if not IsServer() then
    return
  end

  local parent = self:GetParent()
  local block_amount = event.damage
  local barrier_hp = self:GetStackCount()

  -- Don't react to damage with HP removal flag
  if bit.band(event.damage_flags, DOTA_DAMAGE_FLAG_HPLOSS) == DOTA_DAMAGE_FLAG_HPLOSS then
    return 0
  end

  -- Don't react on self damage
  if event.attacker == parent then
    return 0
  end

  -- Don't block more than remaining hp
  block_amount = math.min(block_amount, barrier_hp)

  -- Reduce barrier hp
  self:SetStackCount(barrier_hp - block_amount)

  if block_amount > 0 then
    -- Visual effect
    local alert_type = OVERHEAD_ALERT_MAGICAL_BLOCK
    if event.damage_type == DAMAGE_TYPE_PHYSICAL then
      alert_type = OVERHEAD_ALERT_BLOCK
    end

    SendOverheadEventMessage(nil, alert_type, parent, block_amount, nil)
  end

  -- Remove the barrier if hp is reduced to nothing
  if self:GetStackCount() <= 0 then
    self:Destroy()
  end

  return block_amount
end

function modifier_infused_robe_damage_barrier:GetEffectName()
  return "particles/units/heroes/hero_medusa/medusa_mana_shield_oldbase.vpcf"
end

function modifier_infused_robe_damage_barrier:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end
