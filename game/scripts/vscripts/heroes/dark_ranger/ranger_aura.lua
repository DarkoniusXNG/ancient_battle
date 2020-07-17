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
	self.bonus_damage = 0
	self.percent = 0
	self.agility = 0
	if self.ability then
		self.percent = self.ability:GetSpecialValueFor("agility_to_ranged_damage")
	end
	if self.caster then
		self.agility = self.caster:GetAgility()
	end

	self.bonus_damage = math.ceil((self.agility)*(self.percent)/100)
	
	self:StartIntervalThink(1)
end

function modifier_custom_ranger_aura_effect:OnRefresh()
	if not self.ability or self.ability:IsNull() then
		self.ability = self:GetAbility()
	end
	if not self.caster or self.caster:IsNull() then
		self.caster = self:GetCaster()
	end
	if self.ability then
		self.percent = self.ability:GetSpecialValueFor("agility_to_ranged_damage")
	end
	if self.caster then
		self.agility = self.caster:GetAgility()
	end

	self.bonus_damage = math.ceil((self.agility)*(self.percent)/100)
end

function modifier_custom_ranger_aura_effect:OnIntervalThink()
	self:ForceRefresh()
end

function modifier_custom_ranger_aura_effect:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_TOOLTIP
	}
end

function modifier_custom_ranger_aura_effect:GetModifierPreAttack_BonusDamage()
	if self.bonus_damage then
		return self.bonus_damage
	else
		self:ForceRefresh()
	end

	return 0
end

function modifier_custom_ranger_aura_effect:OnTooltip()
	return self.bonus_damage
end
