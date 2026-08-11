--[[
-Modifier to grant bonus health/damage
Base health and damage is checked only on first application of modifier
]]
modifier_custom_tower_buff = class({})

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
		if GetMapName() == "main" or GetMapName() == "3vs3" then
			self.bonus_hp = self.parentMaxHealth
			self.damage = 0
		elseif GetMapName() == "two_vs_two" then
			self.bonus_hp = 4*(self.parentMaxHealth)
			self.damage = (self.parentMinDamage + self.parentMaxDamage) / 2
		else
			self.bonus_hp = self.parentMaxHealth
			self.damage = 0
		end
	end
end

function modifier_custom_tower_buff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
		MODIFIER_PROPERTY_BASEATTACK_BONUSDAMAGE,
	}
end

function modifier_custom_tower_buff:GetModifierExtraHealthBonus()
	return self.bonus_hp
end

function modifier_custom_tower_buff:GetModifierBaseAttack_BonusDamage()
	if self.damage then
		return self.damage
	end
end
