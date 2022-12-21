LinkLuaModifier("modifier_custom_necronomicon_passives", "items/necronomicon.lua", LUA_MODIFIER_MOTION_NONE)

item_custom_necronomicon_1 = class({})

function item_custom_necronomicon_1:GetIntrinsicModifierName()
	return "modifier_custom_necronomicon_passives"
end

function item_custom_necronomicon_1:OnSpellStart()
  local caster = self:GetCaster()

  local summon_position = caster:GetAbsOrigin() + RandomVector(250)

  local duration = self:GetSpecialValueFor("summon_duration")

  local level = self:GetAbilityKeyValues().ItemBaseLevel
  local warrior = "npc_dota_necronomicon_warrior_"..level
  local archer = "npc_dota_necronomicon_archer_"..level
  local int_lvl = tonumber(level)

  local warrior_summon = CreateUnitByName(warrior, summon_position, true, caster, caster, caster:GetTeamNumber())
  warrior_summon:SetOwner(caster:GetOwner())
  warrior_summon:SetControllableByPlayer(caster:GetPlayerID(), true)
  warrior_summon:AddNewModifier(caster, self, "modifier_kill", {duration = duration})
  local last_will = warrior_summon:FindAbilityByName("necronomicon_warrior_last_will")
  if last_will then
	last_will:SetLevel(int_lvl)
  end
  local true_sight = warrior_summon:FindAbilityByName("necronomicon_warrior_sight")
  if true_sight and int_lvl == 3 then
    true_sight:SetLevel(1)
  end
  local mana_burn = warrior_summon:FindAbilityByName("necronomicon_warrior_mana_burn")
  if mana_burn then
	mana_burn:SetLevel(int_lvl)
  end

  local archer_summon = CreateUnitByName(archer, summon_position, true, caster, caster, caster:GetTeamNumber())
  archer_summon:SetOwner(caster:GetOwner())
  archer_summon:SetControllableByPlayer(caster:GetPlayerID(), true)
  archer_summon:AddNewModifier(caster, self, "modifier_kill", {duration = duration})
  local purge = archer_summon:FindAbilityByName("necronomicon_archer_purge")
  if purge and int_lvl == 3 then
    purge:SetLevel(1)
  end
  local aura = archer_summon:FindAbilityByName("necronomicon_archer_aoe")
  if aura then
    aura:SetLevel(int_lvl)
  end

  FindClearSpaceForUnit(warrior_summon, summon_position, false)
  FindClearSpaceForUnit(archer_summon, summon_position, false)

  -- Sound
  caster:EmitSound("DOTA_Item.Necronomicon.Activate")
end

function item_custom_necronomicon_1:ProcsMagicStick()
  return false
end

item_custom_necronomicon_2 = item_custom_necronomicon_1
item_custom_necronomicon_3 = item_custom_necronomicon_1

---------------------------------------------------------------------------------------------------

modifier_custom_necronomicon_passives = class({})

function modifier_custom_necronomicon_passives:IsHidden()
	return true
end

function modifier_custom_necronomicon_passives:IsDebuff()
	return false
end

function modifier_custom_necronomicon_passives:IsPurgable()
	return false
end

function modifier_custom_necronomicon_passives:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_custom_necronomicon_passives:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
	}
end

function modifier_custom_necronomicon_passives:GetModifierBonusStats_Strength()
	return self:GetAbility():GetSpecialValueFor("bonus_strength")
end

function modifier_custom_necronomicon_passives:GetModifierBonusStats_Intellect()
	return self:GetAbility():GetSpecialValueFor("bonus_intellect")
end
