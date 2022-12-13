LinkLuaModifier("modifier_archmage_shard_teleport_visual_bkb", "heroes/archmage/modifier_archmage_shard_teleport_buff.lua", LUA_MODIFIER_MOTION_NONE)

modifier_archmage_shard_teleport_buff = class({})

function modifier_archmage_shard_teleport_buff:IsHidden() -- needs tooltip
  local parent = self:GetParent()
  return not parent:HasShardCustom()
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

if IsServer() then
  function modifier_archmage_shard_teleport_buff:OnCreated()
    self:StartIntervalThink(0.1)
  end

  function modifier_archmage_shard_teleport_buff:OnIntervalThink()
    local parent = self:GetParent()
    if parent:IsIllusion() then
      self:Destroy()
    end
    if parent:HasShardCustom() and parent:IsChanneling() then
      if not parent:HasModifier("modifier_archmage_shard_teleport_visual_bkb") then
        parent:AddNewModifier(parent, nil, "modifier_archmage_shard_teleport_visual_bkb", {})
      end
    else
      parent:RemoveModifierByName("modifier_archmage_shard_teleport_visual_bkb")
    end
  end
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

---------------------------------------------------------------------------------------------------

modifier_archmage_shard_teleport_visual_bkb = class({})

function modifier_archmage_shard_teleport_visual_bkb:IsHidden()
  return true
end

function modifier_archmage_shard_teleport_visual_bkb:IsDebuff()
  return false
end

function modifier_archmage_shard_teleport_visual_bkb:IsPurgable()
  return false
end

function modifier_archmage_shard_teleport_visual_bkb:RemoveOnDeath()
  return true
end

function modifier_archmage_shard_teleport_visual_bkb:OnCreated()
  -- Basic dispel
  local RemovePositiveBuffs = false
  local RemoveDebuffs = true
  local BuffsCreatedThisFrameOnly = false
  local RemoveStuns = false
  local RemoveExceptions = false
  self:GetParent():Purge(RemovePositiveBuffs, RemoveDebuffs, BuffsCreatedThisFrameOnly, RemoveStuns, RemoveExceptions)
end

function modifier_archmage_shard_teleport_visual_bkb:GetEffectName()
  return "particles/items_fx/black_king_bar_avatar.vpcf"
end

function modifier_archmage_shard_teleport_visual_bkb:GetStatusEffectName()
  return "particles/status_fx/status_effect_avatar.vpcf"
end

--function modifier_archmage_shard_teleport_visual_bkb:GetEffectAttachType()
  --return PATTACH_ABSORIGIN_FOLLOW
--end
