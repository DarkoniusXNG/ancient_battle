modifier_custom_blood_mirror_debuff_caster = class({})

function modifier_custom_blood_mirror_debuff_caster:IsHidden()
	return true
end

function modifier_custom_blood_mirror_debuff_caster:IsDebuff()
	return true
end

function modifier_custom_blood_mirror_debuff_caster:IsPurgable()
	return false
end

function modifier_custom_blood_mirror_debuff_caster:RemoveOnDeath()
	return true
end
