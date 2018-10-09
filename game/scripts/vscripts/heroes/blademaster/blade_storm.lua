if blademaster_blade_storm == nil then
	blademaster_blade_storm = class({})
end

LinkLuaModifier("modifier_custom_blade_storm", "heroes/blademaster/modifier_custom_blade_storm.lua", LUA_MODIFIER_MOTION_NONE)

function blademaster_blade_storm:OnSpellStart()
	if IsServer() then
		local caster = self:GetCaster()

		if caster == nil then
			return nil
		end

		-- Basic Dispel
		caster:Purge(false, true, false, false, false)

		-- Apply the buff
		local blade_storm_duration = self:GetSpecialValueFor("duration")
		caster:AddNewModifier(caster, self, "modifier_custom_blade_storm", {duration = blade_storm_duration})
	end
end

function blademaster_blade_storm:ProcsMagicStick()
	return true
end
