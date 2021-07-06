archmage_arcane_magic = class({})

LinkLuaModifier("modifier_archmage_aura_applier", "heroes/archmage/arcane_magic.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_archmage_aura_effect", "heroes/archmage/arcane_magic.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_archmage_arcane_magic_buff", "heroes/archmage/arcane_magic.lua", LUA_MODIFIER_MOTION_NONE)

function archmage_arcane_magic:GetIntrinsicModifierName()
  return "modifier_archmage_aura_applier"
end

function archmage_arcane_magic:OnSpellStart()
  local caster = self:GetCaster()
  local target = self:GetCursorTarget()
  local duration = self:GetSpecialValueFor("buff_duration")
  
  -- Cast sound
  target:EmitSound("Hero_KeeperOfTheLight.ChakraMagic.Target")

  -- Cast particle
  local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_keeper_of_the_light/keeper_of_the_light_chakra_magic.vpcf", PATTACH_POINT_FOLLOW, caster)
  ParticleManager:SetParticleControlEnt(particle, 0, caster, PATTACH_POINT_FOLLOW, "attach_attack1", caster:GetAbsOrigin(), true)
  ParticleManager:SetParticleControl(particle, 1, target:GetAbsOrigin())
  ParticleManager:ReleaseParticleIndex(particle)
  
-- "FireEffect"
-- {
-- "EffectName"		"particles/units/heroes/hero_keeper_of_the_light/keeper_chakra_magic.vpcf"
-- "EffectAttachType"  "follow_origin"

-- "ControlPointEntities"
-- {
-- "CASTER"	"attach_attack1" 	// ok
-- "TARGET"	"attach_hitloc" 	// follow_origin but it returns an error
-- }
-- }

  -- Actual Effect
  target:AddNewModifier(caster, self, "modifier_archmage_arcane_magic_buff", {duration = duration})
end

function archmage_arcane_magic:ProcsMagicStick()
  return true
end

function archmage_arcane_magic:IsStealable()
  return true
end

function archmage_arcane_magic:OnUnStolen()
  local caster = self:GetCaster()
  local passive_modifier = caster:FindModifierByName("modifier_archmage_aura_applier")
  if passive_modifier then
    caster:RemoveModifierByName("modifier_archmage_aura_applier")
  end
end

---------------------------------------------------------------------------------------------------

modifier_archmage_aura_applier = class({})

function modifier_archmage_aura_applier:IsHidden()
  return true
end

function modifier_archmage_aura_applier:IsDebuff()
  return false
end

function modifier_archmage_aura_applier:IsPurgable()
  return false
end

function modifier_archmage_aura_applier:RemoveOnDeath()
  return false
end

function modifier_archmage_aura_applier:IsAura()
  if self:GetParent():PassivesDisabled() then
    return false
  end
  return true
end

function modifier_archmage_aura_applier:GetModifierAura()
  return "modifier_archmage_aura_effect"
end

function modifier_archmage_aura_applier:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_archmage_aura_applier:GetAuraSearchType()
  return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_archmage_aura_applier:GetAuraSearchFlags()
  return DOTA_UNIT_TARGET_FLAG_MANA_ONLY
end

function modifier_archmage_aura_applier:GetAuraRadius()
  return self:GetSpecialValueFor("aura_radius")
end

--function modifier_archmage_aura_applier:IsAuraActiveOnDeath()
  --return false
--end

---------------------------------------------------------------------------------------------------

modifier_archmage_aura_effect = class({})

function modifier_archmage_aura_effect:IsHidden()
  return false
end

function modifier_archmage_aura_effect:IsDebuff()
  return false
end

function modifier_archmage_aura_effect:IsPurgable()
  return false
end

function modifier_archmage_aura_effect:OnCreated()
  local ability = self:GetAbility()
  if ability then
    self.mana_cost_reduction = ability:GetSpecialValueFor("aura_mana_cost_reduction_pct")
    self.spell_amp = ability:GetSpecialValueFor("aura_spell_amp")
    self.mana_regen = ability:GetSpecialValueFor("aura_mana_regen")
    self.bonus_magic_resist = ability:GetSpecialValueFor("aura_magic_resistance")
  end
end

