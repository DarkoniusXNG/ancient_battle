LinkLuaModifier("modifier_item_custom_butterfly_passive", "items/butterfly.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_custom_butterfly_active", "items/butterfly.lua", LUA_MODIFIER_MOTION_NONE)

item_custom_butterfly = class({})

function item_custom_butterfly:GetIntrinsicModifierName()
  return "modifier_item_custom_butterfly_passive"
end

function item_custom_butterfly:OnSpellStart()
  local caster = self:GetCaster()
  local buff_duration = self:GetSpecialValueFor("buff_duration")

  -- Apply a Butterfly special buff to the caster
  caster:AddNewModifier(caster, self, "modifier_item_custom_butterfly_active", {duration = buff_duration})

  -- Sound
  caster:EmitSound("DOTA_Item.Butterfly")
end

function item_custom_butterfly:ProcsMagicStick()
  return false
end

---------------------------------------------------------------------------------------------------

modifier_item_custom_butterfly_passive = class({})

function modifier_item_custom_butterfly_passive:IsHidden()
  return true
end

function modifier_item_custom_butterfly_passive:IsDebuff()
  return false
end

function modifier_item_custom_butterfly_passive:IsPurgable()
  return false
end

function modifier_item_custom_butterfly_passive:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_custom_butterfly_passive:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.agi = ability:GetSpecialValueFor("bonus_agility")
    self.evasion = ability:GetSpecialValueFor("bonus_evasion")
    self.attack_speed = ability:GetSpecialValueFor("bonus_attack_speed")
    self.dmg = ability:GetSpecialValueFor("bonus_damage")
  end
end

modifier_item_custom_butterfly_passive.OnRefresh = modifier_item_custom_butterfly_passive.OnCreated

function modifier_item_custom_butterfly_passive:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
    MODIFIER_PROPERTY_EVASION_CONSTANT,
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
  }
end

function modifier_item_custom_butterfly_passive:GetModifierBonusStats_Agility()
  return self.agi or self:GetAbility():GetSpecialValueFor("bonus_agility")
end

function modifier_item_custom_butterfly_passive:GetModifierAttackSpeedBonus_Constant()
  return self.attack_speed or self:GetAbility():GetSpecialValueFor("bonus_attack_speed")
end

function modifier_item_custom_butterfly_passive:GetModifierEvasion_Constant()
  return self.evasion or self:GetAbility():GetSpecialValueFor("bonus_evasion")
end

function modifier_item_custom_butterfly_passive:GetModifierPreAttack_BonusDamage()
  return self.dmg or self:GetAbility():GetSpecialValueFor("bonus_damage")
end

---------------------------------------------------------------------------------------------------

modifier_item_custom_butterfly_active = class({})

function modifier_item_custom_butterfly_active:IsHidden()
  return false
end

function modifier_item_custom_butterfly_active:IsDebuff()
  return false
end

function modifier_item_custom_butterfly_active:IsPurgable()
  return false
end

function modifier_item_custom_butterfly_active:OnCreated()
  local parent = self:GetParent()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.move_speed = ability:GetSpecialValueFor("buff_ms_per_agility")
    self.evasion = ability:GetSpecialValueFor("buff_evasion")
  end

  if parent:IsRealHero() then
    self.agi = parent:GetAgility()
  end
end

modifier_item_custom_butterfly_active.OnRefresh = modifier_item_custom_butterfly_active.OnCreated

function modifier_item_custom_butterfly_active:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    MODIFIER_PROPERTY_EVASION_CONSTANT,
  }
end

function modifier_item_custom_butterfly_active:GetModifierMoveSpeedBonus_Percentage()
  local ms_per_agi = self.move_speed or self:GetAbility():GetSpecialValueFor("buff_ms_per_agility")
  if self.agi and ms_per_agi then
    return ms_per_agi * self.agi
  end

  return 0
end

function modifier_item_custom_butterfly_active:GetModifierEvasion_Constant()
  return self.evasion or self:GetAbility():GetSpecialValueFor("buff_evasion")
end

function modifier_item_custom_butterfly_active:GetEffectName()
  return "particles/ui/blessing_icon_unlock_green.vpcf"--"particles/items2_fx/butterfly_buff.vpcf"
end

function modifier_item_custom_butterfly_active:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_item_custom_butterfly_active:GetTexture()
  return "item_butterfly"
end
