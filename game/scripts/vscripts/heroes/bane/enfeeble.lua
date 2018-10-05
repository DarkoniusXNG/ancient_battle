if bane_custom_enfeeble == nil then
	bane_custom_enfeeble = class({})
end

LinkLuaModifier("modifier_custom_enfeeble_debuff", "heroes/bane/modifier_custom_enfeeble_debuff.lua", LUA_MODIFIER_MOTION_NONE)

function bane_custom_enfeeble:OnSpellStart()
	if IsServer() then
		local caster = self:GetCaster()
		local target = self:GetCursorTarget()

		if caster == nil or target == nil then
			return nil
		end

		-- Sound on caster
		caster:EmitSound("Hero_Bane.Enfeeble.Cast")

		-- Checking if target has spell block, if target has spell block, there is no need to execute the spell
		if not target:TriggerSpellAbsorb(self) then

			-- Sound on target
			target:EmitSound("Hero_Bane.Enfeeble")

			-- Apply debuff
			local enfeeble_duration = self:GetSpecialValueFor("duration")
			target:AddNewModifier(caster, self, "modifier_custom_enfeeble_debuff", {duration = enfeeble_duration})
		end
	end
end

function bane_custom_enfeeble:ProcsMagicStick()
	return true
end
