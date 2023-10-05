modifier_custom_brain_sap_int_loss = class({})

function modifier_custom_brain_sap_int_loss:IsHidden()
	return true
end

function modifier_custom_brain_sap_int_loss:IsDebuff()
	return true
end

function modifier_custom_brain_sap_int_loss:IsPurgable()
	return false
end

function modifier_custom_brain_sap_int_loss:RemoveOnDeath()
	return true
end

function modifier_custom_brain_sap_int_loss:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_custom_brain_sap_int_loss:OnCreated()
	local parent = self:GetParent()
	local ability = self:GetAbility()

	self.int_steal_amount = ability:GetSpecialValueFor("int_steal")

	if IsServer() then
		local counter_modifier = parent:FindModifierByName("modifier_custom_brain_sap_int_loss_counter")
		if counter_modifier and not counter_modifier:IsNull() then
			counter_modifier:SetStackCount(counter_modifier:GetStackCount() + self.int_steal_amount)
		end
	end
end

function modifier_custom_brain_sap_int_loss:OnDestroy()
	if IsServer() then
		local counter_modifier = self:GetParent():FindModifierByName("modifier_custom_brain_sap_int_loss_counter")
		if counter_modifier and not counter_modifier:IsNull() then
			counter_modifier:SetStackCount(counter_modifier:GetStackCount() - self.int_steal_amount)
		end
	end
end

function modifier_custom_brain_sap_int_loss:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS
	}
end

function modifier_custom_brain_sap_int_loss:GetModifierBonusStats_Intellect()
	return -self.int_steal_amount
end
