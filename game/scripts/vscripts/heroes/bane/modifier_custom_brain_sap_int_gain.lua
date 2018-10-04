if modifier_custom_brain_sap_int_gain == nil then
	modifier_custom_brain_sap_int_gain = class({})
end

function modifier_custom_brain_sap_int_gain:IsHidden()
	return true
end

function modifier_custom_brain_sap_int_gain:IsDebuff()
	return false
end

function modifier_custom_brain_sap_int_gain:IsPurgable()
	return false
end

function modifier_custom_brain_sap_int_gain:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_custom_brain_sap_int_gain:OnCreated()
	local parent = self:GetParent()
	local ability = self:GetAbility()

	self.int_steal_amount = ability:GetSpecialValueFor("int_steal")

	if IsServer() then
		local counter_modifier = parent:FindModifierByName("modifier_custom_brain_sap_int_gain_counter")
		if counter_modifier and not counter_modifier:IsNull() then
			counter_modifier:SetStackCount(counter_modifier:GetStackCount() + self.int_steal_amount)
		end
	end
end

function modifier_custom_brain_sap_int_gain:OnRefresh()
	local ability = self:GetAbility()

	self.int_steal_amount = ability:GetSpecialValueFor("int_steal")
end

function modifier_custom_brain_sap_int_gain:OnDestroy()
	if IsServer() then
		local counter_modifier = self:GetParent():FindModifierByName("modifier_custom_brain_sap_int_gain_counter")
		if counter_modifier and not counter_modifier:IsNull() then
			counter_modifier:SetStackCount(counter_modifier:GetStackCount() - self.int_steal_amount)
		end
	end
end

function modifier_custom_brain_sap_int_gain:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS
	}
	return funcs
end

function modifier_custom_brain_sap_int_gain:GetModifierBonusStats_Intellect()
	return self.int_steal_amount
end
