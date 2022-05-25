LinkLuaModifier("modifier_custom_bracer_passives", "items/bracer_old.lua", LUA_MODIFIER_MOTION_NONE)

item_bracer_old = class({})

function item_bracer_old:GetIntrinsicModifierName()
	return "modifier_custom_bracer_passives"
end

---------------------------------------------------------------------------------------------------

modifier_custom_bracer_passives = class({})

function modifier_custom_bracer_passives:IsHidden()
	return true
end

function modifier_custom_bracer_passives:IsDebuff()
	return false
end

function modifier_custom_bracer_passives:IsPurgable()
	return false
end

function modifier_custom_bracer_passives:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_custom_bracer_passives:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
	}
end

function modifier_custom_bracer_passives:GetModifierBonusStats_Strength()
	return self:GetAbility():GetSpecialValueFor("bonus_strength")
end

function modifier_custom_bracer_passives:GetModifierBonusStats_Agility()
	return self:GetAbility():GetSpecialValueFor("bonus_agility")
end

function modifier_custom_bracer_passives:GetModifierBonusStats_Intellect()
	return self:GetAbility():GetSpecialValueFor("bonus_intellect")
end
