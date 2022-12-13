modifier_bakedanuki_tomfoolery_hidden = class({})

function modifier_bakedanuki_tomfoolery_hidden:IsHidden()
	return true
end

function modifier_bakedanuki_tomfoolery_hidden:IsPurgable()
	return false
end

function modifier_bakedanuki_tomfoolery_hidden:OnCreated()
	if IsServer() then
		self:GetParent():AddNoDraw()
	end
end

function modifier_bakedanuki_tomfoolery_hidden:OnDestroy()
	if IsServer() then
		self:GetParent():StartGestureWithPlaybackRate( ACT_DOTA_CAST_ABILITY_2, 2.0 )
		self:GetParent():RemoveNoDraw()
	end
end

function modifier_bakedanuki_tomfoolery_hidden:CheckState()
	return {
		[MODIFIER_STATE_OUT_OF_GAME] = true,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
		[MODIFIER_STATE_INVULNERABLE] = true,
		[MODIFIER_STATE_INVISIBLE] = true,
		[MODIFIER_STATE_TRUESIGHT_IMMUNE] = true,
		[MODIFIER_STATE_UNSELECTABLE] = true,
		[MODIFIER_STATE_UNTARGETABLE] = true,
		[MODIFIER_STATE_NOT_ON_MINIMAP] = true,
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
	}
end
