sandra_will_to_live = class({})

LinkLuaModifier( "modifier_sandra_will_to_live", "heroes/sandra/modifier_sandra_will_to_live", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_sandra_will_to_live_delay", "heroes/sandra/modifier_sandra_will_to_live_delay", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_sandra_will_to_live_threshold", "heroes/sandra/modifier_sandra_will_to_live_threshold", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------
-- Passive Modifier
function sandra_will_to_live:GetIntrinsicModifierName()
	return "modifier_sandra_will_to_live"
end
