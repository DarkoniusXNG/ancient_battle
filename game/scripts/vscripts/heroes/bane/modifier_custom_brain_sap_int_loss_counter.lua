modifier_custom_brain_sap_int_loss_counter = class({})

function modifier_custom_brain_sap_int_loss_counter:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_TOOLTIP
  }
end

function modifier_custom_brain_sap_int_loss_counter:OnTooltip()
  return self:GetStackCount()
end

function modifier_custom_brain_sap_int_loss_counter:IsHidden()
	return false
end

function modifier_custom_brain_sap_int_loss_counter:IsDebuff()
	return true
end

function modifier_custom_brain_sap_int_loss_counter:IsPurgable()
	return false
end

function modifier_custom_brain_sap_int_loss_counter:RemoveOnDeath()
	return true
end
