LinkLuaModifier("modifier_custom_stout_shield_passive", "items/custom_stout_shield.lua", LUA_MODIFIER_MOTION_NONE)

item_custom_stout_shield = class({})

function item_custom_stout_shield:GetIntrinsicModifierName()
	return "modifier_custom_stout_shield_passive"
end

---------------------------------------------------------------------------------------------------

modifier_custom_stout_shield_passive = class({})

function modifier_custom_stout_shield_passive:IsHidden()
	return true
end

function modifier_custom_stout_shield_passive:IsDebuff()
	return false
end

function modifier_custom_stout_shield_passive:IsPurgable()
	return false
end

function modifier_custom_stout_shield_passive:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_custom_stout_shield_passive:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_PHYSICAL_CONSTANT_BLOCK
	}
end

function modifier_custom_stout_shield_passive:GetModifierPhysical_ConstantBlock()
	local parent = self:GetParent()
	local ability = self:GetAbility()
	local chance = ability:GetSpecialValueFor("block_chance")

	if IsServer() then
		if ability:PseudoRandom(chance) then
			if parent:IsRangedAttacker() then
				return ability:GetSpecialValueFor("damage_block_ranged")
			else
				return ability:GetSpecialValueFor("damage_block_melee")
			end
		end
	end

	return 0
end
