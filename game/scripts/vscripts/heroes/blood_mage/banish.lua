if blood_mage_banish == nil then
	blood_mage_banish = class({})
end

LinkLuaModifier("modifier_banished_enemy", "heroes/blood_mage/banish.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_banished_ally", "heroes/blood_mage/banish.lua", LUA_MODIFIER_MOTION_NONE)

-- function blood_mage_banish:CastFilterResultTarget(target)
	-- local default_result = self.BaseClass.CastFilterResultTarget(self, target)

	-- if target:IsCustomWardTypeUnit() then
		-- return UF_FAIL_CUSTOM
	-- end

	-- return default_result
-- end

-- function blood_mage_banish:GetCustomCastErrorTarget(target)
	-- if target:IsCustomWardTypeUnit() then
		-- return "#dota_hud_error_cant_cast_on_other"
	-- end
	-- return ""
-- end

function blood_mage_banish:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	if not target or not caster then
		return
	end
	
	--KVs
	local hero_duration = self:GetSpecialValueFor("hero_duration")
	local creep_duration = self:GetSpecialValueFor("creep_duration")

	-- Talent that increases duration:
	local talent = caster:FindAbilityByName("special_bonus_unique_blood_mage_1")
	if talent and talent:GetLevel() > 0 then
		hero_duration = hero_duration + talent:GetSpecialValueFor("value")
		creep_duration = creep_duration + talent:GetSpecialValueFor("value")
	end

	-- Checking if target is an enemy
	if target:GetTeamNumber() ~= caster:GetTeamNumber() then
		-- Check for spell block and spell immunity (latter because of lotus)
		if not target:TriggerSpellAbsorb(self) and not target:IsMagicImmune() then
			-- Sound
			target:EmitSound("Hero_Pugna.Decrepify")

			if target:IsRealHero() then
				target:AddNewModifier(caster, self, "modifier_banished_enemy", {duration = hero_duration})
			else
				target:AddNewModifier(caster, self, "modifier_banished_enemy", {duration = creep_duration})
			end
		end
	else
		-- Sound
		target:EmitSound("Hero_Pugna.Decrepify")

		if target:IsRealHero() then
			target:AddNewModifier(caster, self, "modifier_banished_ally", {duration = hero_duration})
		else
			target:AddNewModifier(caster, self, "modifier_banished_ally", {duration = creep_duration})
		end
	end
end

---------------------------------------------------------------------------------------------------

if modifier_banished_ally == nil then
	modifier_banished_ally = class({})
end

function modifier_banished_ally:IsHidden() -- needs tooltip
	return false
end

function modifier_banished_ally:IsDebuff()
	return false
end

function modifier_banished_ally:IsPurgable()
	return true
end

function modifier_banished_ally:RemoveOnDeath()
	return true
end

function modifier_banished_ally:OnCreated()
	local ability = self:GetAbility()
	if ability and not ability:IsNull() then
		self.magic_resist = ability:GetSpecialValueFor("bonus_spell_damage_allies")
		self.hp_regen_amp = ability:GetSpecialValueFor("heal_amp_pct")
		self.lifesteal_amp = ability:GetSpecialValueFor("heal_amp_pct")
		self.heal_amp = ability:GetSpecialValueFor("heal_amp_pct")
		self.spell_lifesteal_amp = ability:GetSpecialValueFor("heal_amp_pct")
	end
end

modifier_banished_ally.OnRefresh = modifier_banished_ally.OnCreated

function modifier_banished_ally:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_DECREPIFY_UNIQUE,
		MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
		MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET,
		MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE,
		MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
	}
end

function modifier_banished_ally:GetModifierMagicalResistanceDecrepifyUnique()
	return self.magic_resist
end

function modifier_banished_ally:GetAbsoluteNoDamagePhysical()
	return 1
end

function modifier_banished_ally:GetModifierHPRegenAmplify_Percentage()
	return self.hp_regen_amp
end

function modifier_banished_ally:GetModifierHealAmplify_PercentageTarget()
	return self.heal_amp
end

function modifier_banished_ally:GetModifierLifestealRegenAmplify_Percentage()
	return self.lifesteal_amp
end

function modifier_banished_ally:GetModifierSpellLifestealRegenAmplify_Percentage()
	return self.spell_lifesteal_amp
end

function modifier_banished_ally:CheckState()
	return {
		[MODIFIER_STATE_DISARMED] = true,
		[MODIFIER_STATE_ATTACK_IMMUNE] = true,
	}
end

function modifier_banished_ally:GetEffectName()
	return "particles/units/heroes/hero_pugna/pugna_decrepify.vpcf"
end

function modifier_banished_ally:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

---------------------------------------------------------------------------------------------------

if modifier_banished_enemy == nil then
	modifier_banished_enemy = class({})
end

function modifier_banished_enemy:IsHidden() -- needs tooltip
	return false
end

function modifier_banished_enemy:IsDebuff()
	return true
end

function modifier_banished_enemy:IsPurgable()
	return true
end

function modifier_banished_enemy:RemoveOnDeath()
	return true
end

function modifier_banished_enemy:OnCreated()
	local ability = self:GetAbility()
	if ability and not ability:IsNull() then
		self.magic_resist = ability:GetSpecialValueFor("bonus_spell_damage")
		local movement_slow = ability:GetSpecialValueFor("move_speed_slow")
		if IsServer() then
			-- Slow is reduced with Status Resistance
			self.slow = parent:GetValueChangedByStatusResistance(movement_slow)
		else
			self.slow = movement_slow
		end
	end
end

modifier_banished_enemy.OnRefresh = modifier_banished_enemy.OnCreated

function modifier_banished_enemy:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_DECREPIFY_UNIQUE,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
	}
end

function modifier_banished_enemy:GetModifierMagicalResistanceDecrepifyUnique()
	return 0 - math.abs(self.magic_resist)
end

function modifier_banished_enemy:GetModifierMoveSpeedBonus_Percentage()
	return 0 - math.abs(self.slow)
end

function modifier_banished_enemy:GetAbsoluteNoDamagePhysical()
	return 1
end

function modifier_banished_enemy:CheckState()
	return {
		[MODIFIER_STATE_DISARMED] = true,
		[MODIFIER_STATE_ATTACK_IMMUNE] = true,
	}
end

function modifier_banished_enemy:GetEffectName()
	return "particles/units/heroes/hero_pugna/pugna_decrepify.vpcf"
end

function modifier_banished_enemy:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end
