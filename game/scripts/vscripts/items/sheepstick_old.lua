item_sheepstick_old = class({})

LinkLuaModifier("modifier_item_old_hex", "items/sheepstick_old.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_sheepstick_old_passive", "items/sheepstick_old.lua", LUA_MODIFIER_MOTION_NONE)

function item_sheepstick_old:OnSpellStart()
  local caster = self:GetCaster()
  local target = self:GetCursorTarget()
  local debuff_duration = self:GetSpecialValueFor("hex_duration")

  -- Check for spell block
  if target:TriggerSpellAbsorb(self) then return end

  -- Play the cast sound
  target:EmitSound("DOTA_Item.Sheepstick.Activate")

  -- Kill the target instantly if it is an illusion
  if target:IsIllusion() and not target:IsStrongIllusionCustom() then
    --target:ForceKill(false)
    target:Kill(self, caster)
    return
  end

  -- Status Resistance fix
  debuff_duration = target:GetValueChangedByStatusResistance(debuff_duration)

  target:AddNewModifier(caster, self, "modifier_item_old_hex", {duration = debuff_duration})
  --target:AddNewModifier(caster, self, "modifier_hexxed", {duration = debuff_duration})
end

function item_sheepstick_old:GetIntrinsicModifierName()
  return "modifier_item_sheepstick_old_passive"
end

---------------------------------------------------------------------------------------------------

modifier_item_sheepstick_old_passive = class({})

function modifier_item_sheepstick_old_passive:IsHidden()
  return true
end

function modifier_item_sheepstick_old_passive:IsPurgable()
  return false
end

function modifier_item_sheepstick_old_passive:RemoveOnDeath()
  return false
end

function modifier_item_sheepstick_old_passive:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_sheepstick_old_passive:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
    MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
    MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
  }
end

function modifier_item_sheepstick_old_passive:GetModifierPreAttack_BonusDamage()
  return self:GetAbility():GetSpecialValueFor("bonus_damage")
end

function modifier_item_sheepstick_old_passive:GetModifierBonusStats_Strength()
  return self:GetAbility():GetSpecialValueFor("bonus_strength")
end

function modifier_item_sheepstick_old_passive:GetModifierBonusStats_Agility()
  return self:GetAbility():GetSpecialValueFor("bonus_agility")
end

function modifier_item_sheepstick_old_passive:GetModifierBonusStats_Intellect()
  return self:GetAbility():GetSpecialValueFor("bonus_intellect")
end

function modifier_item_sheepstick_old_passive:GetModifierConstantManaRegen()
  return self:GetAbility():GetSpecialValueFor("bonus_mana_regen")
end

function modifier_item_sheepstick_old_passive:GetModifierAttackSpeedBonus_Constant()
  return self:GetAbility():GetSpecialValueFor("bonus_attack_speed")
end

---------------------------------------------------------------------------------------------------

modifier_item_old_hex = class({})

function modifier_item_old_hex:IsHidden() -- needs tooltip
  return false
end

function modifier_item_old_hex:IsDebuff()
  return true
end

function modifier_item_old_hex:IsStunDebuff()
  return true
end

function modifier_item_old_hex:IsPurgable()
  return true
end

if IsServer() then
  function modifier_item_old_hex:OnCreated()
    local parent = self:GetParent()
    local caster = self:GetCaster()
    self.sheep_pfx = ParticleManager:CreateParticle("particles/items_fx/item_sheepstick.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    ParticleManager:SetParticleControl(self.sheep_pfx, 0, parent:GetAbsOrigin())

    -- Decide which model
    local random_number = RandomInt(1, 3)
    if random_number == 1 then
      self.model = "models/props_gameplay/pig.vmdl"
    elseif random_number == 2 then
      self.model = "models/props_gameplay/frog.vmdl"
    else
      self.model = "models/props_gameplay/chicken.vmdl"
    end
  end

  function modifier_item_old_hex:OnRefresh()
    if self.sheep_pfx then
      ParticleManager:DestroyParticle(self.sheep_pfx, true)
      ParticleManager:ReleaseParticleIndex(self.sheep_pfx)
    end
    self:OnCreated()
  end

  function modifier_item_old_hex:OnDestroy()
    if self.sheep_pfx then
      ParticleManager:DestroyParticle(self.sheep_pfx, false)
      ParticleManager:ReleaseParticleIndex(self.sheep_pfx)
    end
  end
end

function modifier_item_old_hex:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BASE_OVERRIDE,
    MODIFIER_PROPERTY_MODEL_CHANGE,
    MODIFIER_PROPERTY_VISUAL_Z_DELTA,
  }
end

function modifier_item_old_hex:GetModifierMoveSpeedOverride()
  return self:GetAbility():GetSpecialValueFor("hex_move_speed")
end

function modifier_item_old_hex:GetModifierModelChange()
  return self.model
end

function modifier_item_old_hex:GetVisualZDelta()
  return 0
end

function modifier_item_old_hex:CheckState()
  return {
    [MODIFIER_STATE_HEXED] = true,
    [MODIFIER_STATE_DISARMED] = true,
    [MODIFIER_STATE_SILENCED] = true,
    [MODIFIER_STATE_MUTED] = true,
    [MODIFIER_STATE_PASSIVES_DISABLED] = true,
    [MODIFIER_STATE_BLOCK_DISABLED] = true,
    [MODIFIER_STATE_EVADE_DISABLED] = true,
  }
end
