if modifier_custom_blood_mirror_debuff_enemy == nil then
	modifier_custom_blood_mirror_debuff_enemy = class({})
end

function modifier_custom_blood_mirror_debuff_enemy:IsHidden()
	return false
end

function modifier_custom_blood_mirror_debuff_enemy:IsDebuff()
	return true
end

function modifier_custom_blood_mirror_debuff_enemy:IsPurgable()
	return true
end

function modifier_custom_blood_mirror_debuff_enemy:RemoveOnDeath()
	return true
end

function modifier_custom_blood_mirror_debuff_enemy:GetEffectName()
	return "particles/econ/items/bloodseeker/bloodseeker_eztzhok_weapon/bloodseeker_bloodrage_ground_eztzhok.vpcf"
end

function modifier_custom_blood_mirror_debuff_enemy:GetEffectAttachType()
	return PATTACH_POINT_FOLLOW
end
