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
  local ability = self:GetAbility()
  if not ability or ability:IsNull() then
    return
  end

  self.movement_speed = ability:GetSpecialValueFor("bonus_movement_speed")
  self.attack_speed = ability:GetSpecialValueFor("bonus_attack_speed")
  self.agi = ability:GetSpecialValueFor("bonus_agility")
end

modifier_item_sonic_passives.OnRefresh = modifier_item_sonic_passives.OnCreated

function modifier_item_sonic_passives:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_UNIQUE,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
    MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
  }
end

function modifier_item_sonic_passives:GetModifierMoveSpeedBonus_Special_Boots()
  return self.movement_speed
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
    [MODIFIER_STATE_FLYING] = true,
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
