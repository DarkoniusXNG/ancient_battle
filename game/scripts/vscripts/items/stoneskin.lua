item_stoneskin = class({})

LinkLuaModifier("modifier_item_stoneskin_passives", "items/stoneskin.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_stoneskin_aura_effect", "items/stoneskin.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_stoneskin_active", "items/stoneskin.lua", LUA_MODIFIER_MOTION_NONE)

function item_stoneskin:GetIntrinsicModifierName()
  return "modifier_item_stoneskin_passives"
end

function item_stoneskin:OnSpellStart()
  local caster = self:GetCaster()

  -- Apply Stoneskin buff to caster
  caster:AddNewModifier(caster, self, "modifier_item_stoneskin_active", {duration = self:GetSpecialValueFor("duration")})

  -- Activation Sound
  caster:EmitSound("Hero_EarthSpirit.Petrify")
end

-- OnProjectileHit_ExtraData doesn't work for items which is sad
function item_stoneskin:OnProjectileHit(target, location)
  if not target or not location then
    return
  end

  if target:IsMagicImmune() or target:IsAttackImmune() then
    return
  end

  local attacker
  if self.deflect_attacker then
    attacker = EntIndexToHScript(self.deflect_attacker)
  end
  
  if not attacker or attacker:IsNull() then
    return
  end
  
  local damage = self.deflect_damage or 0

  -- Initialize damage table
  local damage_table = {
    attacker = attacker,
    damage = damage,
    damage_type = DAMAGE_TYPE_PHYSICAL,
    damage_flags = bit.bor(DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL),
    ability = self,
    victim = target,
  }

  -- Apply damage
  ApplyDamage(damage_table)

  return true
end

------------------------------------------------------------------------

modifier_item_stoneskin_passives = class({})

function modifier_item_stoneskin_passives:IsHidden()
  return true
end

function modifier_item_stoneskin_passives:IsDebuff()
  return false
end

function modifier_item_stoneskin_passives:IsPurgable()
  return false
end

function modifier_item_stoneskin_passives:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_stoneskin_passives:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
  }
end

function modifier_item_stoneskin_passives:GetModifierPhysicalArmorBonus()
  return self:GetAbility():GetSpecialValueFor("bonus_armor")
end

function modifier_item_stoneskin_passives:IsAura()
  return true
end

function modifier_item_stoneskin_passives:GetModifierAura()
  return "modifier_item_stoneskin_aura_effect"
end

function modifier_item_stoneskin_passives:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("aura_radius")
end

function modifier_item_stoneskin_passives:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_item_stoneskin_passives:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC)
end

---------------------------------------------------------------------------------------------------

modifier_item_stoneskin_aura_effect = class({})

function modifier_item_stoneskin_aura_effect:IsHidden() -- needs tooltip
  return false
end

function modifier_item_stoneskin_aura_effect:IsDebuff()
  return false
end

function modifier_item_stoneskin_aura_effect:IsPurgable()
  return false
end

function modifier_item_stoneskin_aura_effect:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.hp_regen_amp = ability:GetSpecialValueFor("hp_regen_amp")
    self.lifesteal_amp = ability:GetSpecialValueFor("lifesteal_amp")
    self.heal_amp = ability:GetSpecialValueFor("heal_amp")
    self.spell_lifesteal_amp = ability:GetSpecialValueFor("spell_lifesteal_amp")
  end
end

function modifier_item_stoneskin_aura_effect:OnRefresh()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.hp_regen_amp = ability:GetSpecialValueFor("hp_regen_amp")
    self.lifesteal_amp = ability:GetSpecialValueFor("lifesteal_amp")
    self.heal_amp = ability:GetSpecialValueFor("heal_amp")
    self.spell_lifesteal_amp = ability:GetSpecialValueFor("spell_lifesteal_amp")
  end
end

function modifier_item_stoneskin_aura_effect:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
    MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET,
    MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE,
    MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE,
  }
end

function modifier_item_stoneskin_aura_effect:GetModifierHPRegenAmplify_Percentage()
  return self.hp_regen_amp or self:GetAbility():GetSpecialValueFor("hp_regen_amp")
end

function modifier_item_stoneskin_aura_effect:GetModifierHealAmplify_PercentageTarget()
  return self.heal_amp or self:GetAbility():GetSpecialValueFor("heal_amp")
end

