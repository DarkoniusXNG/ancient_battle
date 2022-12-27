bakedanuki_tricksters_insight = class({})

LinkLuaModifier( "modifier_bakedanuki_tricksters_insight", "heroes/bakedanuki/modifier_bakedanuki_tricksters_insight", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_bakedanuki_tricksters_insight_passive", "heroes/bakedanuki/modifier_bakedanuki_tricksters_insight_passive", LUA_MODIFIER_MOTION_NONE )

function bakedanuki_tricksters_insight:IsStealable()
	return true
end

function bakedanuki_tricksters_insight:IsHiddenWhenStolen()
	return false
end

function bakedanuki_tricksters_insight:GetIntrinsicModifierName()
	return "modifier_bakedanuki_tricksters_insight_passive"
end

function bakedanuki_tricksters_insight:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	if not target or not caster then
		return
	end

	-- This check must be before spell block check
	if caster:GetUnitName() ~= "npc_dota_hero_dark_willow" then
		caster:RemoveModifierByName("modifier_bakedanuki_tricksters_insight_passive")
	end

	-- Check for spell block and spell immunity (latter because of lotus)
	if target:TriggerSpellAbsorb(self) or target:IsMagicImmune() then
		return
	end

	-- Sound
	target:EmitSound("Hero_DarkWillow.Shadow_Realm.Damage")

	-- Add modifiers
	local duration = self:GetSpecialValueFor("crit_duration")
	target:AddNewModifier(caster, self, "modifier_bakedanuki_tricksters_insight", {duration = duration})
	if caster:GetUnitName() ~= "npc_dota_hero_dark_willow" then
		caster:AddNewModifier(caster, self, "modifier_bakedanuki_tricksters_insight_passive", {duration = duration})
	end
end

function bakedanuki_tricksters_insight:OnUnStolen()
	local caster = self:GetCaster()

	if IsServer() then
		if caster:GetUnitName() ~= "npc_dota_hero_dark_willow" then
			caster:RemoveModifierByName("modifier_bakedanuki_tricksters_insight_passive")
		end
	end
end

function bakedanuki_tricksters_insight:ProcsMagicStick()
	return true
end
