if dark_ranger_ranger_aura == nil then
	dark_ranger_ranger_aura = class({})
end

LinkLuaModifier("modifier_custom_ranger_aura_effect", "heroes/dark_ranger/ranger_aura.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_custom_ranger_aura_applier", "heroes/dark_ranger/ranger_aura.lua", LUA_MODIFIER_MOTION_NONE)

function dark_ranger_ranger_aura:IsStealable()
	return false
end

function dark_ranger_ranger_aura:GetIntrinsicModifierName()
	return "modifier_custom_ranger_aura_applier"
end

---------------------------------------------------------------------------------------------------

if modifier_custom_ranger_aura_applier == nil then
	modifier_custom_ranger_aura_applier = class({})
end

function modifier_custom_ranger_aura_applier:IsHidden()
	return true
end

function modifier_custom_ranger_aura_applier:IsPurgable()
	return false
end

function modifier_custom_ranger_aura_applier:IsAura()
	local parent = self:GetParent()
	if parent:PassivesDisabled() or parent:IsIllusion() then
		return false
	end
	return true
end

function modifier_custom_ranger_aura_applier:AllowIllusionDuplicate()
	return false
end

function modifier_custom_ranger_aura_applier:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT
end

function modifier_custom_ranger_aura_applier:GetModifierAura()
	return "modifier_custom_ranger_aura_effect"
end

function modifier_custom_ranger_aura_applier:GetAuraRadius()
	local ability = self:GetAbility()
	return ability:GetSpecialValueFor("radius")
end

function modifier_custom_ranger_aura_applier:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_custom_ranger_aura_applier:GetAuraSearchType()
	return bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC)
end

function modifier_custom_ranger_aura_applier:GetAuraSearchFlags()
	return DOTA_UNIT_TARGET_FLAG_RANGED_ONLY
end

---------------------------------------------------------------------------------------------------

if modifier_custom_ranger_aura_effect == nil then
	modifier_custom_ranger_aura_effect = class({})
end

function modifier_custom_ranger_aura_effect:IsHidden()
	return false
end

function modifier_custom_ranger_aura_effect:IsPurgable()
	return false
end

function modifier_custom_ranger_aura_effect:IsDebuff()
	return false
end

function modifier_custom_ranger_aura_effect:OnCreated()
	self.ability = self:GetAbility()
	self.caster = self:GetCaster()

	local agility = 0
	local percent = 0
	local attack_range = 0

	if self.ability then
		percent = self.ability:GetSpecialValueFor("agility_to_ranged_damage")
		attack_range = self.ability:GetSpecialValueFor("bonus_attack_range")
	end

	if self.caster then
		agility = self.caster:GetAgility()

        -- Talent that increases damage
		local talent1 = self.caster:FindAbilityByName("special_bonus_unique_dark_ranger_2")
		if talent1 and talent1:GetLevel() > 0 then
			percent = percent + talent1:GetSpecialValueFor("value")
		end
		
		-- Talent that provides attack range
		local talent2 = self.caster:FindAbilityByName("special_bonus_unique_dark_ranger_3")
		if talent2 and talent2:GetLevel() > 0 then
			attack_range = attack_range + talent2:GetSpecialValueFor("value")
		end
	end

	self.attack_range = attack_range
	self.bonus_damage = math.ceil(agility * percent / 100)
	
	self:StartIntervalThink(1)
end

function modifier_custom_ranger_aura_effect:OnRefresh()
	if not self.ability or self.ability:IsNull() then
		self.ability = self:GetAbility()
	end

	if not self.caster or self.caster:IsNull() then
		self.caster = self:GetCaster()
	end

	local agility = 0
	local percent = 0
	local attack_range = 0

	if self.ability then
		percent = self.ability:GetSpecialValueFor("agility_to_ranged_damage")
		attack_range = self.ability:GetSpecialValueFor("bonus_attack_range")
	end

	if self.caster then
		agility = self.caster:GetAgility()

        -- Talent that increases damage
		local talent1 = self.caster:FindAbilityByName("special_bonus_unique_dark_ranger_2")
		if talent1 and talent1:GetLevel() > 0 then
			percent = percent + talent1:GetSpecialValueFor("value")
		end
		
		-- Talent that provides attack range
		local talent2 = self.caster:FindAbilityByName("special_bonus_unique_dark_ranger_3")
		if talent2 and talent2:GetLevel() > 0 then
			attack_range = attack_range + talent2:GetSpecialValueFor("value")
		end
	end

	self.attack_range = attack_range
	self.bonus_damage = math.ceil(agility * percent / 100)
end

function modifier_custom_ranger_aura_effect:OnIntervalThink()
	self:ForceRefresh()
end

function modifier_custom_ranger_aura_effect:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
		MODIFIER_PROPERTY_TOOLTIP,
	}
end

function modifier_custom_ranger_aura_effect:GetModifierPreAttack_BonusDamage()
	if self:GetCaster():PassivesDisabled() then
		return 0
	end

	if self.bonus_damage then
		if self.bonus_damage ~= 0 then
			return self.bonus_damage
		else
			self:ForceRefresh()
		end
	else
		self:ForceRefresh()
	end

	return 0
end

function modifier_custom_ranger_aura_effect:GetModifierAttackRangeBonus()
	if self:GetParent():IsRangedAttacker() then
		return self.attack_range
	end

	return 0
end

function modifier_custom_ranger_aura_effect:OnTooltip()
	if self:GetCaster():PassivesDisabled() then
		return 0
	end
	return self.bonus_damage
end
