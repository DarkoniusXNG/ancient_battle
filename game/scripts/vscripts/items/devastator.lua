LinkLuaModifier("modifier_item_devastator_passive", "items/devastator.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_devastator_corruption_armor", "items/devastator.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_devastator_reduce_armor", "items/devastator.lua", LUA_MODIFIER_MOTION_NONE)

item_devastator_custom = class({})

function item_devastator_custom:OnSpellStart()
  local caster = self:GetCaster()
  self.devastator_speed = self:GetSpecialValueFor( "devastator_speed" )
  self.devastator_width_initial = self:GetSpecialValueFor( "devastator_width_initial" )
  self.devastator_width_end = self:GetSpecialValueFor( "devastator_width_end" )
  self.devastator_distance = self:GetSpecialValueFor( "devastator_distance" )
  self.devastator_armor_reduction_duration = self:GetSpecialValueFor( "devastator_armor_reduction_duration" )

  -- Sound
  caster:EmitSound("Item_Desolator.Target")

  local vPos
  if self:GetCursorTarget() then
    vPos = self:GetCursorTarget():GetOrigin()
  else
    vPos = self:GetCursorPosition()
  end

  local vDirection = vPos - caster:GetOrigin()
  vDirection.z = 0.0
  vDirection = vDirection:Normalized()

  self.devastator_speed = self.devastator_speed * ( self.devastator_distance / ( self.devastator_distance - self.devastator_width_initial ) )

  local info = {
    EffectName = "particles/items/devastator/devastator_active.vpcf",
    Ability = self,
    vSpawnOrigin = caster:GetOrigin(),
    fStartRadius = self.devastator_width_initial,
    fEndRadius = self.devastator_width_end,
    vVelocity = vDirection * self.devastator_speed,
    fDistance = self.devastator_distance + caster:GetCastRangeBonus(),
    Source = caster,
    iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
    iUnitTargetType = bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
    iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
    --bReplaceExisting = false,
    --bDeleteOnHit = false,
    --bProvidesVision = false,
  }

  ProjectileManager:CreateLinearProjectile( info )
end

-- Impact of the projectile
function item_devastator_custom:OnProjectileHit( hTarget, vLocation )
  if hTarget and ( not hTarget:IsInvulnerable() ) and ( not hTarget:IsAttackImmune() ) then
    local caster = self:GetCaster()

	local armor_reduction_duration = hTarget:GetValueChangedByStatusResistance(self.devastator_armor_reduction_duration)

    -- Apply the Devastator active armor reduction debuff
    hTarget:AddNewModifier(hTarget, self, "modifier_item_devastator_reduce_armor", {duration = armor_reduction_duration})

    caster:PerformAttack(hTarget, true, true, true, false, false, false, true)

    -- Particles
    local vDirection = vLocation - caster:GetOrigin()
    vDirection.z = 0.0
    vDirection = vDirection:Normalized()
    -- Replace with the particles for the item
    local nFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_lina/lina_spell_dragon_slave_impact.vpcf", PATTACH_ABSORIGIN_FOLLOW, hTarget )
    ParticleManager:SetParticleControlForward( nFXIndex, 1, vDirection )
    ParticleManager:ReleaseParticleIndex( nFXIndex )
  end

  return false
end

function item_devastator_custom:GetIntrinsicModifierName()
  return "modifier_item_devastator_passive"
end

---------------------------------------------------------------------------------------------------

modifier_item_devastator_passive = class({})

function modifier_item_devastator_passive:IsHidden()
  return true
end

function modifier_item_devastator_passive:IsDebuff()
  return false
end

function modifier_item_devastator_passive:IsPurgable()
  return false
end

function modifier_item_devastator_passive:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_devastator_passive:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.bonus_damage = ability:GetSpecialValueFor("bonus_damage")
    self.agi = ability:GetSpecialValueFor("bonus_agility")
  end
end

modifier_item_devastator_passive.OnRefresh = modifier_item_devastator_passive.OnCreated

function modifier_item_devastator_passive:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
    MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
    MODIFIER_PROPERTY_PROJECTILE_NAME,
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
end

function modifier_item_devastator_passive:GetModifierPreAttack_BonusDamage()
  return self.bonus_damage or self:GetAbility():GetSpecialValueFor("bonus_damage")
end

function modifier_item_devastator_passive:GetModifierBonusStats_Agility()
  return self.agi or self:GetAbility():GetSpecialValueFor("bonus_agility")
end

function modifier_item_devastator_passive:GetModifierProjectileName()
  if self:IsFirstItemInInventory() then
    return "particles/items_fx/desolator_projectile.vpcf"
  end
