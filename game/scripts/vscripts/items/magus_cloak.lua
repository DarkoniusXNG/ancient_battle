LinkLuaModifier("modifier_custom_magus_cloak_passives", "items/magus_cloak.lua", LUA_MODIFIER_MOTION_NONE)

item_custom_magus_cloak = class({})

function item_custom_magus_cloak:GetIntrinsicModifierName()
	return "modifier_custom_magus_cloak_passives"
end

---------------------------------------------------------------------------------------------------

modifier_custom_magus_cloak_passives = class({})

function modifier_custom_magus_cloak_passives:IsHidden()
	return true
end

function modifier_custom_magus_cloak_passives:IsDebuff()
	return false
end

function modifier_custom_magus_cloak_passives:IsPurgable()
	return false
end

function modifier_custom_magus_cloak_passives:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_custom_magus_cloak_passives:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
		MODIFIER_PROPERTY_CAST_RANGE_BONUS_STACKING,
	}
end

function modifier_custom_magus_cloak_passives:GetModifierPreAttack_BonusDamage()
	return self:GetAbility():GetSpecialValueFor("bonus_damage")
end

function modifier_custom_magus_cloak_passives:GetModifierConstantManaRegen()
	return self:GetAbility():GetSpecialValueFor("bonus_mana_regen")
end

function modifier_custom_magus_cloak_passives:GetModifierBonusStats_Strength()
	return self:GetAbility():GetSpecialValueFor("bonus_strength")
end

function modifier_custom_magus_cloak_passives:GetModifierBonusStats_Agility()
	return self:GetAbility():GetSpecialValueFor("bonus_agility")
end

function modifier_custom_magus_cloak_passives:GetModifierBonusStats_Intellect()
	return self:GetAbility():GetSpecialValueFor("bonus_intellect")
end

function modifier_custom_magus_cloak_passives:GetModifierSpellAmplify_Percentage()
	return self:GetAbility():GetSpecialValueFor("bonus_spell_amp")
end

function modifier_custom_magus_cloak_passives:GetModifierCastRangeBonusStacking()
	return self:GetAbility():GetSpecialValueFor("bonus_cast_range")
end
