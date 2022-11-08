if modifier_custom_unholy_aura_effect == nil then
	modifier_custom_unholy_aura_effect = class({})
end

function modifier_custom_unholy_aura_effect:IsHidden()
	return false
end

function modifier_custom_unholy_aura_effect:IsPurgable()
	return false
end

function modifier_custom_unholy_aura_effect:IsDebuff()
	return false
end

function modifier_custom_unholy_aura_effect:OnCreated()
	local ability = self:GetAbility()
	self.bonus_hp_regen = ability:GetSpecialValueFor("aura_health_regen_bonus")
	self.bonus_move_speed = ability:GetSpecialValueFor("aura_move_speed_bonus")
end

function modifier_custom_unholy_aura_effect:OnRefresh()
	local ability = self:GetAbility()
	if ability and not ability:IsNull() then
		self.bonus_hp_regen = ability:GetSpecialValueFor("aura_health_regen_bonus")
		self.bonus_move_speed = ability:GetSpecialValueFor("aura_move_speed_bonus")
	end
end

function modifier_custom_unholy_aura_effect:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
end

function modifier_custom_unholy_aura_effect:GetModifierConstantHealthRegen()
	local caster = self:GetCaster()
	if caster:IsNull() or caster:PassivesDisabled() then
		return 0
	end

	return self.bonus_hp_regen
end

function modifier_custom_unholy_aura_effect:GetModifierMoveSpeedBonus_Percentage()
	local caster = self:GetCaster()
	if caster:IsNull() or caster:PassivesDisabled() then
		return 0
	end

	return self.bonus_move_speed
end
