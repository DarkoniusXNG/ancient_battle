LinkLuaModifier("modifier_custom_take_aim_passive", "heroes/dark_terminator/take_aim.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dark_terminator_attack_range_talent", "heroes/dark_terminator/take_aim.lua", LUA_MODIFIER_MOTION_NONE)

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

		if IsServer() then
			-- Talent that increases attack range
			local talent = parent:FindAbilityByName("special_bonus_unique_dark_terminator_take_aim")
			if talent then
				if talent:GetLevel() ~= 0 then
					bonus_range = bonus_range + talent:GetSpecialValueFor("value")
				end
			end
		else
			if parent:HasModifier("modifier_dark_terminator_attack_range_talent") then
				bonus_range = bonus_range + parent.take_aim_bonus_range_talent_value
			end
		end

		return bonus_range
	else
		return 0
	end
end

---------------------------------------------------------------------------------------------------

if modifier_dark_terminator_attack_range_talent == nil then
	modifier_dark_terminator_attack_range_talent = class({})
end

function modifier_dark_terminator_attack_range_talent:IsHidden()
    return true
end

function modifier_dark_terminator_attack_range_talent:IsPurgable()
    return false
end

function modifier_dark_terminator_attack_range_talent:AllowIllusionDuplicate() 
	return false
end

function modifier_dark_terminator_attack_range_talent:RemoveOnDeath()
    return false
end

function modifier_dark_terminator_attack_range_talent:OnCreated()
	if IsClient() then
		local parent = self:GetParent()
		local talent = self:GetAbility()
		local talent_value = talent:GetSpecialValueFor("value")
		parent.take_aim_bonus_range_talent_value = talent_value
	end
end
