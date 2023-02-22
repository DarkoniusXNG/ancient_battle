LinkLuaModifier("modifier_item_custom_hand_of_midas", "items/hand_of_midas.lua", LUA_MODIFIER_MOTION_NONE)

item_custom_hand_of_midas = class({})

function item_custom_hand_of_midas:GetIntrinsicModifierName()
  return "modifier_item_custom_hand_of_midas"
end

function item_custom_hand_of_midas:CastFilterResultTarget(target)
  local default_result = self.BaseClass.CastFilterResultTarget(self, target)

  if string.sub(target:GetUnitName(), 1, 21) == "npc_dota_necronomicon" or target:IsCustomWardTypeUnit() then
    return UF_FAIL_CUSTOM
  elseif target:IsCourier() then
    return UF_FAIL_COURIER
  elseif IsServer() then
    if target:IsZombie() then
      return UF_FAIL_CUSTOM
    end
  end

  return default_result
end

function item_custom_hand_of_midas:GetCustomCastErrorTarget(target)
  return "#dota_hud_error_cannot_transmute"
end

function item_custom_hand_of_midas:OnSpellStart()
  local caster = self:GetCaster()
  local target = self:GetCursorTarget()

  local xpMult = self:GetSpecialValueFor("xp_multiplier")
  local bonusGold = self:GetSpecialValueFor("bonus_gold")

  local defaultXPBounty = target:GetDeathXP()
  local player = caster:GetPlayerOwner()
  local playerID = caster:GetPlayerOwnerID()

  -- Midas Particle
  local midas_particle = ParticleManager:CreateParticle("particles/items2_fx/hand_of_midas.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
  ParticleManager:SetParticleControlEnt(midas_particle, 1, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), false)
  ParticleManager:ReleaseParticleIndex(midas_particle)

  if player then
    -- Overhead gold amount popup
    SendOverheadEventMessage(player, OVERHEAD_ALERT_GOLD, target, bonusGold, player)
    -- If the Hand of Midas user is a Spirit Bear or Arc Warden Tempest Double:
    if not caster:IsHero() or caster:IsTempestDouble() then
      caster = player:GetAssignedHero()
    end
  end

  -- Midas Sound
  target:EmitSound("DOTA_Item.Hand_Of_Midas")

  -- Give experience to the main hero; (xpMult-1) because we are NOT setting Death XP to 0 later
  if caster.AddExperience then
    caster:AddExperience(defaultXPBounty*(xpMult-1), DOTA_ModifyXP_CreepKill, false, false)
  end

  -- Giving only bonus gold as reliable gold to the player that used Hand of Midas
  PlayerResource:ModifyGold(playerID, bonusGold, true, DOTA_ModifyGold_CreepKill)

  --target:SetDeathXP(0)
  --target:SetMinimumGoldBounty(0)
  --target:SetMaximumGoldBounty(0)

  target:Kill(self, caster)
end

function item_custom_hand_of_midas:ProcsMagicStick()
  return false
end

---------------------------------------------------------------------------------------------------

modifier_item_custom_hand_of_midas = class({})

function modifier_item_custom_hand_of_midas:IsHidden()
  return true
end

function modifier_item_custom_hand_of_midas:IsDebuff()
  return false
end

function modifier_item_custom_hand_of_midas:IsPurgable()
  return false
end

function modifier_item_custom_hand_of_midas:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_custom_hand_of_midas:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.attack_speed = ability:GetSpecialValueFor("bonus_attack_speed")
  end
end

modifier_item_custom_hand_of_midas.OnRefresh = modifier_item_custom_hand_of_midas.OnCreated

function modifier_item_custom_hand_of_midas:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
  }
end

function modifier_item_custom_hand_of_midas:GetModifierAttackSpeedBonus_Constant()
  return self.attack_speed or self:GetAbility():GetSpecialValueFor("bonus_attack_speed")
end
