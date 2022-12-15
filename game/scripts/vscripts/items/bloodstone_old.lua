LinkLuaModifier("modifier_item_custom_bloodstone_passive", "items/bloodstone_old.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_custom_bloodstone_dummy_stuff", "items/bloodstone_old.lua", LUA_MODIFIER_MOTION_NONE)

item_custom_bloodstone = class({})

function item_custom_bloodstone:GetIntrinsicModifierName()
  return "modifier_item_custom_bloodstone_passive"
end

function item_custom_bloodstone:OnSpellStart()
  local caster = self:GetCaster()
  caster:Kill(self, caster) -- Pocket Deny
end

--------------------------------------------------------------------------

modifier_item_custom_bloodstone_passive = class({})

function modifier_item_custom_bloodstone_passive:IsHidden()
  return true
end

function modifier_item_custom_bloodstone_passive:IsDebuff()
  return false
end

function modifier_item_custom_bloodstone_passive:IsPurgable()
  return false
end

function modifier_item_custom_bloodstone_passive:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_custom_bloodstone_passive:OnCreated()
  if IsServer() then
    self:StartIntervalThink(0.1)
  end
end

function modifier_item_custom_bloodstone_passive:OnIntervalThink()
  if self:IsFirstItemInInventory() then
    self:SetStackCount(2)
  else
    self:SetStackCount(1)
  end
end

function modifier_item_custom_bloodstone_passive:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_DEATH,
    MODIFIER_PROPERTY_HEALTH_BONUS, -- GetModifierHealthBonus
    MODIFIER_PROPERTY_MANA_BONUS, -- GetModifierManaBonus
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT, -- GetModifierConstantHealthRegen
    MODIFIER_PROPERTY_MANA_REGEN_CONSTANT, -- GetModifierConstantManaRegen
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    MODIFIER_PROPERTY_MP_REGEN_AMPLIFY_PERCENTAGE, -- GetModifierMPRegenAmplify_Percentage
  }
end

function modifier_item_custom_bloodstone_passive:GetModifierHealthBonus()
  return self:GetAbility():GetSpecialValueFor("bonus_health")
end

function modifier_item_custom_bloodstone_passive:GetModifierManaBonus()
  return self:GetAbility():GetSpecialValueFor("bonus_mana")
end

function modifier_item_custom_bloodstone_passive:GetModifierConstantHealthRegen()
  local ability = self:GetAbility()
  if self:GetStackCount() ~= 2 then
    return ability:GetSpecialValueFor("bonus_health_regen")
  end
  return ability:GetSpecialValueFor("bonus_health_regen") + (ability:GetCurrentCharges() * ability:GetSpecialValueFor("health_regen_per_charge"))
end

function modifier_item_custom_bloodstone_passive:GetModifierConstantManaRegen()
  local ability = self:GetAbility()
  if self:GetStackCount() ~= 2 then
    return ability:GetSpecialValueFor("bonus_mana_regen")
  end
  return ability:GetSpecialValueFor("bonus_mana_regen") + (ability:GetCurrentCharges() * ability:GetSpecialValueFor("mana_regen_per_charge"))
end

function modifier_item_custom_bloodstone_passive:GetModifierBonusStats_Strength()
  return self:GetAbility():GetSpecialValueFor("bonus_strength")
end

function modifier_item_custom_bloodstone_passive:GetModifierPhysicalArmorBonus()
  return self:GetAbility():GetSpecialValueFor("bonus_armor")
end

function modifier_item_custom_bloodstone_passive:GetModifierMPRegenAmplify_Percentage()
  if self:GetStackCount() ~= 2 then
    return 0
  end
  return self:GetAbility():GetSpecialValueFor("mana_regen_amp")
end

function modifier_item_custom_bloodstone_passive:IsFirstItemInInventory()
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

