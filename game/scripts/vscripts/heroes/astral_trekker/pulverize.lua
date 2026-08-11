astral_trekker_pulverize = astral_trekker_pulverize or class({})

LinkLuaModifier("modifier_pulverize_cleave", "heroes/astral_trekker/modifier_pulverize_cleave.lua", LUA_MODIFIER_MOTION_NONE)

function astral_trekker_pulverize:GetIntrinsicModifierName()
	return "modifier_pulverize_cleave"
end

function astral_trekker_pulverize:IsStealable()
	return false
end
