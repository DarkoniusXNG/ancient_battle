item_custom_arcane_ring = class({})

LinkLuaModifier("modifier_item_custom_arcane_ring_passive", "items/arcane_ring.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_custom_arcane_ring_buff", "items/arcane_ring.lua", LUA_MODIFIER_MOTION_NONE)

function item_custom_arcane_ring:GetIntrinsicModifierName()
  return "modifier_item_custom_arcane_ring_passive"
end

function item_custom_arcane_ring:OnSpellStart()
  local caster = self:GetCaster()
  local radius = self:GetSpecialValueFor("active_radius")
  local buff_duration = self:GetSpecialValueFor("active_duration")
  local mana = self:GetSpecialValueFor("mana_replenish")

  -- Particle
  local particle = ParticleManager:CreateParticle("particles/items_fx/arcane_boots.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
  --ParticleManager:SetParticleControlEnt(particle, 0, caster, PATTACH_ABSORIGIN_FOLLOW, nil, caster:GetOrigin(), false)
  ParticleManager:ReleaseParticleIndex(particle)

  -- Sound
  caster:EmitSound("DOTA_Item.ArcaneRing.Cast")

  local allies = FindUnitsInRadius(
    caster:GetTeamNumber(),
    caster:GetAbsOrigin(),
    nil,
    radius,
    DOTA_UNIT_TARGET_TEAM_FRIENDLY,
    bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER,
    false
  )

  for _, ally in pairs(allies) do
    ally:GiveMana(mana)
    ally:AddNewModifier(caster, self, "modifier_item_custom_arcane_ring_buff", {duration = buff_duration})
  end
end

---------------------------------------------------------------------------------------------------

modifier_item_custom_arcane_ring_passive = class({})

function modifier_item_custom_arcane_ring_passive:IsHidden()
  return true
end

function modifier_item_custom_arcane_ring_passive:IsPurgable()
  return false
end

function modifier_item_custom_arcane_ring_passive:RemoveOnDeath()
  return false
end

function modifier_item_custom_arcane_ring_passive:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_custom_arcane_ring_passive:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MANA_BONUS,
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
  }
end

function modifier_item_custom_arcane_ring_passive:GetModifierPhysicalArmorBonus()
  return self:GetAbility():GetSpecialValueFor("bonus_armor")
end

function modifier_item_custom_arcane_ring_passive:GetModifierManaBonus()
  return self:GetAbility():GetSpecialValueFor("bonus_mana")
end

---------------------------------------------------------------------------------------------------

modifier_item_custom_arcane_ring_buff = class({})

function modifier_item_custom_arcane_ring_buff:IsHidden() -- needs tooltip
  return false
end

function modifier_item_custom_arcane_ring_buff:IsDebuff()
  return false
end

function modifier_item_custom_arcane_ring_buff:IsPurgable()
  return true
end

function modifier_item_custom_arcane_ring_buff:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.cdr = ability:GetSpecialValueFor("buff_cdr")
    self.spell_amp = ability:GetSpecialValueFor("buff_spell_amp")
  end

  if IsServer() then
    -- Particle
    local particle = ParticleManager:CreateParticle("particles/items_fx/arcane_boots_recipient.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
    ParticleManager:ReleaseParticleIndex(particle)
  end
end

function modifier_item_custom_arcane_ring_buff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
    MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE,
  }
end

function modifier_item_custom_arcane_ring_buff:GetModifierSpellAmplify_Percentage()
  return self.spell_amp
end

function modifier_item_custom_arcane_ring_buff:GetModifierPercentageCooldown()
  return self.cdr
end

function modifier_item_custom_arcane_ring_buff:GetTexture()
  return "item_arcane_ring"
end
