LinkLuaModifier("modifier_custom_take_aim_passive", "heroes/dark_terminator/take_aim.lua", LUA_MODIFIER_MOTION_NONE)

dark_terminator_take_aim = class({})

function dark_terminator_take_aim:GetIntrinsicModifierName()
	return "modifier_custom_take_aim_passive"
end

---------------------------------------------------------------------------------------------------

modifier_custom_take_aim_passive = class({})

function modifier_custom_take_aim_passive:IsHidden()
	return true
end

function modifier_custom_take_aim_passive:IsDebuff()
	return false
end

function modifier_custom_take_aim_passive:IsPurgable()
	return false
end

function modifier_custom_take_aim_passive:RemoveOnDeath()
	return false
end

function modifier_custom_take_aim_passive:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
	}
end

function modifier_custom_take_aim_passive:GetModifierAttackRangeBonus()
	local parent = self:GetParent()
	local ability = self:GetAbility()
	if not parent:PassivesDisabled() then
		local bonus_range = ability:GetSpecialValueFor("bonus_attack_range")

		-- Talent that increases attack range
		local talent = parent:FindAbilityByName("special_bonus_unique_dark_terminator_take_aim")
		if talent and talent:GetLevel() > 0 then
			bonus_range = bonus_range + talent:GetSpecialValueFor("value")
		end

		return bonus_range
	else
		return 0
	end
end
