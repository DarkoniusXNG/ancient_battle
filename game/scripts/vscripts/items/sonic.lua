item_sonic = class({})

LinkLuaModifier("modifier_item_sonic_passives", "items/sonic.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_sonic_active", "items/sonic.lua", LUA_MODIFIER_MOTION_NONE)

function item_sonic:GetIntrinsicModifierName()
  return "modifier_item_sonic_passives"
end

function item_sonic:OnSpellStart()
  local caster = self:GetCaster()

  -- Apply Sonic buff to caster
  caster:AddNewModifier(caster, self, "modifier_item_sonic_active", {duration = self:GetSpecialValueFor("duration")})

  -- Activation Sound
  caster:EmitSound("Hero_Dark_Seer.Surge")
end

---------------------------------------------------------------------------------------------------

modifier_item_sonic_passives = class({})

function modifier_item_sonic_passives:IsHidden()
  return true
end

function modifier_item_sonic_passives:IsDebuff()
  return false
end

function modifier_item_sonic_passives:IsPurgable()
  return false
end

function modifier_item_sonic_passives:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_sonic_passives:OnCreated()
  self:OnRefresh()
  if IsServer() then
    self:StartIntervalThink(0.1)
  end
end

function modifier_item_sonic_passives:OnRefresh()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.movement_speed = ability:GetSpecialValueFor("bonus_movement_speed")
    self.attack_speed = ability:GetSpecialValueFor("bonus_attack_speed")
    self.agi = ability:GetSpecialValueFor("bonus_agility")
  end

  if IsServer() then
    self:OnIntervalThink()
  end
end

function modifier_item_sonic_passives:OnIntervalThink()
  if self:IsFirstItemInInventory() then
    self:SetStackCount(2)
  else
    self:SetStackCount(1)
  end
end

function modifier_item_sonic_passives:IsFirstItemInInventory()
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

function modifier_item_sonic_passives:DeclareFunctions()
  return {
    --MODIFIER_PROPERTY_MOVESPEED_BONUS_UNIQUE,
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
    MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
  }
end

--function modifier_item_sonic_passives:GetModifierMoveSpeedBonus_Special_Boots()
  --return self.movement_speed
--end

function modifier_item_sonic_passives:GetModifierMoveSpeedBonus_Percentage()
  if self:GetStackCount() ~= 2 then
    return 0
  end
  local parent = self:GetParent()
  if not parent:HasModifier("modifier_item_yasha") and not parent:HasModifier("modifier_item_sange_and_yasha") and not parent:HasModifier("modifier_item_yasha_and_kaya") and not parent:HasModifier("modifier_item_manta") then
    return self.movement_speed
  end
  return 0
end

function modifier_item_sonic_passives:GetModifierAttackSpeedBonus_Constant()
  return self.attack_speed
end

function modifier_item_sonic_passives:GetModifierBonusStats_Agility()
  return self.agi
end
---------------------------------------------------------------------------------------------------

modifier_item_sonic_active = class({})

function modifier_item_sonic_active:IsHidden() -- needs tooltip
  return false
end

function modifier_item_sonic_active:IsDebuff()
  return false
end

function modifier_item_sonic_active:IsPurgable()
  return true
end

function modifier_item_sonic_active:GetPriority()
  return MODIFIER_PRIORITY_SUPER_ULTRA + 10000
end

function modifier_item_sonic_active:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.speed = ability:GetSpecialValueFor("active_speed_bonus")
  end
end

modifier_item_sonic_active.OnRefresh = modifier_item_sonic_active.OnCreated

function modifier_item_sonic_active:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    MODIFIER_PROPERTY_IGNORE_MOVESPEED_LIMIT,
    MODIFIER_PROPERTY_IGNORE_ATTACKSPEED_LIMIT,
    MODIFIER_PROPERTY_ATTACKSPEED_REDUCTION_PERCENTAGE,
    --MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING
  }
end

function modifier_item_sonic_active:CheckState()
  return {
    [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    [MODIFIER_STATE_UNSLOWABLE] = true,
    [MODIFIER_STATE_ROOTED] = false,
    [MODIFIER_STATE_TETHERED] = false,
  }
end

function modifier_item_sonic_active:GetModifierMoveSpeedBonus_Percentage()
  return self.speed or self:GetAbility():GetSpecialValueFor("active_speed_bonus")
end

function modifier_item_sonic_active:GetModifierIgnoreMovespeedLimit()
  return 1
end

-- Maybe Valve will change this some day into GetModifierIgnoreAttackspeedLimit ...
function modifier_item_sonic_active:GetModifierAttackSpeed_Limit()
  return 1
end

function modifier_item_sonic_active:GetModifierAttackSpeedReductionPercentage()
  return 0
end

--function modifier_item_sonic_active:GetModifierStatusResistanceStacking()
  --return self:GetAbility():GetSpecialValueFor("status_resist")
--end

function modifier_item_sonic_active:GetEffectName()
  return "particles/units/heroes/hero_dark_seer/dark_seer_surge.vpcf"
end
