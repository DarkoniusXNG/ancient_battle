if perun_electric_trap == nil then
	perun_electric_trap = class({})
end

LinkLuaModifier("modifier_perun_electric_trap", "heroes/perun/electric_shield.lua", LUA_MODIFIER_MOTION_NONE) --LUA_MODIFIER_MOTION_HORIZONTAL

function perun_electric_trap:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function perun_electric_trap:OnSpellStart()
	if not IsServer() then
		return
	end

	local caster = self:GetCaster()
	local point = self:GetCursorPosition()

	if not point or not caster then
		return
	end

	

	
end

function perun_electric_trap:ProcsMagicStick()
	return true
end

if modifier_perun_electric_trap == nil then
	modifier_perun_electric_trap = class({})
end

function modifier_perun_electric_trap:IsHidden()
	return true
end

function modifier_perun_electric_trap:IsPurgable()
	return false
end

function modifier_perun_electric_trap:IsDebuff()
	return false
end

function modifier_perun_electric_trap:OnCreated()
	
end

function modifier_perun_electric_trap:OnRefresh()
	
end

function modifier_perun_electric_trap:OnIntervalThink()
	if not IsServer() then
		return
	end

end

function modifier_perun_electric_trap:OnDestroy()
	if not IsServer() then
		return
	end

end


