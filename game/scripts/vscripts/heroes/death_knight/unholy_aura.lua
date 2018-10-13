if death_knight_unholy_aura == nil then
	death_knight_unholy_aura = class({})
end

LinkLuaModifier("modifier_custom_unholy_aura_effect", "heroes/death_knight/modifier_custom_unholy_aura_effect.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_custom_unholy_aura_applier", "heroes/death_knight/modifier_custom_unholy_aura_applier.lua", LUA_MODIFIER_MOTION_NONE)

function death_knight_unholy_aura:IsStealable()
	return false
end

function death_knight_unholy_aura:GetIntrinsicModifierName()
	return "modifier_custom_unholy_aura_applier"
end

function death_knight_unholy_aura:ProcsMagicStick()
	return false
end
