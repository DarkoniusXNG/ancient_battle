if modifier_custom_brain_sap_int_gain_counter == nil then
	modifier_custom_brain_sap_int_gain_counter = class({})
end

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

--function modifier_custom_brain_sap_int_gain_counter:GetAttributes()
	--return MODIFIER_ATTRIBUTE_MULTIPLE
--end
