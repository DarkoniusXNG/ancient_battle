LinkLuaModifier("modifier_item_custom_diffusal_blade_passives", "items/custom_diffusal_blade.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_custom_purged_enemy_hero", "items/custom_diffusal_blade.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_custom_purged_enemy_creep", "items/custom_diffusal_blade.lua", LUA_MODIFIER_MOTION_NONE)

item_custom_diffusal_blade = class({})

function item_custom_diffusal_blade:GetIntrinsicModifierName()
  return "modifier_item_custom_diffusal_blade_passives"
end

function item_custom_diffusal_blade:CastFilterResultTarget(target)
  local defaultFilterResult = self.BaseClass.CastFilterResultTarget(self, target)

  if defaultFilterResult == UF_SUCCESS then
    if target:IsCustomWardTypeUnit() then
      return UF_FAIL_CUSTOM
    end
  end

  return defaultFilterResult
end

function item_custom_diffusal_blade:GetCustomCastErrorTarget(target)
  return "#dota_hud_error_cant_cast_on_other"
end

function item_custom_diffusal_blade:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	-- Check if target and caster entities exist
	if not target or not caster then
		return
	end

	-- Play cast sound
	caster:EmitSound("DOTA_Item.DiffusalBlade.Activate")

	-- Check if enemy or ally
	if target:GetTeamNumber() ~= caster:GetTeamNumber() then
		-- Check for spell block, pierces spell immunity
		if target:TriggerSpellAbsorb(self) then
			return
		end

		-- Play hit sound
		target:EmitSound("DOTA_Item.DiffusalBlade.Target")

		-- Always apply dispel
		DispelEnemy(target)

		-- Get duration
		local duration = self:GetSpecialValueFor("purge_slow_duration")

		if target:IsHero() then
			if target:IsRealHero() or target:IsStrongIllusionCustom() then
				--print("Target is a Real Hero or a Strong Illusion.")

				-- Apply slow only to non spell-immune heroes
				if not target:IsMagicImmune() then
					target:AddNewModifier(caster, self, "modifier_item_custom_purged_enemy_hero", {duration = duration})
				end
			else
				--print("Target is an Illusion of a Hero.")
				target:Kill(self, caster)
			end
		else
			--print("Target is a creep.")
			target:AddNewModifier(caster, self, "modifier_item_custom_purged_enemy_creep", {duration = duration})
			if (target:IsSummoned() or target:IsDominated()) and not target:IsMagicImmune() and not target:IsCustomWardTypeUnit() and target:GetUnitName() ~= "npc_dota_summoned_guardian_angel" then
				--print("Target is a summoned or dominated unit without spell immunity.")
				target:Kill(self, caster)
			end
		end
	else
		DispelAlly(target)
	end

	self:SpendCharge()
end

function item_custom_diffusal_blade:ProcsMagicStick()
  return false
end

---------------------------------------------------------------------------------------------------

function DispelAlly(unit)
	if unit then
		-- Basic Dispel for allies
		local RemovePositiveBuffs = false
		local RemoveDebuffs = true
		local BuffsCreatedThisFrameOnly = false
		local RemoveStuns = false
		local RemoveExceptions = false
		unit:Purge(RemovePositiveBuffs, RemoveDebuffs, BuffsCreatedThisFrameOnly, RemoveStuns, RemoveExceptions)
	end
end

function DispelEnemy(unit)
	if unit then
		-- Basic Dispel for enemies
		local RemovePositiveBuffs = true
		local RemoveDebuffs = false
		local BuffsCreatedThisFrameOnly = false
		local RemoveStuns = false
		local RemoveExceptions = false
		unit:Purge(RemovePositiveBuffs, RemoveDebuffs, BuffsCreatedThisFrameOnly, RemoveStuns, RemoveExceptions)
		unit:RemoveModifierByName("modifier_eul_cyclone")
		unit:RemoveModifierByName("modifier_brewmaster_storm_cyclone")
	end
end

---------------------------------------------------------------------------------------------------

modifier_item_custom_diffusal_blade_passives = class({})

function modifier_item_custom_diffusal_blade_passives:IsHidden()
	return true
end

function modifier_item_custom_diffusal_blade_passives:IsDebuff()
	return false
end

function modifier_item_custom_diffusal_blade_passives:IsPurgable()
	return false
end

function modifier_item_custom_diffusal_blade_passives:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_custom_diffusal_blade_passives:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end

function modifier_item_custom_diffusal_blade_passives:GetModifierBonusStats_Agility()
	return self:GetAbility():GetSpecialValueFor("bonus_agi")
end

function modifier_item_custom_diffusal_blade_passives:GetModifierBonusStats_Intellect()
	return self:GetAbility():GetSpecialValueFor("bonus_int")
