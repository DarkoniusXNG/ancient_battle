LinkLuaModifier("modifier_custom_ring_of_aquila_passives", "items/custom_ring_of_aquila.lua", LUA_MODIFIER_MOTION_NONE)

item_custom_ring_of_aquila = class({})

function item_custom_ring_of_aquila:GetIntrinsicModifierName()
	return "modifier_custom_ring_of_aquila_passives"
end

---------------------------------------------------------------------------------------------------

modifier_custom_ring_of_aquila_passives = class({})

function modifier_custom_ring_of_aquila_passives:IsHidden()
	return true
end

function modifier_custom_ring_of_aquila_passives:IsDebuff()
	return false
end

function modifier_custom_ring_of_aquila_passives:IsPurgable()
	return false
end

function modifier_custom_ring_of_aquila_passives:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_custom_ring_of_aquila_passives:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
	}
end

function modifier_custom_ring_of_aquila_passives:GetModifierPreAttack_BonusDamage()
	return self:GetAbility():GetSpecialValueFor("bonus_damage")
end

function modifier_custom_ring_of_aquila_passives:GetModifierConstantManaRegen()
	return self:GetAbility():GetSpecialValueFor("bonus_mana_regen")
end

function modifier_custom_ring_of_aquila_passives:GetModifierPhysicalArmorBonus()
	return self:GetAbility():GetSpecialValueFor("bonus_armor")
end

function modifier_custom_ring_of_aquila_passives:GetModifierBonusStats_Strength()
	return self:GetAbility():GetSpecialValueFor("bonus_strength")
end

function modifier_custom_ring_of_aquila_passives:GetModifierBonusStats_Agility()
	return self:GetAbility():GetSpecialValueFor("bonus_agility")
end

function modifier_custom_ring_of_aquila_passives:GetModifierBonusStats_Intellect()
	return self:GetAbility():GetSpecialValueFor("bonus_intellect")
end

function modifier_custom_ring_of_aquila_passives:GetModifierAttackSpeedBonus_Constant()
	return self:GetAbility():GetSpecialValueFor("bonus_attack_speed")
end
