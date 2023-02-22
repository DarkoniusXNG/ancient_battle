if blademaster_blade_storm == nil then
	blademaster_blade_storm = class({})
end

LinkLuaModifier("modifier_custom_blade_storm", "heroes/blademaster/modifier_custom_blade_storm.lua", LUA_MODIFIER_MOTION_NONE)

function blademaster_blade_storm:OnSpellStart()
	local caster = self:GetCaster()

	-- Basic Dispel
	caster:Purge(false, true, false, false, false)

	-- Apply the buff
	local blade_storm_duration = self:GetSpecialValueFor("duration")
	if caster:HasShardCustom() then
		blade_storm_duration = self:GetSpecialValueFor("shard_duration")
	end
	caster:AddNewModifier(caster, self, "modifier_custom_blade_storm", {duration = blade_storm_duration})
end

function blademaster_blade_storm:ProcsMagicStick()
	return true
end