end

if IsServer() then
	function modifier_item_custom_diffusal_blade_passives:OnAttackLanded(event)
		local parent = self:GetParent()
		local attacker = event.attacker
		local target = event.target

		-- Check if attacker exists
		if not attacker or attacker:IsNull() then
			return
		end

		-- Check if attacker has this modifier
		if attacker ~= parent then
			return
		end

		if parent:FindAllModifiersByName(self:GetName())[1] ~= self then
			return
		end

		-- If better version of mana break is present, do nothing
		if parent:HasModifier("modifier_item_staff_of_negation_passives") or parent:HasModifier("modifier_item_true_manta_passives") then
			return
		end

		-- To prevent crashes:
		if not target or target:IsNull() then
			return
		end

		-- Check for existence of GetUnitName method to determine if target is a unit or an item
		-- items don't have that method -> nil; if the target is an item, don't continue
		if target.GetUnitName == nil then
			return
		end

		-- Don't affect buildings, wards, illusions and spell-immune units
		if target:IsTower() or target:IsBarracks() or target:IsBuilding() or target:IsOther() or target:IsIllusion() or target:IsMagicImmune() then
			return
		end

		local target_mana = target:GetMana()

		-- Do nothing if target doesn't have mana
		if target_mana < 1 then
			return
		end

		local ability = self:GetAbility()

		-- Parameters
		local mana_burn = ability:GetSpecialValueFor("mana_burn")
		if parent:IsIllusion() then
			if parent:IsRangedAttacker() then
				mana_burn = ability:GetSpecialValueFor("mana_burn_illusion_ranged")
			else
				mana_burn = ability:GetSpecialValueFor("mana_burn_illusion_melee")
			end
		end

		-- Min mana to burn
		mana_burn = math.min(mana_burn, target_mana)

		-- Burn mana
		target:ReduceMana(mana_burn)

		-- Deal bonus damage
		local dmg_per_burned_mana = ability:GetSpecialValueFor("damage_per_burned_mana")
		local actual_damage = dmg_per_burned_mana * mana_burn

		local damage_table = {}
		damage_table.attacker = parent
		damage_table.damage_type = DAMAGE_TYPE_PHYSICAL
		damage_table.damage_flags = DOTA_DAMAGE_FLAG_BYPASSES_BLOCK
		damage_table.ability = ability
		damage_table.damage = actual_damage
		damage_table.victim = target

		ApplyDamage(damage_table)

		-- Sound and effect
		if target:GetMana() > 1 and target:IsAlive() then
			-- Plays the particle
			local manaburn_fx = ParticleManager:CreateParticle("particles/generic_gameplay/generic_manaburn.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
			ParticleManager:SetParticleControl(manaburn_fx, 0, target:GetAbsOrigin())
			ParticleManager:ReleaseParticleIndex(manaburn_fx)
		end
	end
end

---------------------------------------------------------------------------------------------------

modifier_item_custom_purged_enemy_hero = class({})

function modifier_item_custom_purged_enemy_hero:IsHidden() -- needs tooltip
	return false
end

function modifier_item_custom_purged_enemy_hero:IsPurgable()
	return true
end

function modifier_item_custom_purged_enemy_hero:IsDebuff()
	return true
end

function modifier_item_custom_purged_enemy_hero:GetEffectName()
	return "particles/items_fx/diffusal_slow.vpcf"
end

function modifier_item_custom_purged_enemy_hero:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_item_custom_purged_enemy_hero:OnCreated()
	local parent = self:GetParent()
	local ability = self:GetAbility()
	if ability and not ability:IsNull() then
		local movement_slow = ability:GetSpecialValueFor("move_speed_slow")
		if IsServer() then
			-- Slow is reduced with Status Resistance
			self.slow = parent:GetValueChangedByStatusResistance(movement_slow)
		else
			self.slow = movement_slow
		end
	end
end

modifier_item_custom_purged_enemy_hero.OnRefresh = modifier_item_custom_purged_enemy_hero.OnCreated

function modifier_item_custom_purged_enemy_hero:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
end

function modifier_item_custom_purged_enemy_hero:GetModifierMoveSpeedBonus_Percentage()
	return self.slow
end

function modifier_item_custom_purged_enemy_hero:GetTexture()
	return "custom/custom_diffusal_blade"
end

---------------------------------------------------------------------------------------------------

modifier_item_custom_purged_enemy_creep = class(modifier_item_custom_purged_enemy_hero)

function modifier_item_custom_purged_enemy_creep:CheckState()
	return {
		[MODIFIER_STATE_ROOTED] = true,
	}
end
