bakedanuki_frolic_aura = class({})

LinkLuaModifier( "modifier_bakedanuki_frolic_aura", "heroes/bakedanuki/modifier_bakedanuki_frolic_aura", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_bakedanuki_frolic_aura_effect", "heroes/bakedanuki/modifier_bakedanuki_frolic_aura_effect", LUA_MODIFIER_MOTION_NONE )

function bakedanuki_frolic_aura:GetIntrinsicModifierName()
	return "modifier_bakedanuki_frolic_aura"
end
