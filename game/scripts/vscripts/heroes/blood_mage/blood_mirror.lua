blood_mage_blood_mirror = blood_mage_blood_mirror or class({})

-- Visible modifiers
LinkLuaModifier("modifier_custom_blood_mirror_buff_ally_redirect", "heroes/blood_mage/modifier_custom_blood_mirror_buff_ally_redirect.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_custom_blood_mirror_debuff_enemy", "heroes/blood_mage/modifier_custom_blood_mirror_debuff_enemy.lua", LUA_MODIFIER_MOTION_NONE)
-- Hidden modifiers
LinkLuaModifier("modifier_custom_blood_mirror_buff_caster_redirect", "heroes/blood_mage/modifier_custom_blood_mirror_buff_caster_redirect.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_custom_blood_mirror_debuff_caster", "heroes/blood_mage/modifier_custom_blood_mirror_debuff_caster.lua", LUA_MODIFIER_MOTION_NONE)

function blood_mage_blood_mirror:CastFilterResultTarget(target)
	local caster = self:GetCaster()
	local default_result = self.BaseClass.CastFilterResultTarget(self, target)

	if target == caster then
		return UF_FAIL_CUSTOM
	end

	return default_result
end

function blood_mage_blood_mirror:GetCustomCastErrorTarget(target)
	local caster = self:GetCaster()
	if target == caster then
		return "#dota_hud_error_cant_cast_on_self"
	end
	return ""
end

function blood_mage_blood_mirror:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	if not target or not caster then
		return
	end

	-- Sound on caster
	caster:EmitSound("Hero_OgreMagi.Bloodlust.Cast")

	local blood_mirror_duration = self:GetSpecialValueFor("duration")

	if target:GetTeamNumber() == caster:GetTeamNumber() then
		-- Sound on target
		target:EmitSound("Hero_OgreMagi.Bloodlust.Target.FP")

		-- Apply buff
		target:AddNewModifier(caster, self, "modifier_custom_blood_mirror_buff_ally_redirect", {duration = blood_mirror_duration})

		-- Apply debuff to the caster
		caster:AddNewModifier(caster, self, "modifier_custom_blood_mirror_debuff_caster", {duration = blood_mirror_duration})
	else
		-- Check for spell block and spell immunity (latter because of lotus)
		if target:TriggerSpellAbsorb(self) or target:IsMagicImmune() then
			return
		end

		-- Sound on target
		target:EmitSound("Hero_OgreMagi.Bloodlust.Target.FP")

		caster.redirect_target = target -- only on the server-side

		-- Apply debuff
		target:AddNewModifier(caster, self, "modifier_custom_blood_mirror_debuff_enemy", {duration = blood_mirror_duration})

		-- Apply buff to the caster
		caster:AddNewModifier(caster, self, "modifier_custom_blood_mirror_buff_caster_redirect", {duration = blood_mirror_duration})
	end
end

function blood_mage_blood_mirror:ProcsMagicStick()
	return true
end
