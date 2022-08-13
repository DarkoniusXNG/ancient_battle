lich_custom_dark_ritual = class({})

function lich_custom_dark_ritual:CastFilterResultTarget(hTarget)
  local caster = self:GetCaster()
  local caster_team = caster:GetTeamNumber()
  local has_talent = false

  -- Talent that allows targetting ancients and enemy units
  local talent = caster:FindAbilityByName("special_bonus_unique_lich_custom_2")
  if talent and talent:GetLevel() > 0 then
    has_talent = true
  end

  if hTarget:IsCreep() and not hTarget:IsConsideredHero() and not hTarget:IsCourier() and (not hTarget:IsAncient() or has_talent) and (hTarget:GetTeamNumber() == caster_team or has_talent) and not hTarget:IsMagicImmune() then
	return UF_SUCCESS
  end

  return UnitFilter(hTarget, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_CREEP, bit.bor(DOTA_UNIT_TARGET_FLAG_NOT_ANCIENTS, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_NOT_CREEP_HERO), caster_team)
end

function lich_custom_dark_ritual:OnSpellStart()
  local caster = self:GetCaster()
  local target = self:GetCursorTarget()
  local event = {}
  event.caster = caster
  event.target = target
  event.ability = self

  -- Sound
  caster:EmitSound("Hero_Lich.SinisterGaze.Cast")

  -- Particle
  local part = ParticleManager:CreateParticle("particles/units/heroes/hero_lich/lich_dark_ritual.vpcf", PATTACH_POINT_FOLLOW, target)
  ParticleManager:SetParticleControl(part, 0, caster:GetAbsOrigin())
  ParticleManager:SetParticleControl(part, 1, target:GetAbsOrigin())
  ParticleManager:ReleaseParticleIndex(part)

  -- Spell effect
  DarkRitual(event)
end

function lich_custom_dark_ritual:ProcsMagicStick()
  return true
end

-- Called OnSpellStart; doesn't give xp to anyone
function DarkRitual(event)
  local caster = event.caster
  local target = event.target
  local ability = event.ability

  local target_health = target:GetHealth()
  local hp_percent = ability:GetLevelSpecialValueFor("health_conversion", ability:GetLevel() - 1)
	
  local mana_gain = target_health*hp_percent*0.01

  caster:GiveMana(mana_gain)
  target:ForceKill(true)
end
