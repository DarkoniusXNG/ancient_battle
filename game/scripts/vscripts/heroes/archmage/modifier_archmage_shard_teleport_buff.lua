modifier_archmage_shard_teleport_buff = class({})

function modifier_archmage_shard_teleport_buff:IsHidden()
  return true
end

function modifier_archmage_shard_teleport_buff:IsDebuff()
  return false
end

function modifier_archmage_shard_teleport_buff:IsPurgable()
  return false
end

function modifier_archmage_shard_teleport_buff:RemoveOnDeath()
  return false
end

function modifier_archmage_shard_teleport_buff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
  }
end

function modifier_archmage_shard_teleport_buff:GetModifierIncomingDamage_Percentage()
  local parent = self:GetParent()
  if parent:IsIllusion() or not parent:HasShardCustom() then
    return 0
  end

  if parent:IsChanneling() then
    return -50
  end

  return 0
end

function modifier_archmage_shard_teleport_buff:CheckState()
  local parent = self:GetParent()
  local state = {
    [MODIFIER_STATE_MAGIC_IMMUNE] = true,
  }
  
  if parent:IsIllusion() or not parent:HasShardCustom() then
    return {}
  end
  
  if parent:IsChanneling() then
    return state
  end
  
  return {}
end
