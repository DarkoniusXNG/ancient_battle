modifier_custom_counter_helix_proc = class({})

function modifier_custom_counter_helix_proc:IsHidden()
	return true
end

function modifier_custom_counter_helix_proc:IsPurgable()
	return false
end

function modifier_custom_counter_helix_proc:IsDebuff()
	return false
end

function modifier_custom_counter_helix_proc:OnCreated()
	self:StartIntervalThink(0.05)
end

function modifier_custom_counter_helix_proc:OnIntervalThink()
	local parent = self:GetParent()
	-- Every 0.05 seconds spin:
	parent:SetAngles(0, 72, 0)
end
