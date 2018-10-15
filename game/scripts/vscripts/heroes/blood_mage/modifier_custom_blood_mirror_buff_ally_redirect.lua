if modifier_custom_blood_mirror_buff_ally_redirect == nil then
	modifier_custom_blood_mirror_buff_ally_redirect = class({})
end

function modifier_custom_blood_mirror_buff_ally_redirect:IsHidden()
	return false
end

function modifier_custom_blood_mirror_buff_ally_redirect:IsDebuff()
	return false
end

function modifier_custom_blood_mirror_buff_ally_redirect:IsPurgable()
	return true
end

function modifier_custom_blood_mirror_buff_ally_redirect:RemoveOnDeath()
	return true
end

function modifier_custom_blood_mirror_buff_ally_redirect:OnCreated()
	local ability = self:GetAbility()
	self.damage_redirect_percent = ability:GetSpecialValueFor("redirected_damage")
	self.redirect_target = self:GetCaster()
end

function modifier_custom_blood_mirror_buff_ally_redirect:OnRefresh()
	local ability = self:GetAbility()
	self.damage_redirect_percent = ability:GetSpecialValueFor("redirected_damage")
	self.redirect_target = self:GetCaster()
end

function modifier_custom_blood_mirror_buff_ally_redirect:GetEffectName()
	return "particles/econ/items/bloodseeker/bloodseeker_eztzhok_weapon/bloodseeker_bloodrage_ground_eztzhok.vpcf"
end

function modifier_custom_blood_mirror_buff_ally_redirect:GetEffectAttachType()
	return PATTACH_POINT_FOLLOW
end
