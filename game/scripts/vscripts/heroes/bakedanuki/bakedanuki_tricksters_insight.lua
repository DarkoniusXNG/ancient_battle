bakedanuki_tricksters_insight = class({})

LinkLuaModifier( "modifier_bakedanuki_tricksters_insight", "heroes/bakedanuki/modifier_bakedanuki_tricksters_insight", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_bakedanuki_tricksters_insight_passive", "heroes/bakedanuki/modifier_bakedanuki_tricksters_insight_passive", LUA_MODIFIER_MOTION_NONE )

function bakedanuki_tricksters_insight:OnSpellStart()
	-- unit identifier
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	if target:TriggerSpellAbsorb( self ) then
		return
	end

	-- load data
	local duration = self:GetSpecialValueFor("crit_duration")

	-- Add modifiers
	caster:AddNewModifier(caster, self, "modifier_bakedanuki_tricksters_insight_passive", {duration = duration})
	target:AddNewModifier(caster, self, "modifier_bakedanuki_tricksters_insight", {duration = duration})

	self:PlayEffects( target )
end

function bakedanuki_tricksters_insight:PlayEffects( target )
	-- Get Resources
	local sound_cast = "Hero_DarkWillow.Shadow_Realm.Damage"

	target:EmitSound(sound_cast)
end
