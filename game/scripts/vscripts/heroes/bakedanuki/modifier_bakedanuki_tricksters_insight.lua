modifier_bakedanuki_tricksters_insight = class({})

function modifier_bakedanuki_tricksters_insight:IsHidden()
	return false
end

function modifier_bakedanuki_tricksters_insight:IsDebuff()
	return true
end

function modifier_bakedanuki_tricksters_insight:IsPurgable()
	return true
end

function modifier_bakedanuki_tricksters_insight:CheckState()
	return {
		[MODIFIER_STATE_PASSIVES_DISABLED] = true,
	}
end

function modifier_bakedanuki_tricksters_insight:GetEffectName()
	return "particles/units/heroes/hero_dark_willow/dark_willow_wisp_spell_debuff.vpcf"
end

function modifier_bakedanuki_tricksters_insight:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end
