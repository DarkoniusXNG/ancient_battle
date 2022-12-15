LinkLuaModifier("modifier_custom_poor_mans_shield_passives", "items/custom_poor_mans_shield.lua", LUA_MODIFIER_MOTION_NONE)

item_custom_poor_mans_shield = class({})

function item_custom_poor_mans_shield:GetIntrinsicModifierName()
	return "modifier_custom_poor_mans_shield_passives"
end

---------------------------------------------------------------------------------------------------

modifier_custom_poor_mans_shield_passives = class({})

function modifier_custom_poor_mans_shield_passives:IsHidden()
	return true
end

function modifier_custom_poor_mans_shield_passives:IsDebuff()
	return false
end

function modifier_custom_poor_mans_shield_passives:IsPurgable()
	return false
end

function modifier_custom_poor_mans_shield_passives:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_custom_poor_mans_shield_passives:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_PHYSICAL_CONSTANT_BLOCK
		--MODIFIER_EVENT_ON_TAKEDAMAGE
	}
end

function modifier_custom_poor_mans_shield_passives:GetModifierBonusStats_Agility()
	return self:GetAbility():GetSpecialValueFor("bonus_agility")
end
--[[ -- This is not good!
if IsServer() then
	function modifier_custom_poor_mans_shield_passives:OnTakeDamage(event)
		local parent = self:GetParent()
		local ability = self:GetAbility()
		local target = event.target
		local attacker = event.attacker

		if parent ~= target then
			return
		end

		if event.damage < 0 then
			return
		end

		if event.damage_type ~= DAMAGE_TYPE_PHYSICAL then
			return
		end

		if HasBit(event.damage_flags, DOTA_DAMAGE_FLAG_BYPASSES_BLOCK) then
			return
		end

		-- To prevent crashes:
		if not attacker then
			return
		end

		if attacker:IsNull() then
			return
		end

		local chance = ability:GetSpecialValueFor("block_chance")

		if ability:PseudoRandom(chance) then
			self.block_bool = true
		else
			self.block_bool = false
		end
	end
end
]]

function modifier_custom_poor_mans_shield_passives:GetModifierPhysical_ConstantBlock()
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
