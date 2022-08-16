LinkLuaModifier("modifier_item_enrage_crystal", "items/enrage_crystal.lua", LUA_MODIFIER_MOTION_NONE)

item_enrage_crystal = class({})

function item_enrage_crystal:GetIntrinsicModifierName()
  return "modifier_item_enrage_crystal"
end

function item_enrage_crystal:OnSpellStart()
  local caster = self:GetCaster()

  -- Strong Dispel
  caster:Purge(false, true, false, true, true)
  
  -- Sound
  caster:EmitSound("Hero_Abaddon.AphoticShield.Destroy")

  -- Particle
  local particle = ParticleManager:CreateParticle("particles/items/enrage_crystal/enrage_crystal_explosion.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
  ParticleManager:ReleaseParticleIndex(particle)
end

function item_enrage_crystal:ProcsMagicStick()
  return false
end

---------------------------------------------------------------------------------------------------

modifier_item_enrage_crystal = class({})

function modifier_item_enrage_crystal:IsHidden()
  return true
end

function modifier_item_enrage_crystal:IsDebuff()
  return false
end

function modifier_item_enrage_crystal:IsPurgable()
  return false
end

function modifier_item_enrage_crystal:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_enrage_crystal:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.bonus_str = ability:GetSpecialValueFor("bonus_strength")
    self.bonus_damage = ability:GetSpecialValueFor("bonus_damage")
    self.bonus_status_resist = ability:GetSpecialValueFor("bonus_status_resist")
    self.hp_regen_amp = ability:GetSpecialValueFor("hp_regen_amp")
    self.lifesteal_amp = ability:GetSpecialValueFor("lifesteal_amp")
  end
end

modifier_item_enrage_crystal.OnRefresh = modifier_item_enrage_crystal.OnCreated

function modifier_item_enrage_crystal:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
    MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
  }
end

function modifier_item_enrage_crystal:GetModifierBonusStats_Strength()
  return self.bonus_str or self:GetAbility():GetSpecialValueFor("bonus_strength")
end

function modifier_item_enrage_crystal:GetModifierPreAttack_BonusDamage()
  return self.bonus_damage or self:GetAbility():GetSpecialValueFor("bonus_damage")
end

function modifier_item_enrage_crystal:GetModifierStatusResistanceStacking()
  local parent = self:GetParent()
  if not parent:HasModifier("modifier_item_sange") and not parent:HasModifier("modifier_item_sange_and_yasha") and not parent:HasModifier("modifier_item_kaya_and_sange") and not parent:HasModifier("modifier_item_heavens_halberd") and self:IsFirstItemInInventory() then
    return self.bonus_status_resist or self:GetAbility():GetSpecialValueFor("bonus_status_resist")
  end
  return 0 
end

function modifier_item_enrage_crystal:GetModifierHPRegenAmplify_Percentage()
  if not parent:HasModifier("modifier_item_sange") and not parent:HasModifier("modifier_item_sange_and_yasha") and not parent:HasModifier("modifier_item_kaya_and_sange") and not parent:HasModifier("modifier_item_heavens_halberd") and self:IsFirstItemInInventory() then
    return self.hp_regen_amp or self:GetAbility():GetSpecialValueFor("hp_regen_amp")
  end
  return 0 
end

function modifier_item_enrage_crystal:GetModifierLifestealRegenAmplify_Percentage()
  if not parent:HasModifier("modifier_item_sange") and not parent:HasModifier("modifier_item_sange_and_yasha") and not parent:HasModifier("modifier_item_kaya_and_sange") and not parent:HasModifier("modifier_item_heavens_halberd") and self:IsFirstItemInInventory() then
    return self.lifesteal_amp or self:GetAbility():GetSpecialValueFor("lifesteal_amp")
  end
  return 0 
end

function modifier_item_enrage_crystal:IsFirstItemInInventory()
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
