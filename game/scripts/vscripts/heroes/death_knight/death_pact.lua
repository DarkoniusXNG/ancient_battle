if death_knight_death_pact == nil then
	death_knight_death_pact = class({})
end

LinkLuaModifier("modifier_custom_death_pact", "heroes/death_knight/death_pact.lua", LUA_MODIFIER_MOTION_NONE)

function death_knight_death_pact:CastFilterResultTarget(target)
	local default_result = self.BaseClass.CastFilterResultTarget(self, target)

	if target:IsCustomWardTypeUnit() then
		return UF_FAIL_CUSTOM
	end

	return default_result
end

function death_knight_death_pact:GetCustomCastErrorTarget(target)
	if target:IsCustomWardTypeUnit() then
		return "#dota_hud_error_cant_cast_on_other"
	end
	return ""
end

function death_knight_death_pact:OnSpellStart()
  local caster = self:GetCaster()
  local target = self:GetCursorTarget()
  local duration = self:GetSpecialValueFor("duration")

  -- Talent that increases duration
  local talent_1 = caster:FindAbilityByName("special_bonus_unique_death_knight_2")
  if talent_1 and talent_1:GetLevel() > 0 then
    duration = duration + talent_1:GetSpecialValueFor("value")
  end

  -- get the target's current health
  local target_health = target:GetHealth()

  -- kill the target
  target:Kill(self, caster)

  -- get KV variables
  local healthPct = self:GetSpecialValueFor("health_gain_pct")
  local damagePct = self:GetSpecialValueFor("damage_gain_pct")

  -- Talent that increases hp and dmg gain
  local talent_2 = caster:FindAbilityByName("special_bonus_unique_death_knight_3")
  if talent_2 and talent_2:GetLevel() > 0 then
    healthPct = healthPct + talent_2:GetSpecialValueFor("value")
    damagePct = damagePct + talent_2:GetSpecialValueFor("value2")
  end

  -- Calculate bonuses
  local health = target_health * healthPct * 0.01
  local damage = target_health * damagePct * 0.01

  -- apply the new modifier which actually provides the stats
  -- then set its stack count to the amount of health the target had
  local modifier = caster:AddNewModifier(caster, self, "modifier_custom_death_pact", {duration = duration, health = health})
  modifier:SetStackCount(damage)

  -- play the sounds
  caster:EmitSound("Hero_Clinkz.DeathPact.Cast")
  target:EmitSound("Hero_Clinkz.DeathPact")

  -- Particle
  local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_clinkz/clinkz_death_pact.vpcf", PATTACH_ABSORIGIN, target)
  ParticleManager:SetParticleControlEnt(particle, 1, caster, PATTACH_ABSORIGIN, "", caster:GetAbsOrigin(), true)
  ParticleManager:ReleaseParticleIndex(particle)
end

--------------------------------------------------------------------------------

if modifier_custom_death_pact == nil then
	modifier_custom_death_pact = class({})
end

function modifier_custom_death_pact:IsHidden()
	return false
end

function modifier_custom_death_pact:IsDebuff()
	return false
end

function modifier_custom_death_pact:IsPurgable()
	return false
end

-- It's not called Death Pact for nothing
function modifier_custom_death_pact:RemoveOnDeath()
	return false
end

function modifier_custom_death_pact:OnCreated(event)
  local parent = self:GetParent()
  local ability = self:GetAbility()

  -- this has to be done server-side because valve
  if IsServer() then
    self.health = event.health

    -- apply the new health and such
    parent:CalculateStatBonus(true)

    -- add the added health
    parent:Heal(event.health, ability)
  end
end

function modifier_custom_death_pact:OnRefresh(event)
  self:OnCreated(event)
end

function modifier_custom_death_pact:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_BASEATTACK_BONUSDAMAGE,
		MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
	}
end

function modifier_custom_death_pact:GetModifierBaseAttack_BonusDamage()
  return self:GetStackCount()
end

function modifier_custom_death_pact:GetModifierExtraHealthBonus()
  return self.health
end

function modifier_custom_death_pact:GetEffectName()
  return "particles/units/heroes/hero_clinkz/clinkz_death_pact_buff.vpcf"
end

function modifier_custom_death_pact:GetEffectAttachType()
  return PATTACH_POINT_FOLLOW
end
