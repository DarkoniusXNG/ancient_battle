if silencer_custom_curse_of_the_silent == nil then
	silencer_custom_curse_of_the_silent = class({})
end

LinkLuaModifier("modifier_custom_curse_of_the_silent", "heroes/silencer/modifier_custom_curse_of_the_silent.lua", LUA_MODIFIER_MOTION_NONE)

function silencer_custom_curse_of_the_silent:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function silencer_custom_curse_of_the_silent:IsStealable()
	return true
end

function silencer_custom_curse_of_the_silent:IsHiddenWhenStolen()
	return false
end

function silencer_custom_curse_of_the_silent:OnSpellStart()
	local caster = self:GetCaster()
	local position = self:GetCursorPosition()

	local duration = self:GetSpecialValueFor("duration")
	local radius = self:GetSpecialValueFor("radius")

	if not position or not caster then
		return
	end

	-- Sound from caster
	caster:EmitSound("Hero_Silencer.Curse.Cast")

	-- Particle in AoE
	local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_silencer/silencer_curse_aoe.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(particle, 0, position)
	ParticleManager:SetParticleControl(particle, 1, Vector(radius, 0, 0))
	ParticleManager:ReleaseParticleIndex(particle)

	-- Targetting constants
	local target_team = self:GetAbilityTargetTeam() or DOTA_UNIT_TARGET_TEAM_ENEMY
	local target_type = self:GetAbilityTargetType() or bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
	local target_flags = self:GetAbilityTargetFlags() or DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE

	local caster_team = caster:GetTeamNumber()

	local enemies = FindUnitsInRadius(caster_team, position, nil, radius, target_team, target_type, target_flags, FIND_ANY_ORDER, false)
	for _, enemy in pairs(enemies) do
		if enemy then
			enemy:AddNewModifier(caster, self, "modifier_custom_curse_of_the_silent", {duration = duration})
		end
	end
end

function silencer_custom_curse_of_the_silent:ProcsMagicStick()
	return true
end
