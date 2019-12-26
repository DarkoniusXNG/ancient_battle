LinkLuaModifier("modifier_custom_magus_cloak_passives", "items/magus_cloak.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_custom_magus_cloak_debuff", "items/magus_cloak.lua", LUA_MODIFIER_MOTION_NONE)

item_custom_magus_cloak = class({})

function item_custom_magus_cloak:GetIntrinsicModifierName()
	return "modifier_custom_magus_cloak_passives"
end

---------------------------------------------------------------------------------------------------

modifier_custom_magus_cloak_passives = class({})

function modifier_custom_magus_cloak_passives:IsHidden()
	return true
end

function modifier_custom_magus_cloak_passives:IsDebuff()
	return false
end

function modifier_custom_magus_cloak_passives:IsPurgable()
	return false
end

function modifier_custom_magus_cloak_passives:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_custom_magus_cloak_passives:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
		MODIFIER_EVENT_ON_ABILITY_EXECUTED
	}
end

function modifier_custom_magus_cloak_passives:GetModifierPreAttack_BonusDamage()
	return self:GetAbility():GetSpecialValueFor("bonus_damage")
end

function modifier_custom_magus_cloak_passives:GetModifierConstantManaRegen()
	return self:GetAbility():GetSpecialValueFor("bonus_mana_regen")
end

function modifier_custom_magus_cloak_passives:GetModifierBonusStats_Strength()
	return self:GetAbility():GetSpecialValueFor("bonus_strength")
end

function modifier_custom_magus_cloak_passives:GetModifierBonusStats_Agility()
	return self:GetAbility():GetSpecialValueFor("bonus_agility")
end

function modifier_custom_magus_cloak_passives:GetModifierBonusStats_Intellect()
	return self:GetAbility():GetSpecialValueFor("bonus_intellect")
end

function modifier_custom_magus_cloak_passives:GetModifierSpellAmplify_Percentage()
	return self:GetAbility():GetSpecialValueFor("bonus_spell_amp")
end

function modifier_custom_magus_cloak_passives:OnAbilityExecuted(event)
	local parent = self:GetParent()

	-- Trigger only for the parent
	if parent ~= event.unit then
		return nil
	end

	-- Don't trigger on illusions
	if parent:IsIllusion() then
		return nil
	end

	if not IsServer() then
		return nil
	end

	local target = event.target

	-- To prevent crashes
	if not target then
		return nil
	end

	-- To prevent crashes
	if target:IsNull() then
		return nil
	end

	-- Don't trigger on self-casted spells or spells casted on allies
	if target == parent or target:GetTeamNumber() == parent:GetTeamNumber() then
		return nil
	end

	-- Don't trigger if target is dead
	if not target:IsAlive() then
		return nil
	end

	-- Don't trigger on buildings, towers and fountains
	if target:IsBuilding() or target:IsTower() or target:IsFountain() then
		return nil
	end

	local caster = self:GetCaster() or parent
	local ability = self:GetAbility()
	--[[ -- Manually count number of cloaks in inventory
	local ability_name = ability:GetAbilityName()
	local number_of_magus_cloaks = 0
	for item_slot = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6 do
		local item = caster:GetItemInSlot(item_slot)
		if item then
			local item_name = item:GetName()
			print("Item name: "..item_name)
			if item_name == ability_name then
				number_of_magus_cloaks = number_of_magus_cloaks + 1
			end
		end
	end
	]]
	local number_of_magus_cloaks = #caster:FindAllModifiersByName(self:GetName())
	local modifier = target:AddNewModifier(caster, ability, "modifier_custom_magus_cloak_debuff", {duration = FrameTime() * 2})
	modifier:SetStackCount(number_of_magus_cloaks)
end

---------------------------------------------------------------------------------------------------

modifier_custom_magus_cloak_debuff = class({})

function modifier_custom_magus_cloak_debuff:IsHidden()
	return true
end

function modifier_custom_magus_cloak_debuff:IsDebuff()
	return true
end

function modifier_custom_magus_cloak_debuff:IsPurgable()
	return false
end

function modifier_custom_magus_cloak_debuff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING
	}
end

function modifier_custom_magus_cloak_debuff:GetModifierStatusResistanceStacking()
	return self:GetStackCount()*self:GetAbility():GetSpecialValueFor("bonus_debuff_amp")
end
