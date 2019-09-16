if astral_trekker_pulverize == nil then
	astral_trekker_pulverize = class({})
end

LinkLuaModifier("modifier_pulverize_cleave", "heroes/astral_trekker/modifier_pulverize_cleave.lua", LUA_MODIFIER_MOTION_NONE)

function astral_trekker_pulverize:GetIntrinsicModifierName()
	return "modifier_pulverize_cleave"
end

function astral_trekker_pulverize:IsStealable()
	return false
end
