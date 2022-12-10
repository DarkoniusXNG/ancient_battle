LinkLuaModifier("modifier_custom_super_illusion_hide", "modifiers/modifier_custom_super_illusion.lua", LUA_MODIFIER_MOTION_NONE)

modifier_custom_super_illusion = class({})

function modifier_custom_super_illusion:IsHidden()
  return true
end

function modifier_custom_super_illusion:IsDebuff()
  return false
end

function modifier_custom_super_illusion:IsPurgable()
  return false
end

function modifier_custom_super_illusion:RemoveOnDeath()
  return false
end

function modifier_custom_super_illusion:OnCreated(event)
  if IsServer() then
    self.mute = event.mute == 1
    self.attack_dmg_reduction = event.attack_dmg_reduction
    self.bounty = event.bounty
  end
end

function modifier_custom_super_illusion:DeclareFunctions()
  return {
    --MODIFIER_PROPERTY_TEMPEST_DOUBLE,
    --MODIFIER_PROPERTY_SUPER_ILLUSION_WITH_ULTIMATE,
    MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
    MODIFIER_PROPERTY_MIN_HEALTH,
    MODIFIER_EVENT_ON_TAKEDAMAGE,
    MODIFIER_EVENT_ON_DEATH,
  }
end

--function modifier_custom_super_illusion:GetModifierTempestDouble()
  --return 1
--end

--function modifier_custom_super_illusion:GetModifierSuperIllusionWithUltimate()
  --return 1
--end

function modifier_custom_super_illusion:GetModifierTotalDamageOutgoing_Percentage(event)
  if not event.inflictor and event.damage_category == DOTA_DAMAGE_CATEGORY_ATTACK then
    return self.attack_dmg_reduction
  end
  return 0
end

if IsServer() then
  function modifier_custom_super_illusion:GetMinHealth()
    return 1
  end

  -- This is important when super illusion is killed
  function modifier_custom_super_illusion:OnTakeDamage(event)
    local parent = self:GetParent()
    if event.unit ~= parent then
      return
    end

    if event.damage >= parent:GetHealth() then
      HideTheCopyPermanently(parent)
      -- Apply a modifier that will keep the copy alive/invulnerable and hidden while debuffs exist or for the duration
      parent:AddNewModifier(parent, nil, "modifier_custom_super_illusion_hide", {})
      -- Deselect the copy/target
      PlayerResource:RemoveFromSelection(parent:GetPlayerOwnerID(), parent)

      local attacker = event.attacker
      if attacker ~= parent then
        PlayerResource:ModifyGold(attacker:GetPlayerOwnerID(), self.bounty, true, DOTA_ModifyGold_Unspecified)
        SendOverheadEventMessage(nil, OVERHEAD_ALERT_GOLD, attacker, self.bounty, nil)
      end

      self:Destroy()
    end
  end

  -- This is important when super illusion expires
  function modifier_custom_super_illusion:OnDeath(event)
    local parent = self:GetParent()

    if event.unit ~= parent then
      return
    end

    HideTheCopyPermanently(parent)
    -- Apply a modifier that will keep the copy alive/invulnerable and hidden while debuffs exist or for the duration
    parent:AddNewModifier(parent, nil, "modifier_custom_super_illusion_hide", {})
    -- Deselect the copy/target
    PlayerResource:RemoveFromSelection(parent:GetPlayerID(), parent)

    self:Destroy()
  end

  function modifier_custom_super_illusion:CheckState()
    return {
      [MODIFIER_STATE_MUTED] = self.mute,
      [MODIFIER_STATE_NOT_ON_MINIMAP_FOR_ENEMIES] = true,
    }
  end
end

---------------------------------------------------------------------------------------------------

modifier_custom_super_illusion_hide = class({})

function modifier_custom_super_illusion_hide:IsHidden()
  return true
end

function modifier_custom_super_illusion_hide:IsDebuff()
  return false
end

function modifier_custom_super_illusion_hide:IsPurgable()
  return false
end

function modifier_custom_super_illusion_hide:OnCreated()
  if not IsServer() then
    return
  end
  self.counter = 0
  self:StartIntervalThink(1)
end

function modifier_custom_super_illusion_hide:OnIntervalThink()
  if not IsServer() then
    return
  end
  local parent = self:GetParent()
  if not parent or parent:IsNull() then
    return
  end
  --local num_of_active_modifiers = 0
  --for index = 0, parent:GetAbilityCount() - 1 do
    --local ability = parent:GetAbilityByIndex(index)
    --if ability and not ability:IsNull() and ability:GetLevel() > 0 then
      -- NumModifiersUsingAbility doesn't work for every ability for some reason, thanks Valve
      --if ability.NumModifiersUsingAbility and ability:NumModifiersUsingAbility() then
        --num_of_active_modifiers = num_of_active_modifiers + ability:NumModifiersUsingAbility()
      --end
    --end
  --end

  self.counter = self.counter + 1

  if self.counter > 60 then
    self:StartIntervalThink(-1)
    self:Destroy()
  end
end

function modifier_custom_super_illusion_hide:OnDestroy()
  if not IsServer() then
    return
  end
  local parent = self:GetParent()
  if not parent or parent:IsNull() then
    return
  end

  --parent:ForceKill(false)
  parent:MakeIllusion()
  parent:RemoveSelf()
end

function modifier_custom_super_illusion_hide:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
  }
end

function modifier_custom_super_illusion_hide:GetAbsoluteNoDamagePhysical()
  return 1
end

function modifier_custom_super_illusion_hide:GetAbsoluteNoDamageMagical()
  return 1
end

function modifier_custom_super_illusion_hide:GetAbsoluteNoDamagePure()
  return 1
end

function modifier_custom_super_illusion_hide:GetPriority()
  return MODIFIER_PRIORITY_SUPER_ULTRA + 10000
end

function modifier_custom_super_illusion_hide:CheckState()
  return {
    [MODIFIER_STATE_STUNNED] = true,
    [MODIFIER_STATE_OUT_OF_GAME] = true,
    [MODIFIER_STATE_INVULNERABLE] = true,
    [MODIFIER_STATE_ATTACK_IMMUNE] = true,
    [MODIFIER_STATE_MAGIC_IMMUNE] = true,
    [MODIFIER_STATE_NO_HEALTH_BAR] = true,
    [MODIFIER_STATE_UNSELECTABLE] = true,
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
    [MODIFIER_STATE_NOT_ON_MINIMAP_FOR_ENEMIES] = true,
    [MODIFIER_STATE_PASSIVES_DISABLED] = true,
    [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
    [MODIFIER_STATE_BLIND] = true,
    [MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true,
  }
end
