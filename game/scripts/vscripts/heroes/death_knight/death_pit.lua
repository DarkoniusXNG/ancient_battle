death_knight_death_pit = death_knight_death_pit or class({})

LinkLuaModifier("modifier_death_knight_death_pit_effect", "heroes/death_knight/modifier_death_knight_death_pit_effect", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_death_knight_death_pit_thinker", "heroes/death_knight/modifier_death_knight_death_pit_thinker", LUA_MODIFIER_MOTION_NONE)

function death_knight_death_pit:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function death_knight_death_pit:OnSpellStart()
	local caster = self:GetCaster()

	CreateModifierThinker(caster, self, "modifier_death_knight_death_pit_thinker", {duration = self:GetSpecialValueFor("pit_duration")}, self:GetCursorPosition(), caster:GetTeamNumber(), false)
end

function death_knight_death_pit:ProcsMagicStick()
	return true
end
