if modifier_custom_blood_mirror_buff_caster_redirect == nil then
	modifier_custom_blood_mirror_buff_caster_redirect = class({})
end

function modifier_custom_blood_mirror_buff_caster_redirect:IsHidden()
	return true
end

function modifier_custom_blood_mirror_buff_caster_redirect:IsDebuff()
	return false
end

function modifier_custom_blood_mirror_buff_caster_redirect:IsPurgable()
	return false
end

function modifier_custom_blood_mirror_buff_caster_redirect:RemoveOnDeath()
	return true
end

function modifier_custom_blood_mirror_buff_caster_redirect:OnCreated()
	if IsServer() then
		local ability = self:GetAbility()
		self.damage_redirect_percent = ability:GetSpecialValueFor("redirected_damage")
		self.redirect_target = ability:GetCursorTarget()
	end
end

function modifier_custom_blood_mirror_buff_caster_redirect:OnRefresh()
	if IsServer() then
		local ability = self:GetAbility()
		self.damage_redirect_percent = ability:GetSpecialValueFor("redirected_damage")
		self.redirect_target = ability:GetCursorTarget()
	end
end