--------------------------------------------------------------------------
-- charge handling
if IsServer() then
  function modifier_item_custom_bloodstone_passive:OnDeath(keys)
    local parent = self:GetParent()
    local dead_unit = keys.unit
    local killer = keys.attacker
    local ability = self:GetAbility()

    -- someone else died or owner is reincarnating
    if parent ~= dead_unit or parent:IsReincarnating() then
      -- Dead unit is not on parent's team
      if parent:GetTeamNumber() ~= dead_unit:GetTeamNumber() then
        -- Dead unit is an actually dead real enemy hero unit
        if (dead_unit:IsRealHero() and (not dead_unit:IsTempestDouble()) and (not dead_unit:IsReincarnating()) and (not dead_unit:IsClone())) then
          local parentToDeadVector = dead_unit:GetAbsOrigin() - parent:GetAbsOrigin()
          local isDeadInChargeRange = parentToDeadVector:Length2D() <= ability:GetSpecialValueFor("charge_gain_radius")

          -- Charge gain - only if parent is near the dead unit or if parent is the killer
          if (isDeadInChargeRange or killer == parent) and self:IsFirstItemInInventory() then
            ability:SetCurrentCharges(ability:GetCurrentCharges() + ability:GetSpecialValueFor("charge_gain_per_kill"))
          end
        end
      end
      return
    end

    -- Charge loss (on every Bloodstone)
    local old_charges = ability:GetCurrentCharges()

    -- Don't remove charges when neutrals kill the parent
    if killer:GetTeamNumber() ~= DOTA_TEAM_NEUTRALS then
      local new_charges = math.max(0, old_charges - ability:GetSpecialValueFor("charge_loss_on_death"))
      ability:SetCurrentCharges(new_charges)
    end

    if not parent:IsRealHero() or parent:IsTempestDouble() or not self:IsFirstItemInInventory() then
      return
    end

    local death_location = parent:GetAbsOrigin()
    local heal_amount = ability:GetSpecialValueFor("death_heal_base") + (ability:GetSpecialValueFor("death_heal_per_charge") * old_charges)
    local mana_amount = ability:GetSpecialValueFor("death_mana_restore")
    local allies = FindUnitsInRadius(
      parent:GetTeamNumber(),
      death_location,
      nil,
      ability:GetSpecialValueFor("death_heal_radius"),
      DOTA_UNIT_TARGET_TEAM_FRIENDLY,
      bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
      DOTA_UNIT_TARGET_FLAG_NONE,
      FIND_ANY_ORDER,
      false
    )

    for _, ally in pairs(allies) do
      ally:GiveMana(mana_amount)
      ally:Heal(heal_amount, ability)
    end

    -- Add vision at death location
    local vision_duration = ability:GetSpecialValueFor("death_vision_duration")
    local dummy = CreateUnitByName("npc_dota_custom_dummy_unit", death_location, false, parent, parent, parent:GetTeamNumber())
    dummy:AddNewModifier(parent, ability, "modifier_item_custom_bloodstone_dummy_stuff", {})
    dummy:AddNewModifier(parent, ability, "modifier_kill", {duration = vision_duration})
  end
end

---------------------------------------------------------------------------------------------------

modifier_item_custom_bloodstone_dummy_stuff = class({})

function modifier_item_custom_bloodstone_dummy_stuff:IsHidden()
  return true
end

function modifier_item_custom_bloodstone_dummy_stuff:IsDebuff()
  return false
end

function modifier_item_custom_bloodstone_dummy_stuff:IsPurgable()
  return false
end

function modifier_item_custom_bloodstone_dummy_stuff:DeclareFunctions()
  return {
    --MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
    --MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
    --MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
    MODIFIER_PROPERTY_BONUS_DAY_VISION,
    MODIFIER_PROPERTY_BONUS_NIGHT_VISION,
  }
end

function modifier_item_custom_bloodstone_dummy_stuff:GetAbsoluteNoDamagePhysical()
  return 1
end

function modifier_item_custom_bloodstone_dummy_stuff:GetAbsoluteNoDamageMagical()
  return 1
end

function modifier_item_custom_bloodstone_dummy_stuff:GetAbsoluteNoDamagePure()
  return 1
end

function modifier_item_custom_bloodstone_dummy_stuff:GetBonusDayVision()
  local ability = self:GetAbility()
  if not ability or ability:IsNull() then
    return 1200
  end
  return ability:GetSpecialValueFor("death_vision_radius")
end

function modifier_item_custom_bloodstone_dummy_stuff:GetBonusNightVision()
  local ability = self:GetAbility()
  if not ability or ability:IsNull() then
    return 1200
  end
  return ability:GetSpecialValueFor("death_vision_radius")
end

function modifier_item_custom_bloodstone_dummy_stuff:CheckState()
  return {
    --[MODIFIER_STATE_UNSELECTABLE] = true,
    --[MODIFIER_STATE_NOT_ON_MINIMAP] = true,
    [MODIFIER_STATE_NOT_ON_MINIMAP_FOR_ENEMIES] = true,
    --[MODIFIER_STATE_NO_HEALTH_BAR] = true,
    --[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    --[MODIFIER_STATE_OUT_OF_GAME] = true,
    --[MODIFIER_STATE_NO_TEAM_MOVE_TO] = true,
    --[MODIFIER_STATE_NO_TEAM_SELECT] = true,
    --[MODIFIER_STATE_COMMAND_RESTRICTED] = true,
    --[MODIFIER_STATE_ATTACK_IMMUNE] = true,
    --[MODIFIER_STATE_MAGIC_IMMUNE] = true,
    [MODIFIER_STATE_FLYING] = true,
  }
end
