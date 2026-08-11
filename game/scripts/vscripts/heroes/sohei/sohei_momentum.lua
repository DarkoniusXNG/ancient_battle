LinkLuaModifier("modifier_sohei_momentum_passive", "heroes/sohei/sohei_momentum.lua", LUA_MODIFIER_MOTION_NONE)

sohei_momentum = class({})

function sohei_momentum:GetAbilityTextureName()
  local baseName = self.BaseClass.GetAbilityTextureName(self)

  if self:GetSpecialValueFor("trigger_distance") <= 0 then
    return baseName
  end

  if self.intrMod and not self.intrMod:IsNull() and not self.intrMod:IsMomentumReady() then
    return baseName .. "_inactive"
  end

  return baseName
end

function sohei_momentum:GetIntrinsicModifierName()
	return "modifier_sohei_momentum_passive"
end

function sohei_momentum:ShouldUseResources()
  return true
end

---------------------------------------------------------------------------------------------------
-- Momentum's passive modifier
modifier_sohei_momentum_passive = class({})

function modifier_sohei_momentum_passive:IsHidden()
  return true
end

function modifier_sohei_momentum_passive:IsPurgable()
  return false
end

function modifier_sohei_momentum_passive:IsDebuff()
  return false
end

function modifier_sohei_momentum_passive:RemoveOnDeath()
  return false
end

function modifier_sohei_momentum_passive:IsMomentumReady()
  local ability = self:GetAbility()
  local distanceFull = ability:GetSpecialValueFor("trigger_distance")
  if IsServer() then
    return self:GetStackCount() >= distanceFull and ability:IsCooldownReady()
  else
    return self:GetStackCount() >= distanceFull
  end
end

function modifier_sohei_momentum_passive:OnCreated()
  self:GetAbility().intrMod = self

  self.parentOrigin = self:GetParent():GetAbsOrigin()
  self.attackPrimed = false -- necessary for cases when sohei starts an attack while moving

  if IsServer() then
    self:StartIntervalThink( 1 / 30 )
  end
end

if IsServer() then
  function modifier_sohei_momentum_passive:OnIntervalThink()
    -- Update position
    local parent = self:GetParent()
    local ability = self:GetAbility()
    local oldOrigin = self.parentOrigin
    self.parentOrigin = parent:GetAbsOrigin()

    if not self:IsMomentumReady() then
      if ability:IsCooldownReady() and not parent:PassivesDisabled() then
        self:SetStackCount(self:GetStackCount() + ( self.parentOrigin - oldOrigin ):Length2D())
      end
    end
  end

  function modifier_sohei_momentum_passive:DeclareFunctions()
    return {
      MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
      MODIFIER_EVENT_ON_ATTACK_LANDED,
    }
  end

  function modifier_sohei_momentum_passive:GetModifierPreAttack_CriticalStrike(event)
    local parent = self:GetParent()
    local ability = self:GetAbility()
    local target = event.target

    -- Check if attacked entity exists
    if not target or target:IsNull() then
      return 0
    end

    -- Check if attacked entity is an item, rune or something weird
    if target.GetUnitName == nil then
      return 0
    end

    if self:IsMomentumReady() and not parent:PassivesDisabled() then

      -- make sure the target is valid
      local ufResult = UnitFilter(
        target,
        ability:GetAbilityTargetTeam(),
        ability:GetAbilityTargetType(),
        bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_NO_INVIS, DOTA_UNIT_TARGET_FLAG_NOT_ATTACK_IMMUNE),
        parent:GetTeamNumber()
      )

      if ufResult ~= UF_SUCCESS then
        return 0
      end

      self.attackPrimed = true

      local crit_damage = ability:GetSpecialValueFor("crit_damage")
      -- Talent that increases crit damage
      local talent = parent:FindAbilityByName("special_bonus_unique_sohei_5")
      if talent and talent:GetLevel() > 0 then
        crit_damage = crit_damage + talent:GetSpecialValueFor("value")
      end

      return crit_damage
    end

    self.attackPrimed = false
    return 0
  end

  function modifier_sohei_momentum_passive:OnAttackLanded(event)
    local parent = self:GetParent()
    local attacker = event.attacker
    local target = event.target

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return
    end

    -- Check if attacker has this modifier
    if attacker ~= parent then
      return
    end

    -- Check if attacked entity exists
    if not target or target:IsNull() then
      return
    end

    -- Check if attacked entity is an item, rune or something weird
    if target.GetUnitName == nil then
      return
    end

    if self.attackPrimed == false then
      return
    end

    local ability = self:GetAbility()

    -- Reset stack counter - Momentum attack landed
    self:SetStackCount(0)

    -- start momentum cooldown
    ability:UseResources(false, false, false, true)
  end
end