function modifier_item_stoneskin_aura_effect:GetModifierLifestealRegenAmplify_Percentage()
  return self.lifesteal_amp or self:GetAbility():GetSpecialValueFor("lifesteal_amp")
end

function modifier_item_stoneskin_aura_effect:GetModifierSpellLifestealRegenAmplify_Percentage()
  return self.spell_lifesteal_amp or self:GetAbility():GetSpecialValueFor("spell_lifesteal_amp")
end

------------------------------------------------------------------------

modifier_item_stoneskin_active = class({})

function modifier_item_stoneskin_active:IsHidden() -- needs tooltip
  return false
end

function modifier_item_stoneskin_active:IsDebuff()
  return false
end

function modifier_item_stoneskin_active:IsPurgable()
  return false
end

function modifier_item_stoneskin_active:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
    MODIFIER_PROPERTY_AVOID_DAMAGE,
    MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
    MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE,
  }
end

function modifier_item_stoneskin_active:GetModifierPhysicalArmorBonus()
  if not self:GetAbility() then
    if not self:IsNull() then
      self:Destroy()
    end
    return 0
  end
  return self:GetAbility():GetSpecialValueFor("stone_armor")
end

function modifier_item_stoneskin_active:GetModifierMagicalResistanceBonus()
  if not self:GetAbility() then
    if not self:IsNull() then
      self:Destroy()
    end
    return 0
  end
  return self:GetAbility():GetSpecialValueFor("stone_magic_resist")
end

function modifier_item_stoneskin_active:GetModifierAvoidDamage(event)
  local parent = self:GetParent()
  local ability = self:GetAbility()
  local chance = 30
  local radius = 400
  if ability and not ability:IsNull() then
    chance = ability:GetSpecialValueFor("stone_deflect_chance")
    radius = ability:GetSpecialValueFor("stone_deflect_radius")
  end
  if event.ranged_attack == true and event.damage_category == DOTA_DAMAGE_CATEGORY_ATTACK and RollPseudoRandomPercentage(chance, DOTA_PSEUDO_RANDOM_CUSTOM_GAME_1, parent) == true then
    local units = FindUnitsInRadius(
      parent:GetTeamNumber(),
      parent:GetAbsOrigin(),
      nil,
      radius,
      DOTA_UNIT_TARGET_TEAM_BOTH,
      bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
      DOTA_UNIT_TARGET_FLAG_NONE,
      FIND_CLOSEST,
      false
    )
    local closest
    local attacker = event.attacker
    for _, unit in ipairs(units) do
      if unit ~= parent then
        closest = unit
        break
      end
    end
    if closest and attacker then
      local info = {
	    EffectName = attacker:GetRangedProjectileName(),
        Ability = ability,
        Source = parent,
        vSourceLoc = parent:GetAbsOrigin(),
        Target = closest,
        iMoveSpeed = attacker:GetProjectileSpeed(),
        bDodgeable = true,
        bProvidesVision = true,
        iVisionRadius = 250,
        iVisionTeamNumber = attacker:GetTeamNumber(),
        --bIsAttack = true,
        --bReplaceExisting = false,
        --bIgnoreObstructions = true,
        iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1,
        bDrawsOnMinimap = false,
        bVisibleToEnemies = true,
        -- ExtraData = {
          -- attacker = attacker:GetEntityIndex(),
          -- damage = math.max(event.original_damage, event.damage),
        -- }
      }
      -- Create a tracking projectile
      ProjectileManager:CreateTrackingProjectile(info)
	  
	  if ability then
	    ability.deflect_attacker = attacker:GetEntityIndex()
        ability.deflect_damage = math.max(event.original_damage, event.damage)
	  end
	end
	return 1
  end

  return 0
end

function modifier_item_stoneskin_active:GetModifierStatusResistanceStacking()
  if not self:GetAbility() then
    if not self:IsNull() then
      self:Destroy()
    end
    return 0
  end
  return self:GetAbility():GetSpecialValueFor("stone_status_resist")
end

function modifier_item_stoneskin_active:GetStatusEffectName()
  return "particles/status_fx/status_effect_earth_spirit_petrify.vpcf"
end

function modifier_item_stoneskin_active:StatusEffectPriority()
  return MODIFIER_PRIORITY_ULTRA
end

function modifier_item_stoneskin_active:GetModifierMoveSpeed_Absolute()
  if not self:GetAbility() then
    if not self:IsNull() then
      self:Destroy()
    end
    return
  end
  return self:GetAbility():GetSpecialValueFor("stone_move_speed")
end