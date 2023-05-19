LinkLuaModifier("modifier_item_enrage_crystal", "items/enrage_crystal.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_enrage_crystal_active", "items/enrage_crystal.lua", LUA_MODIFIER_MOTION_NONE)

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

  -- Apply brief debuff immunity
  caster:AddNewModifier(caster, self, "modifier_item_enrage_crystal_active", {duration = self:GetSpecialValueFor("active_duration")})
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
  self:OnRefresh()
  if IsServer() then
    self:StartIntervalThink(0.1)
  end
end

function modifier_item_enrage_crystal:OnRefresh()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.bonus_str = ability:GetSpecialValueFor("bonus_strength")
    self.bonus_damage = ability:GetSpecialValueFor("bonus_damage")
    self.bonus_status_resist = ability:GetSpecialValueFor("bonus_status_resist")
    self.hp_regen_amp = ability:GetSpecialValueFor("hp_regen_amp")
    self.lifesteal_amp = ability:GetSpecialValueFor("lifesteal_amp")
    self.dmg_reduction = ability:GetSpecialValueFor("dmg_reduction_while_stunned")
  end

  if IsServer() then
    self:OnIntervalThink()
  end
end

function modifier_item_enrage_crystal:OnIntervalThink()
  if self:IsFirstItemInInventory() then
    self:SetStackCount(2)
  else
    self:SetStackCount(1)
  end
end

function modifier_item_enrage_crystal:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
    MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
    MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
    MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE,
    MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK,
  }
end

function modifier_item_enrage_crystal:GetModifierBonusStats_Strength()
  return self.bonus_str or self:GetAbility():GetSpecialValueFor("bonus_strength")
end

function modifier_item_enrage_crystal:GetModifierPreAttack_BonusDamage()
  return self.bonus_damage or self:GetAbility():GetSpecialValueFor("bonus_damage")
end

function modifier_item_enrage_crystal:GetModifierStatusResistanceStacking()
  if self:GetStackCount() ~= 2 then
    return 0
  end
  local parent = self:GetParent()
  if not parent:HasModifier("modifier_item_sange") and not parent:HasModifier("modifier_item_sange_and_yasha") and not parent:HasModifier("modifier_item_kaya_and_sange") and not parent:HasModifier("modifier_item_heavens_halberd") then
    return self.bonus_status_resist or self:GetAbility():GetSpecialValueFor("bonus_status_resist")
  end
  return 0
end

function modifier_item_enrage_crystal:GetModifierHPRegenAmplify_Percentage()
  if self:GetStackCount() ~= 2 then
    return 0
  end
  local parent = self:GetParent()
  if not parent:HasModifier("modifier_item_sange") and not parent:HasModifier("modifier_item_sange_and_yasha") and not parent:HasModifier("modifier_item_kaya_and_sange") and not parent:HasModifier("modifier_item_heavens_halberd") then
    return self.hp_regen_amp or self:GetAbility():GetSpecialValueFor("hp_regen_amp")
  end
  return 0
end

function modifier_item_enrage_crystal:GetModifierLifestealRegenAmplify_Percentage()
  if self:GetStackCount() ~= 2 then
    return 0
  end
  local parent = self:GetParent()
  if not parent:HasModifier("modifier_item_sange") and not parent:HasModifier("modifier_item_sange_and_yasha") and not parent:HasModifier("modifier_item_kaya_and_sange") and not parent:HasModifier("modifier_item_heavens_halberd") then
    return self.lifesteal_amp or self:GetAbility():GetSpecialValueFor("lifesteal_amp")
  end
  return 0
end

if IsServer() then
  function modifier_item_enrage_crystal:GetModifierTotal_ConstantBlock(event)
    if self:GetStackCount() ~= 2 then
      return 0
    end

    local parent = self:GetParent()
    local damage = event.damage

    local block_amount = damage * self.dmg_reduction / 100

    if block_amount > 0 and (parent:IsStunned() or parent:IsHexed() or parent:IsOutOfGame()) then
      -- Visual effect
      local alert_type = OVERHEAD_ALERT_MAGICAL_BLOCK
      if event.damage_type == DAMAGE_TYPE_PHYSICAL then
        alert_type = OVERHEAD_ALERT_BLOCK
      end

      SendOverheadEventMessage(nil, alert_type, parent, block_amount, nil)

      return block_amount
    end

    return 0
  end
end

function modifier_item_enrage_crystal:IsFirstItemInInventory()
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

---------------------------------------------------------------------------------------------------

modifier_item_enrage_crystal_active = class({})

function modifier_item_enrage_crystal_active:IsHidden()
  return false
end

function modifier_item_enrage_crystal_active:IsDebuff()
  return false
end

function modifier_item_enrage_crystal_active:IsPurgable()
  return false
end

function modifier_item_enrage_crystal_active:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
  }
end

function modifier_item_enrage_crystal_active:GetModifierStatusResistanceStacking()
  return 99
end

function modifier_item_enrage_crystal_active:CheckState()
  return {
    [MODIFIER_STATE_DEBUFF_IMMUNE] = true,
  }
end

function modifier_item_enrage_crystal_active:GetEffectName()
  return "particles/items_fx/black_king_bar_avatar.vpcf"
end
