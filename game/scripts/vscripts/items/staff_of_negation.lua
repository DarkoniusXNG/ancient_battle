LinkLuaModifier("modifier_item_staff_of_negation_passives", "items/staff_of_negation.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_staff_of_negation_debuff", "items/staff_of_negation.lua", LUA_MODIFIER_MOTION_NONE)

item_staff_of_negation = class({})

function item_staff_of_negation:GetIntrinsicModifierName()
  return "modifier_item_staff_of_negation_passives"
end

function item_staff_of_negation:GetAOERadius()
  return self:GetSpecialValueFor("radius")
end

function item_staff_of_negation:OnSpellStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()

	-- Check if point and caster exist
	if not point or not caster then
		return
	end

	local caster_team = caster:GetTeamNumber()
	local radius = self:GetSpecialValueFor("radius")
	local duration = self:GetSpecialValueFor("duration")

	-- Targetting constants
	local target_type = bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
	local target_flags = bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_INVULNERABLE)

	-- Apply the slow modifier and purge enemies around point and kill all summons and illusions
	local enemies = FindUnitsInRadius(caster_team, point, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, target_type, target_flags, FIND_ANY_ORDER, false)
	for _, enemy in pairs(enemies) do
		if enemy and not enemy:IsNull() then
			-- Dispel always
			DispelEnemy(enemy)

			-- Debuff only if not spell immune
			if not enemy:IsMagicImmune() then
				enemy:AddNewModifier(caster, self, "modifier_item_staff_of_negation_debuff", {duration = duration})
			end

			if enemy:IsDominated() or enemy:IsSummoned() or (enemy:IsIllusion() and not enemy:IsStrongIllusionCustom()) then
				if not enemy:IsMagicImmune() and not enemy:IsCustomWardTypeUnit() and enemy:GetUnitName() ~= "npc_dota_summoned_guardian_angel" then
					enemy:Kill(self, caster)
				end
			end
		end
	end

	-- Apply the basic dispel to allies around point
	local allies = FindUnitsInRadius(caster_team, point, nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, target_type, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)
	for _, ally in pairs(allies) do
		if ally and not ally:IsNull() then
			DispelAlly(ally)
		end
	end

	-- Sound
	EmitSoundOnLocationWithCaster(point, "DOTA_Item.RodOfAtos.Target", caster) -- DOTA_Item.RodOfAtos.Activate
end

function item_staff_of_negation:ProcsMagicStick()
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

modifier_item_staff_of_negation_passives = class({})

function modifier_item_staff_of_negation_passives:IsHidden()
	return true
end

function modifier_item_staff_of_negation_passives:IsDebuff()
	return false
end

function modifier_item_staff_of_negation_passives:IsPurgable()
	return false
end

function modifier_item_staff_of_negation_passives:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_staff_of_negation_passives:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end

function modifier_item_staff_of_negation_passives:GetModifierBonusStats_Strength()
	return self:GetAbility():GetSpecialValueFor("bonus_str")
end

function modifier_item_staff_of_negation_passives:GetModifierBonusStats_Agility()
	return self:GetAbility():GetSpecialValueFor("bonus_agi")
end

function modifier_item_staff_of_negation_passives:GetModifierBonusStats_Intellect()
	return self:GetAbility():GetSpecialValueFor("bonus_int")
end

function modifier_item_staff_of_negation_passives:GetModifierAttackSpeedBonus_Constant()
	return self:GetAbility():GetSpecialValueFor("bonus_attack_speed")
end

function modifier_item_staff_of_negation_passives:GetModifierPreAttack_BonusDamage()
	return self:GetAbility():GetSpecialValueFor("bonus_dmg")
end

function modifier_item_staff_of_negation_passives:GetModifierConstantManaRegen()
	return self:GetAbility():GetSpecialValueFor("bonus_mana_regen")
end

if IsServer() then
	function modifier_item_staff_of_negation_passives:OnAttackLanded(event)
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
		if parent:HasModifier("modifier_item_true_manta_passives") then
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
		target:ReduceMana(mana_burn, ability)

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

modifier_item_staff_of_negation_debuff = class({})

function modifier_item_staff_of_negation_debuff:IsHidden() -- needs tooltip
	return false
end

function modifier_item_staff_of_negation_debuff:IsPurgable()
	return true
end

function modifier_item_staff_of_negation_debuff:IsDebuff()
	return true
end

function modifier_item_staff_of_negation_debuff:GetEffectName()
	return "particles/items2_fx/rod_of_atos.vpcf"
end

function modifier_item_staff_of_negation_debuff:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_item_staff_of_negation_debuff:OnCreated()
	local parent = self:GetParent()
	local ability = self:GetAbility()
	if ability and not ability:IsNull() then
		local movement_slow = ability:GetSpecialValueFor("move_speed_slow")
		local attack_slow = ability:GetSpecialValueFor("attack_speed_slow")
		if IsServer() then
			-- Slow is reduced with Status Resistance
			self.slow = parent:GetValueChangedByStatusResistance(movement_slow)
			self.attack_slow = parent:GetValueChangedByStatusResistance(attack_slow)
		else
			self.slow = movement_slow
			self.attack_slow = attack_slow
		end
	end
end

modifier_item_staff_of_negation_debuff.OnRefresh = modifier_item_staff_of_negation_debuff.OnCreated

function modifier_item_staff_of_negation_debuff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_DISABLE_HEALING,
		MODIFIER_PROPERTY_PROVIDES_FOW_POSITION,
	}
end

function modifier_item_staff_of_negation_debuff:GetModifierMoveSpeedBonus_Percentage()
	return self.slow
end

function modifier_item_staff_of_negation_debuff:GetModifierAttackSpeedBonus_Constant()
	return self.attack_slow
end

function modifier_item_staff_of_negation_debuff:GetDisableHealing()
	return 1
end

function modifier_item_staff_of_negation_debuff:GetModifierProvidesFOWVision()
	return 1
end

function modifier_item_staff_of_negation_debuff:CheckState()
	return {
		[MODIFIER_STATE_TETHERED] = true,
		[MODIFIER_STATE_INVISIBLE] = false,
	}
end

function modifier_item_staff_of_negation_debuff:GetTexture()
	return "custom/staff_of_negation"
end
