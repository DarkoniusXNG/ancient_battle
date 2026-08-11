axe_custom_counter_helix = class({})

LinkLuaModifier("modifier_custom_counter_helix_aura_applier", "heroes/axe/modifier_custom_counter_helix_aura_applier.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_custom_counter_helix_aura_effect", "heroes/axe/modifier_custom_counter_helix_aura_effect.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_custom_counter_helix_proc", "heroes/axe/modifier_custom_counter_helix_proc.lua", LUA_MODIFIER_MOTION_NONE)

function axe_custom_counter_helix:GetIntrinsicModifierName()
	return "modifier_custom_counter_helix_aura_applier"
end

function axe_custom_counter_helix:IsStealable()
	return false
end

function axe_custom_counter_helix:ShouldUseResources()
	return true
end
