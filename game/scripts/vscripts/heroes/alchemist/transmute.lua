alchemist_custom_transmute = class({})

LinkLuaModifier("modifier_custom_transmuted_hero", "heroes/alchemist/transmute.lua", LUA_MODIFIER_MOTION_NONE)

-- function alchemist_custom_transmute:OnHeroCalculateStatBonus()
  -- local caster = self:GetCaster()

  -- if caster:HasShardCustom() then
    -- self:SetHidden(false)
    -- if self:GetLevel() <= 0 then
      -- self:SetLevel(1)
    -- end
  -- else
    -- self:SetHidden(true)
    -- --self:SetLevel(0)
  -- end
-- end

function alchemist_custom_transmute:CastFilterResultTarget(target)
  local defaultFilterResult = self.BaseClass.CastFilterResultTarget(self, target)

  if target:IsRoshan() then
    return UF_FAIL_CUSTOM
  elseif target:IsCourier() then
    return UF_FAIL_COURIER
  end
  
  return defaultFilterResult
end

function alchemist_custom_transmute:GetCustomCastErrorTarget(target)
  if target:IsRoshan() then
    return "#dota_hud_error_cant_cast_on_roshan"
  end
end

function alchemist_custom_transmute:GetCooldown(level)
  local base_cooldown = self.BaseClass.GetCooldown(self, level)
  local cooldown_heroes = self:GetSpecialValueFor("cooldown_heroes")
  local cooldown_creeps = self:GetSpecialValueFor("cooldown_creeps")

  if IsServer() then
    local target = self:GetCursorTarget()
    if target and (target:IsHero() or target:IsConsideredHero()) then
      return cooldown_heroes
    elseif target then
      return cooldown_creeps
    end
  end

  return base_cooldown
end

function alchemist_custom_transmute:OnSpellStart()
  local caster = self:GetCaster()
  local target = self:GetCursorTarget()
  
  -- Don't continue if target and caster entities exist
  if not target or not caster then
    return
  end
  
  -- Sound
  target:EmitSound("DOTA_Item.Hand_Of_Midas")

  -- Don't continue if target has spell block
  if target:TriggerSpellAbsorb(self) then
    return
  end
  
  local stun_hero_duration = self:GetSpecialValueFor("stun_duration")
  local gold_bounty_multiplier = self:GetSpecialValueFor("gold_bounty_multiplier")

  if target:IsHero() or target:IsConsideredHero() then
    -- Target is a real hero, illusion of a hero or a hero creep.
    -- Take status resistance in mind
    stun_hero_duration = target:GetValueChangedByStatusResistance(stun_hero_duration)
    -- Apply spell effect
    target:AddNewModifier(caster, self, "modifier_custom_transmuted_hero", {duration = stun_hero_duration})
  else
    --local min_gold_bounty = target:GetMinimumGoldBounty()
    local max_gold_bounty = target:GetMaximumGoldBounty()
    --local new_gold_bounty = math.ceil((min_gold_bounty + max_gold_bounty) * 0.5 * gold_bounty_multiplier)
	local new_gold_bounty = math.ceil(max_gold_bounty * gold_bounty_multiplier)
    target:SetMinimumGoldBounty(new_gold_bounty)
    target:SetMaximumGoldBounty(new_gold_bounty)
    target:AddNoDraw()
    local particle_gold = ParticleManager:CreateParticle("particles/items2_fx/hand_of_midas.vpcf", PATTACH_CUSTOMORIGIN, nil)
    ParticleManager:SetParticleControlEnt(particle_gold, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(particle_gold, 1, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
    ParticleManager:ReleaseParticleIndex(particle_gold)

    target:Kill(self, caster) -- Kill the creep. This increments the caster's last hit counter.

    -- Message Particle, has a bunch of options
    local symbol = 0 -- "+" presymbol
    local color = Vector(255, 200, 33) -- Gold color
    local lifetime = 2
    local digits = string.len(new_gold_bounty) + 1
    local particleName = "particles/units/heroes/hero_alchemist/alchemist_lasthit_msg_gold.vpcf"
    local particle_message = ParticleManager:CreateParticle( particleName, PATTACH_ABSORIGIN, target)
    ParticleManager:SetParticleControl(particle_message, 1, Vector(symbol, new_gold_bounty, symbol))
    ParticleManager:SetParticleControl(particle_message, 2, Vector(lifetime, digits, 0))
    ParticleManager:SetParticleControl(particle_message, 3, color)
    ParticleManager:ReleaseParticleIndex(particle_message)
  end
end

function alchemist_custom_transmute:ProcsMagicStick()
  return true
end

function alchemist_custom_transmute:IsStealable()
  return true
end

---------------------------------------------------------------------------------------------------

modifier_custom_transmuted_hero = class({})

function modifier_custom_transmuted_hero:IsHidden()
  return false
end

function modifier_custom_transmuted_hero:IsDebuff()
  return true
end

function modifier_custom_transmuted_hero:IsStunDebuff()
  return true
end

function modifier_custom_transmuted_hero:IsPurgable()
  return true
end

function modifier_custom_transmuted_hero:CheckState()
  local state = {
    [MODIFIER_STATE_STUNNED] = true,
    [MODIFIER_STATE_FROZEN] = true,
  }

  return state
end

--function modifier_custom_transmuted_hero:GetEffectName()
  --return "particles/generic_gameplay/generic_stunned.vpcf"
--end

--function modifier_custom_transmuted_hero:GetEffectAttachType()
  --return PATTACH_OVERHEAD_FOLLOW
--end

function modifier_custom_transmuted_hero:GetStatusEffectName()
  return "particles/econ/items/effigies/status_fx_effigies/status_effect_effigy_gold_lvl2.vpcf"
end

function modifier_custom_transmuted_hero:StatusEffectPriority()
  return 12
end