end

function modifier_item_devastator_passive:IsFirstItemInInventory()
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

if IsServer() then
  function modifier_item_devastator_passive:OnAttackLanded(event)
    local parent = self:GetParent()
    local ability = self:GetAbility()
    local target = event.target

    -- Prevent the code below from executing multiple times for no reason
    if not self:IsFirstItemInInventory() then
      return
    end

    if parent ~= event.attacker then
      return
    end

    if parent:IsIllusion() then
      return
    end

    -- To prevent crashes:
    if not target or target:IsNull() then
      return
    end

    -- Check for existence of GetUnitName method to determine if target is a unit or an item (or rune)
    -- items don't have that method -> nil; if the target is an item, don't continue
    if target.GetUnitName == nil then
      return
    end

    -- Doesn't work on allies
    if target:GetTeamNumber() == parent:GetTeamNumber() then
      return
    end

    -- If the target has desolator debuff then remove it (to prevent stacking armor reductions)
    if target:HasModifier("modifier_desolator_buff") then
      target:RemoveModifierByName("modifier_desolator_buff")
    end

    -- If the target has Orb of Corrosion debuff then remove it (to prevent stacking armor reductions)
    if target:HasModifier("modifier_orb_of_corrosion_debuff") then
      target:RemoveModifierByName("modifier_orb_of_corrosion_debuff")
    end

    -- Calculate duration of the debuff
    local corruption_duration = ability:GetSpecialValueFor("corruption_duration")
    -- Calculate duration while keeping status resistance in mind
    local armor_reduction_duration = target:GetValueChangedByStatusResistance(corruption_duration)
    -- Apply Devastator passive debuff
    target:AddNewModifier(parent, ability, "modifier_item_devastator_corruption_armor", {duration = armor_reduction_duration})
  end
end

---------------------------------------------------------------------------------------------------

modifier_item_devastator_corruption_armor = class({})

function modifier_item_devastator_corruption_armor:IsHidden() -- needs tooltip
  return false
end

function modifier_item_devastator_corruption_armor:IsDebuff()
  return true
end

function modifier_item_devastator_corruption_armor:IsPurgable()
  return true
end

function modifier_item_devastator_corruption_armor:OnCreated()
  if IsServer() then
    self:StartIntervalThink(0.1)
  end

  local ability = self:GetAbility()
  if not ability or ability:IsNull() then
    return
  end

  self.armor_reduction = ability:GetSpecialValueFor("corruption_armor")
  self.slow = ability:GetSpecialValueFor("corruption_slow") --self:GetParent():GetValueChangedBySlowResistance(ability:GetSpecialValueFor("corruption_slow"))
  self.heal_reduction = ability:GetSpecialValueFor("corruption_heal_reduction")
end

function modifier_item_devastator_corruption_armor:OnIntervalThink()
  local parent = self:GetParent()
  if parent:HasModifier("modifier_desolator_buff") then
    parent:RemoveModifierByName("modifier_desolator_buff")
  end
  if parent:HasModifier("modifier_orb_of_corrosion_debuff") then
    parent:RemoveModifierByName("modifier_orb_of_corrosion_debuff")
  end
end

function modifier_item_devastator_corruption_armor:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    MODIFIER_PROPERTY_RESTORATION_AMPLIFICATION,
  }
end

function modifier_item_devastator_corruption_armor:GetModifierPhysicalArmorBonus()
  return 0 - math.abs(self.armor_reduction)
end

function modifier_item_devastator_corruption_armor:GetModifierMoveSpeedBonus_Percentage()
  return 0 - math.abs(self.slow)
end

function modifier_item_devastator_corruption_armor:GetModifierPropertyRestorationAmplification()
  return 0 - math.abs(self.heal_reduction)
end

---------------------------------------------------------------------------------------------------

modifier_item_devastator_reduce_armor = class({})

function modifier_item_devastator_reduce_armor:IsHidden() -- needs tooltip
  return false
end

function modifier_item_devastator_reduce_armor:IsDebuff()
  return true
end

function modifier_item_devastator_reduce_armor:IsPurgable()
  return true
end

function modifier_item_devastator_reduce_armor:OnCreated()
  self.armor_reduction = self:GetAbility():GetSpecialValueFor("devastator_armor_reduction")
end

function modifier_item_devastator_reduce_armor:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
  }
end

function modifier_item_devastator_reduce_armor:GetModifierPhysicalArmorBonus()
  return 0 - math.abs(self.armor_reduction)
end
