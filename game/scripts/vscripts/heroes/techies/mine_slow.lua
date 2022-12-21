modifier_techies_custom_mine_slow = class({})

function modifier_techies_custom_mine_slow:IsHidden() -- needs tooltip
  return false
end

function modifier_techies_custom_mine_slow:IsDebuff()
  return true
end

function modifier_techies_custom_mine_slow:IsPurgable()
  return true
end

function modifier_techies_custom_mine_slow:IsStunDebuff()
  return false
end

function modifier_techies_custom_mine_slow:OnCreated()
  local parent = self:GetParent()
  local ability = self:GetAbility()
  local movement_slow = 45
  local attack_slow = 45
  if ability and not ability:IsNull() then
    movement_slow = ability:GetSpecialValueFor("move_speed_slow_pct")
    attack_slow = ability:GetSpecialValueFor("attack_speed_slow")
  end

  if IsServer() then
    -- Slow is reduced with Status Resistance
    self.slow = parent:GetValueChangedByStatusResistance(movement_slow)
    self.attack_speed = parent:GetValueChangedByStatusResistance(attack_slow)
  else
    self.slow = movement_slow
    self.attack_speed = attack_slow
  end
end

function modifier_techies_custom_mine_slow:OnRefresh()
  self:OnCreated()
end

function modifier_techies_custom_mine_slow:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
  }
end

function modifier_techies_custom_mine_slow:GetModifierMoveSpeedBonus_Percentage()
  return 0 - math.abs(self.slow)
end

function modifier_techies_custom_mine_slow:GetModifierAttackSpeedBonus_Constant()
  return 0 - math.abs(self.attack_speed)
end
