if modifier_custom_enfeeble_debuff == nil then
	modifier_custom_enfeeble_debuff = class({})
end

function modifier_custom_enfeeble_debuff:IsHidden()
	return false
end

function modifier_custom_enfeeble_debuff:IsDebuff()
	return true
end

function modifier_custom_enfeeble_debuff:IsPurgable()
	return false
end

function modifier_custom_enfeeble_debuff:RemoveOnDeath()
	return true
end

function modifier_custom_enfeeble_debuff:OnCreated()
	local ability = self:GetAbility()
	self.attack_damage_reduction = ability:GetSpecialValueFor("attack_damage_reduction")
	self.spell_damage_reduction = ability:GetSpecialValueFor("spell_damage_reduction")
end

function modifier_custom_enfeeble_debuff:OnRefresh()
	local ability = self:GetAbility()
	self.attack_damage_reduction = ability:GetSpecialValueFor("attack_damage_reduction")
	self.spell_damage_reduction = ability:GetSpecialValueFor("spell_damage_reduction")
end

function modifier_custom_enfeeble_debuff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
		MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
		MODIFIER_PROPERTY_TOOLTIP
	}
end

function modifier_custom_enfeeble_debuff:GetModifierDamageOutgoing_Percentage()
	return self.attack_damage_reduction
end

function modifier_custom_enfeeble_debuff:GetModifierTotalDamageOutgoing_Percentage(event)
	local damaging_ability = event.inflictor
	if not damaging_ability or event.damage_category ~= DOTA_DAMAGE_CATEGORY_SPELL then
		return 0
	end
	if not damaging_ability:IsItem() then
		return 0 - math.abs(self.spell_damage_reduction)
	end
	return 0
end

function modifier_custom_enfeeble_debuff:OnTooltip()
	return math.abs(self.spell_damage_reduction)
end

function modifier_custom_enfeeble_debuff:GetEffectName()
	return "particles/units/heroes/hero_bane/bane_enfeeble.vpcf"
end

function modifier_custom_enfeeble_debuff:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end