function modifier_archmage_aura_effect:OnRefresh()
  local ability = self:GetAbility()
  if ability then
    self.mana_cost_reduction = ability:GetSpecialValueFor("aura_mana_cost_reduction_pct")
    self.spell_amp = ability:GetSpecialValueFor("aura_spell_amp")
    self.mana_regen = ability:GetSpecialValueFor("aura_mana_regen")
    self.bonus_magic_resist = ability:GetSpecialValueFor("aura_magic_resistance")
  end
end

function modifier_archmage_aura_effect:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MANACOST_PERCENTAGE_STACKING, --GetModifierPercentageManacostStacking
    MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE, -- GetModifierSpellAmplify_Percentage
    MODIFIER_PROPERTY_MANA_REGEN_CONSTANT, -- GetModifierConstantManaRegen
    MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS, -- GetModifierMagicalResistanceBonus
    --MODIFIER_PROPERTY_TOOLTIP, -- OnTooltip
    --MODIFIER_PROPERTY_TOOLTIP2, -- OnTooltip2
  }
end

function modifier_archmage_aura_effect:GetModifierPercentageManacostStacking()
  return self.mana_cost_reduction or self:GetAbility():GetSpecialValueFor("aura_mana_cost_reduction_pct")
end

function modifier_archmage_aura_effect:GetModifierSpellAmplify_Percentage()
  return self.spell_amp or self:GetAbility():GetSpecialValueFor("aura_spell_amp")
end

function modifier_archmage_aura_effect:GetModifierConstantManaRegen()
  return self.mana_regen or self:GetAbility():GetSpecialValueFor("aura_mana_regen")
end

function modifier_archmage_aura_effect:GetModifierMagicalResistanceBonus()
  return self.bonus_magic_resist or self:GetAbility():GetSpecialValueFor("aura_magic_resistance")
end

--function modifier_archmage_aura_effect:OnTooltip()
  --return self.mana_cost_reduction
--end

--function modifier_archmage_aura_effect:OnTooltip2()
  --return self.spell_amp
--end

function modifier_archmage_aura_effect:GetEffectName()
  return "particles/items_fx/aura_shivas.vpcf"
end

function modifier_archmage_aura_effect:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end

---------------------------------------------------------------------------------------------------

modifier_archmage_arcane_magic_buff = class({})

function modifier_archmage_arcane_magic_buff:IsHidden()
  return false
end

function modifier_archmage_arcane_magic_buff:IsDebuff()
  return false
end

function modifier_archmage_arcane_magic_buff:IsPurgable()
  return true
end

function modifier_archmage_arcane_magic_buff:OnCreated()
  local ability = self:GetAbility()
  if ability then
    self.cd_reduction = ability:GetSpecialValueFor("buff_cd_reduction")
    self.mana_regen_amp = ability:GetSpecialValueFor("buff_mana_regen_amp")
  end

--"AttachEffect"
-- {
-- "EffectName"					"particles/frostivus_herofx/maiden_holdout_arcane_buff.vpcf"
-- "EffectAttachType"				"follow_origin"
-- "Target"						"TARGET"
-- }
end

function modifier_archmage_arcane_magic_buff:OnRefresh()
  local ability = self:GetAbility()
  if ability then
    self.cd_reduction = ability:GetSpecialValueFor("buff_cd_reduction")
    self.mana_regen_amp = ability:GetSpecialValueFor("buff_mana_regen_amp")
  end
end

function modifier_archmage_arcane_magic_buff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE, -- GetModifierPercentageCooldown
    --MODIFIER_PROPERTY_MANA_REGEN_CONSTANT, -- GetModifierConstantManaRegen
    MODIFIER_PROPERTY_MP_REGEN_AMPLIFY_PERCENTAGE, -- GetModifierMPRegenAmplify_Percentage
  }
end

function modifier_archmage_arcane_magic_buff:GetModifierPercentageCooldown()
  return self.cd_reduction or self:GetAbility():GetSpecialValueFor("buff_cd_reduction")
end

--function modifier_archmage_arcane_magic_buff:GetModifierConstantManaRegen()
  --return mana_regen * (1 + self.mana_regen_amp/100)
--end

function modifier_archmage_arcane_magic_buff:GetModifierMPRegenAmplify_Percentage()
  return self.mana_regen_amp or self:GetAbility():GetSpecialValueFor("buff_mana_regen_amp")
end

function modifier_archmage_arcane_magic_buff:GetEffectName()
  return "particles/frostivus_herofx/maiden_holdout_arcane_buff.vpcf"
end

function modifier_archmage_arcane_magic_buff:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end
