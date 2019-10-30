sohei_wholeness_of_body = class({})

LinkLuaModifier("modifier_sohei_wholeness_of_body_status", "heroes/sohei/sohei_wholeness_of_body.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_sohei_wholeness_talent", "heroes/sohei/sohei_wholeness_of_body.lua", LUA_MODIFIER_MOTION_NONE)

function sohei_wholeness_of_body:GetBehavior()
	local caster = self:GetCaster()

	if IsServer() then
		-- Talent that changes targetting behavior
		local talent = caster:FindAbilityByName("special_bonus_sohei_wholeness_allycast")
		if talent then
			if talent:GetLevel() ~= 0 then
				return DOTA_ABILITY_BEHAVIOR_UNIT_TARGET
			end
		end
	else
		if caster:HasModifier("modifier_sohei_wholeness_talent") then
			return DOTA_ABILITY_BEHAVIOR_UNIT_TARGET
		end
	end

	return bit.bor(DOTA_ABILITY_BEHAVIOR_NO_TARGET, DOTA_ABILITY_BEHAVIOR_IMMEDIATE)
end
--------------------------------------------------------------------------------

function sohei_wholeness_of_body:CastFilterResultTarget( target )
  local default_result = self.BaseClass.CastFilterResultTarget(self, target)
  return default_result
end

function sohei_wholeness_of_body:OnSpellStart()
  local caster = self:GetCaster()
  local target = self:GetCursorTarget() or caster
  -- Activation sound
  target:EmitSound("Sohei.Guard")
  -- Strong Dispel
  target:Purge(false, true, false, true, false)
  -- Applying the buff
  target:AddNewModifier(caster, self, "modifier_sohei_wholeness_of_body_status", {duration = self:GetSpecialValueFor("sr_duration")})

	-- Knockback talent
	local talent = caster:FindAbilityByName("special_bonus_sohei_wholeness_knockback")
	if talent then
		if talent:GetLevel() ~= 0 then
			local position = target:GetAbsOrigin()
			local radius = talent:GetSpecialValueFor("value") 
			local team = caster:GetTeamNumber()
			local enemies = FindUnitsInRadius(team, position, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
			for _, enemy in ipairs( enemies ) do
				local modifierKnockback = {
					center_x = position.x,
					center_y = position.y,
					center_z = position.z,
					duration = talent:GetSpecialValueFor("duration"),
					knockback_duration = talent:GetSpecialValueFor("duration"),
					knockback_distance = radius - (position - enemy:GetAbsOrigin()):Length2D(),
				}
				enemy:AddNewModifier(caster, self, "modifier_knockback", modifierKnockback )
			end
		end
	end
end

--------------------------------------------------------------------------------

-- wholeness_of_body modifier
modifier_sohei_wholeness_of_body_status = class({})
--------------------------------------------------------------------------------

function modifier_sohei_wholeness_of_body_status:IsDebuff()
  return false
end

function modifier_sohei_wholeness_of_body_status:IsHidden()
  return false
end

function modifier_sohei_wholeness_of_body_status:IsPurgable()
  return true
end

--------------------------------------------------------------------------------

function modifier_sohei_wholeness_of_body_status:GetEffectName()
  return "particles/hero/sohei/guard.vpcf"
end

function modifier_sohei_wholeness_of_body_status:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_sohei_wholeness_of_body_status:OnCreated()
  local ability = self:GetAbility()
  self.status_resistance = ability:GetSpecialValueFor("status_resistance")
  self.damageheal = ability:GetSpecialValueFor("damage_taken_heal") / 100
  self.endHeal = 0
end

function modifier_sohei_wholeness_of_body_status:OnRefresh()
  local ability = self:GetAbility()
  self.status_resistance = ability:GetSpecialValueFor("status_resistance")
  self.damageheal = ability:GetSpecialValueFor("damage_taken_heal") / 100
end

function modifier_sohei_wholeness_of_body_status:OnDestroy()
  if IsServer() then
    self:GetParent():Heal(self.endHeal + self:GetAbility():GetSpecialValueFor("post_heal"), self:GetAbility())
  end
end

--------------------------------------------------------------------------------

function modifier_sohei_wholeness_of_body_status:DeclareFunctions()
  local funcs = {
  MODIFIER_PROPERTY_STATUS_RESISTANCE,
  MODIFIER_EVENT_ON_TAKEDAMAGE,
  }

  return funcs
end

function modifier_sohei_wholeness_of_body_status:GetModifierStatusResistance( )
  return self.status_resistance
end

function modifier_sohei_wholeness_of_body_status:OnTakeDamage( params )
  if params.unit == self:GetParent() then
    self.endHeal = self.endHeal + params.damage * self.damageheal
  end
end

if modifier_sohei_wholeness_talent == nil then
  modifier_sohei_wholeness_talent = class({})
end

function modifier_sohei_wholeness_talent:IsHidden()
  return true
end

function modifier_sohei_wholeness_talent:IsPurgable()
  return false
end

function modifier_sohei_wholeness_talent:AllowIllusionDuplicate()
	return false
end

function modifier_sohei_wholeness_talent:RemoveOnDeath()
  return false
end
