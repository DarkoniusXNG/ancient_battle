modifier_custom_brain_sap_int_gain_counter = class({})

function modifier_custom_brain_sap_int_gain_counter:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_TOOLTIP
  }
end

function modifier_custom_brain_sap_int_gain_counter:OnTooltip()
  return self:GetStackCount()
end

function modifier_custom_brain_sap_int_gain_counter:IsHidden()
	return false
end

function modifier_custom_brain_sap_int_gain_counter:IsDebuff()
	return false
end

function modifier_custom_brain_sap_int_gain_counter:IsPurgable()
	return false
end
