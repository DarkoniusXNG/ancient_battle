﻿if silencer_custom_last_word == nil then
	silencer_custom_last_word = class({})
end

LinkLuaModifier("modifier_custom_last_word_silence_passive", "heroes/silencer/modifier_custom_last_word_silence_passive.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_custom_last_word_aura_effect", "heroes/silencer/modifier_custom_last_word_aura_effect.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_custom_last_word_aura_applier", "heroes/silencer/modifier_custom_last_word_aura_applier.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_custom_last_word_silence_active", "heroes/silencer/modifier_custom_last_word_silence_active.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_custom_last_word_disarm", "heroes/silencer/modifier_custom_last_word_disarm.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_custom_last_word_active", "heroes/silencer/modifier_custom_last_word_active.lua", LUA_MODIFIER_MOTION_NONE)

function silencer_custom_last_word:IsStealable()
	return true
end

function silencer_custom_last_word:IsHiddenWhenStolen()
	return false
end

function silencer_custom_last_word:GetIntrinsicModifierName()
	return "modifier_custom_last_word_aura_applier"
end

function silencer_custom_last_word:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	if IsServer() then
		if caster:GetUnitName() ~= "npc_dota_hero_silencer" then
			caster:RemoveModifierByName("modifier_custom_last_word_aura_applier")
		end

		-- Checking if target has spell block, if target has spell block, there is no need to execute the spell
		if target ~= nil and (not target:TriggerSpellAbsorb(self)) then
			-- Sound on the target
			target:EmitSound("Hero_Silencer.LastWord.Cast")

			-- Applying the timer debuff
			local duration = self:GetSpecialValueFor("debuff_duration")
			target:AddNewModifier(caster, self, "modifier_custom_last_word_active", {duration = duration})
		end
	end
end

function silencer_custom_last_word:OnStolen(hSourceAbility)
	local caster = self:GetCaster()

	if IsServer() then
		if caster:GetUnitName() ~= "npc_dota_hero_silencer" then
			caster:RemoveModifierByName("modifier_custom_last_word_aura_applier")
		end
	end
end

function silencer_custom_last_word:ProcsMagicStick()
	return true
end
