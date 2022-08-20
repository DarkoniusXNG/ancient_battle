if modifier_custom_chemical_rage_buff == nil then
	modifier_custom_chemical_rage_buff = class({})
end

function modifier_custom_chemical_rage_buff:IsHidden()
	return true
end

function modifier_custom_chemical_rage_buff:IsDebuff()
	return false
end

function modifier_custom_chemical_rage_buff:IsPurgable()
	return false
end

function modifier_custom_chemical_rage_buff:AllowIllusionDuplicate()
	return false
end

function modifier_custom_chemical_rage_buff:RemoveOnDeath()
	return true
end

function modifier_custom_chemical_rage_buff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_BASE_ATTACK_TIME_CONSTANT,
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
		MODIFIER_PROPERTY_IGNORE_MOVESPEED_LIMIT,
	}
end

function modifier_custom_chemical_rage_buff:OnCreated()
	local parent = self:GetParent()
	local ability = self:GetAbility()

	local think_interval = ability:GetSpecialValueFor("think_interval")
	local base_attack_time = ability:GetSpecialValueFor("custom_base_attack_time")

	self.bonus_move_speed = ability:GetSpecialValueFor("custom_bonus_move_speed")
	self.bonus_hp_regen = ability:GetSpecialValueFor("custom_bonus_health_regen")
	self.bonus_mana_regen = ability:GetSpecialValueFor("custom_bonus_mana_regen")

	-- Talent that reduces BAT
	local talent = parent:FindAbilityByName("special_bonus_unique_alchemist_custom_1")
	if talent and talent:GetLevel() > 0 then
		base_attack_time = base_attack_time - math.abs(talent:GetSpecialValueFor("value"))
	end

	self.base_attack_time = base_attack_time

	if IsServer() then
		-- Start thinking
		self:StartIntervalThink(think_interval)
	end
end

function modifier_custom_chemical_rage_buff:OnRefresh()
	local parent = self:GetParent()
	local ability = self:GetAbility()

	local base_attack_time = ability:GetSpecialValueFor("custom_base_attack_time")

	self.bonus_move_speed = ability:GetSpecialValueFor("custom_bonus_move_speed")
	self.bonus_hp_regen = ability:GetSpecialValueFor("custom_bonus_health_regen")
	self.bonus_mana_regen = ability:GetSpecialValueFor("custom_bonus_mana_regen")

	-- Talent that reduces BAT
	local talent = parent:FindAbilityByName("special_bonus_unique_alchemist_custom_1")
	if talent and talent:GetLevel() > 0 then
		base_attack_time = base_attack_time - math.abs(talent:GetSpecialValueFor("value"))
	end

	self.base_attack_time = base_attack_time
end

function modifier_custom_chemical_rage_buff:OnIntervalThink()
	local parent = self:GetParent()
	if IsServer() and parent then
		if parent:HasScepter() then
			-- If parent picked up scepter or had it while modifier is still on him
			self:ScepterBuff(parent)
		else
			-- If parent dropped scepter while modifier is still on him
			self:ScepterBuffEnd(parent)
		end
	end
end

function modifier_custom_chemical_rage_buff:OnDestroy()
	local parent = self:GetParent()
	if IsServer() and parent then
		self:ScepterBuffEnd(parent)
	end
end

function modifier_custom_chemical_rage_buff:GetModifierMoveSpeedBonus_Percentage()
	return self.bonus_move_speed
end

function modifier_custom_chemical_rage_buff:GetModifierBaseAttackTimeConstant()
	return self.base_attack_time
end

function modifier_custom_chemical_rage_buff:GetModifierConstantHealthRegen()
	return self.bonus_hp_regen
end

function modifier_custom_chemical_rage_buff:GetModifierConstantManaRegen()
	return self.bonus_mana_regen
end

-- Adds all base intelligence to base strength.
function modifier_custom_chemical_rage_buff:ScepterBuff(caster)
	if caster:IsRealHero() then
		local intelligence_old = caster:GetBaseIntellect()
		local strength_old = caster:GetBaseStrength()

		if (caster.old_strength == nil) and (caster.old_level == nil) then
			-- This will happen only when the modifier is created
			caster.old_strength = strength_old
			caster.old_level = caster:GetLevel()
		end
		if intelligence_old > 1 then
			local intelligence_new = 1
			local strength_new = strength_old + intelligence_old - 1
			caster:SetBaseIntellect(intelligence_new)
			caster:SetBaseStrength(strength_new)
			caster:CalculateStatBonus(true)  -- This is needed to update Caster's bonuses from stats
		end
	end	
end

-- Reverts everything back if needed
function modifier_custom_chemical_rage_buff:ScepterBuffEnd(caster)
	if caster:IsRealHero() and caster.old_strength and caster.old_level then
		local level = caster:GetLevel()
		local strength_gain = caster:GetStrengthGain()

		local strength_old = caster.old_strength
		local level_old = caster.old_level
		caster.old_strength = nil
		caster.old_level = nil

		local level_difference = level - level_old -- caster can level up during the duration of the modifier
		local strength_new = strength_old + level_difference*strength_gain
		local intelligence_new = caster:GetBaseStrength() - strength_new + 1
		
		caster:SetBaseIntellect(intelligence_new)
		caster:SetBaseStrength(strength_new)
		caster:CalculateStatBonus(true)
	end
end

function modifier_custom_chemical_rage_buff:GetModifierIgnoreMovespeedLimit()
	return 1
end
