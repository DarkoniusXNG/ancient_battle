paladin_holy_strike = paladin_holy_strike or class({})

LinkLuaModifier("modifier_holy_strike_passive", "heroes/paladin/modifier_holy_strike_passive.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_holy_strike_passive_weapon_effect", "heroes/paladin/modifier_holy_strike_passive_weapon_effect.lua", LUA_MODIFIER_MOTION_NONE)

function paladin_holy_strike:GetIntrinsicModifierName()
	return "modifier_holy_strike_passive"
end

function paladin_holy_strike:CastFilterResultTarget(target)
	local default_result = self.BaseClass.CastFilterResultTarget(self, target)

	if target:IsCustomWardTypeUnit() then
		return UF_FAIL_CUSTOM
	end

	return default_result
end

function paladin_holy_strike:GetCustomCastErrorTarget(target)
	if target:IsCustomWardTypeUnit() then
		return "#dota_hud_error_cant_cast_on_other"
	end
	return ""
end

function paladin_holy_strike:ShouldUseResources()
	return true
end

function paladin_holy_strike:OnUpgrade()
	-- First point to the ability
	if self:GetLevel() == 1 then
		-- Turn on autocast when the ability is leveled-up for the first time
		if not self:GetAutoCastState() then
			self:ToggleAutoCast()
		end
	end
end

function paladin_holy_strike:IsStealable()
	return false
end
