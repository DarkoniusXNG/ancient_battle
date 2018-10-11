if alchemist_custom_chemical_rage == nil then
	alchemist_custom_chemical_rage = class({})
end

LinkLuaModifier("modifier_custom_chemical_rage_buff", "heroes/alchemist/modifier_custom_chemical_rage_buff.lua", LUA_MODIFIER_MOTION_NONE)

function alchemist_custom_chemical_rage:OnSpellStart()
	if IsServer() then
		local caster = self:GetCaster()

		if caster == nil then
			return nil
		end

		-- Basic Dispel
		caster:Purge(false, true, false, false, false)
		
		-- Sound
		caster:EmitSound("Hero_Alchemist.ChemicalRage.Cast")

		-- Applying the built-in modifier that controls the animations, sounds and body transformation.
		-- The modifier_alchemist_chemical_rage tooltip needs to be adjusted
		local transform_duration = self:GetSpecialValueFor("transformation_time")
		caster:AddNewModifier(caster, self, "modifier_alchemist_chemical_rage_transform", {duration = transform_duration})

		-- Apply the real buff
		local buff_duration = self:GetSpecialValueFor("duration")
		caster:AddNewModifier(caster, self, "modifier_custom_chemical_rage_buff", {duration = buff_duration})
	end
end

function alchemist_custom_chemical_rage:ProcsMagicStick()
	return true
end
