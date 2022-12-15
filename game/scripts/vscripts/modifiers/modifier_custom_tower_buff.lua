--[[
-Modifier to grant bonus health/damage
Base health and damage is checked only on first application of modifier
]]
if modifier_custom_tower_buff == nil then
	modifier_custom_tower_buff = class({})
end

function modifier_custom_tower_buff:IsHidden()
    return true
end

function modifier_custom_tower_buff:IsPurgable()
    return false
end

function modifier_custom_tower_buff:GetAttributes()
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_custom_tower_buff:OnCreated()
	if IsServer() then
		local parent = self:GetParent()
		-- Get parent unit's base health and damage at time of modifier application
		self.parentMaxHealth = parent:GetBaseMaxHealth()
		self.parentMinDamage = parent:GetBaseDamageMin()
		self.parentMaxDamage = parent:GetBaseDamageMax()
	end
end

function modifier_custom_tower_buff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
		MODIFIER_PROPERTY_BASEATTACK_BONUSDAMAGE,
	}
end

function modifier_custom_tower_buff:GetModifierExtraHealthBonus()
	return 3.5*(self.parentMaxHealth)
end

function modifier_custom_tower_buff:GetModifierBaseAttack_BonusDamage()
	-- Check that min and max damage values have been fetched to prevent errors
	if self.parentMinDamage and self.parentMaxDamage then
		return (self.parentMinDamage + self.parentMaxDamage) / 2
	end
end
