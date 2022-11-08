LinkLuaModifier("modifier_custom_lifestealer_poison_sting", "heroes/lifestealer/poison_sting.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_custom_lifestealer_poison_sting_debuff", "heroes/lifestealer/poison_sting.lua", LUA_MODIFIER_MOTION_NONE)

life_stealer_custom_poison_sting = class({})

function life_stealer_custom_poison_sting:GetIntrinsicModifierName()
	return "modifier_custom_lifestealer_poison_sting"
end

---------------------------------------------------------------------------------------------------

modifier_custom_lifestealer_poison_sting = class({})

function modifier_custom_lifestealer_poison_sting:IsHidden()
	return true
end

function modifier_custom_lifestealer_poison_sting:IsPurgable()
	return false
end

function modifier_custom_lifestealer_poison_sting:IsDebuff()
	return false
end

function modifier_custom_lifestealer_poison_sting:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end

if IsServer() then
	function modifier_custom_lifestealer_poison_sting:OnAttackLanded(event)
		local parent = self:GetParent()
		local ability = self:GetAbility()
		local attacker = event.attacker
		local target = event.target

		-- Check if parent is affected by Break
		if parent:PassivesDisabled() then
			return
		end

		-- Check if attacker exists
		if not attacker or attacker:IsNull() then
			return
		end

		-- Check if attacker has this modifier
		if attacker ~= parent then
			return
		end

		-- Check if attacked entity exists
		if not target or target:IsNull() then
			return
		end

		-- Check if attacked entity can gain modifiers
		if target.HasModifier == nil then
			return
		end

		-- Don't affect buildings, wards, invulnerable units and spell-immune units.
		if target:IsTower() or target:IsBarracks() or target:IsBuilding() or target:IsOther() or target:IsInvulnerable() or target:IsMagicImmune() then
			return
		end
		
		target:AddNewModifier(parent, ability, "modifier_custom_lifestealer_poison_sting_debuff", {duration = ability:GetSpecialValueFor("duration")})
	end
end

---------------------------------------------------------------------------------------------------

modifier_custom_lifestealer_poison_sting_debuff = class({})

function modifier_custom_lifestealer_poison_sting_debuff:IsHidden() -- needs tooltip
	return false
end

function modifier_custom_lifestealer_poison_sting_debuff:IsPurgable()
	return true
end

function modifier_custom_lifestealer_poison_sting_debuff:IsDebuff()
	return true
end

function modifier_custom_lifestealer_poison_sting_debuff:GetEffectName()
	return "particles/units/heroes/hero_venomancer/venomancer_poison_debuff.vpcf"
end

function modifier_custom_lifestealer_poison_sting_debuff:OnCreated()
	local parent = self:GetParent()
	local ability = self:GetAbility()
	if ability and not ability:IsNull() then
		local movement_slow = ability:GetSpecialValueFor("move_speed_slow")
		self.dps = ability:GetSpecialValueFor("damage")
		self.heal_reduction	= ability:GetSpecialValueFor("heal_reduction")
		if IsServer() then
			-- Slow is reduced with Status Resistance
			self.slow = parent:GetValueChangedByStatusResistance(movement_slow)
		else
			self.slow = movement_slow
		end
	end
	
	if IsServer() then
		self.interval = 0.25
	
		self:OnIntervalThink()
		self:StartIntervalThink(self.interval)
	end
end

function modifier_custom_lifestealer_poison_sting_debuff:OnRefresh()
	self:OnCreated()
end

function modifier_custom_lifestealer_poison_sting_debuff:OnIntervalThink()
	local parent = self:GetParent()
	local caster = self:GetCaster()
	
	-- Don't apply damage if source doesn't exist or an illusion
	if caster:IsNull() or caster:IsIllusion() then
		return
	end
	
	local damage_per_interval = self.dps * self.interval

	ApplyDamage({
		victim = parent,
		damage = damage_per_interval,
		damage_type = DAMAGE_TYPE_MAGICAL,
		--damage_flags = DOTA_DAMAGE_FLAG_HPLOSS,
		attacker = caster,
		ability = self:GetAbility()
	})
	
	SendOverheadEventMessage(caster, OVERHEAD_ALERT_BONUS_POISON_DAMAGE, parent, damage_per_interval, nil)
end

function modifier_custom_lifestealer_poison_sting_debuff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
		MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET,
		MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE,
		MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE,
	}
end

function modifier_custom_lifestealer_poison_sting_debuff:GetModifierMoveSpeedBonus_Percentage()
	return self.slow
end

function modifier_custom_lifestealer_poison_sting_debuff:GetModifierHPRegenAmplify_Percentage()
  if self.heal_reduction then
    return 0 - math.abs(self.heal_reduction)
  end

  return 0
end

function modifier_custom_lifestealer_poison_sting_debuff:GetModifierHealAmplify_PercentageTarget()
  if self.heal_reduction then
    return 0 - math.abs(self.heal_reduction)
  end

  return 0
end

function modifier_custom_lifestealer_poison_sting_debuff:GetModifierLifestealRegenAmplify_Percentage()
  if self.heal_reduction then
    return 0 - math.abs(self.heal_reduction)
  end

  return 0
end

function modifier_custom_lifestealer_poison_sting_debuff:GetModifierSpellLifestealRegenAmplify_Percentage()
  if self.heal_reduction then
    return 0 - math.abs(self.heal_reduction)
  end

  return 0
end
