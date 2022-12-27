if bane_custom_enfeeble == nil then
	bane_custom_enfeeble = class({})
end

LinkLuaModifier("modifier_custom_enfeeble_debuff", "heroes/bane/modifier_custom_enfeeble_debuff.lua", LUA_MODIFIER_MOTION_NONE)

function bane_custom_enfeeble:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	if not target or not caster then
		return
	end

	-- Sound on caster
	caster:EmitSound("Hero_Bane.Enfeeble.Cast")

	-- Check for spell block; pierces spell immunity
	if target:TriggerSpellAbsorb(self) then
		return
	end

	-- Sound on target
	target:EmitSound("Hero_Bane.Enfeeble")

	-- Apply debuff
	local enfeeble_duration = self:GetSpecialValueFor("duration")
	target:AddNewModifier(caster, self, "modifier_custom_enfeeble_debuff", {duration = enfeeble_duration})
end

function bane_custom_enfeeble:ProcsMagicStick()
	return true
end
