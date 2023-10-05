modifier_death_knight_death_pit_effect = modifier_death_knight_death_pit_effect or class({})

function modifier_death_knight_death_pit_effect:IsHidden()
	return false
end

function modifier_death_knight_death_pit_effect:IsDebuff()
	return true
end

function modifier_death_knight_death_pit_effect:IsPurgable()
	return false
end

function modifier_death_knight_death_pit_effect:OnCreated()
	local ability = self:GetAbility()

	local move_speed_slow = -15
	local heal_reduction = 10
	local bonus_lifesteal = 20

	if ability and not ability:IsNull() then
		move_speed_slow = ability:GetSpecialValueFor("move_speed_slow")
		heal_reduction = ability:GetSpecialValueFor("heal_reduction")
		bonus_lifesteal = ability:GetSpecialValueFor("bonus_lifesteal")
	end

	if IsServer() then
		local parent = self:GetParent()
		local caster = ability:GetCaster() -- modifier:GetCaster() in this case will probably return a thinker and not a real caster of the spell

		if not caster:IsNull() then
			-- Talent that increases healing reduction
			local talent = caster:FindAbilityByName("special_bonus_unique_death_knight_4")
			if talent and talent:GetLevel() > 0 then
				heal_reduction = heal_reduction + talent:GetSpecialValueFor("value")
			end
		end

		-- Slow should be affected by status resistance
		self.move_speed_slow = parent:GetValueChangedByStatusResistance(move_speed_slow)

		-- Sound on unit that is affected
		parent:EmitSound("Hero_AbyssalUnderlord.Pit.TargetHero")
	else
		self.move_speed_slow = move_speed_slow
	end

	self.heal_reduction = heal_reduction
	self.bonus_lifesteal = bonus_lifesteal
end

modifier_death_knight_death_pit_effect.OnRefresh = modifier_death_knight_death_pit_effect.OnCreated

function modifier_death_knight_death_pit_effect:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
		MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET,
		MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE,
		MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE,
		--MODIFIER_EVENT_ON_HEALTH_GAINED,
		MODIFIER_EVENT_ON_TAKEDAMAGE
	}
end

function modifier_death_knight_death_pit_effect:GetModifierMoveSpeedBonus_Percentage()
	return 0 - math.abs(self.move_speed_slow)
end

-- function modifier_death_knight_death_pit_effect:OnHealthGained(event)
	-- if IsServer() then
		-- if event.unit == self:GetParent() and event.gain > 0 then
			-- local affected_unit = event.unit or self:GetParent()

			-- local heal_reduction = self.heal_reduction
			-- local new_heal_percentage = 1 - heal_reduction/100

			-- local original_health_gain = event.gain
			-- local new_health_gain = original_health_gain*new_heal_percentage

			-- local new_HP = affected_unit:GetHealth() - original_health_gain + new_health_gain
			-- new_HP = math.max(new_HP, 1)

			-- affected_unit:SetHealth(new_HP)
		-- end
	-- end
-- end

if IsServer() then
	function modifier_death_knight_death_pit_effect:OnTakeDamage(event)
		local parent = self:GetParent()
		local attacker = event.attacker
		local damaged_unit = event.unit
		local dmg_flags = event.damage_flags
		local damage = event.damage
		local inflictor = event.inflictor

		-- Check if attacker exists
		if not attacker or attacker:IsNull() then
			return
		end

		-- Check if damaged entity exists
		if not damaged_unit or damaged_unit:IsNull() then
			return
		end

		-- Check if damaged entity has this modifier
		if damaged_unit ~= parent then
			return
		end

		-- Ignore self damage
		if damaged_unit == attacker then
			return
		end

		-- Check if damaged entity is an item, rune or something weird
		if damaged_unit.GetUnitName == nil then
			return
		end

		-- Buildings, wards and invulnerable units can't lifesteal
		if attacker:IsTower() or attacker:IsBuilding() or attacker:IsOther() or attacker:IsInvulnerable() then
			return
		end

		-- Don't affect buildings, wards and invulnerable units. - this is not needed, left it here in case of some random changes in the future
		if damaged_unit:IsTower() or damaged_unit:IsBarracks() or damaged_unit:IsBuilding() or damaged_unit:IsOther() or damaged_unit:IsInvulnerable() then
			return
		end

		-- Check if attacker is dead
		if not attacker:IsAlive() then
			return
		end

		-- Check if damage is 0 or negative
		if damage <= 0 then
			return
		end

		-- Check for damage flags
		if HasBit(dmg_flags, DOTA_DAMAGE_FLAG_HPLOSS) or HasBit(dmg_flags, DOTA_DAMAGE_FLAG_REFLECTION) or HasBit(dmg_flags, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL) or HasBit(dmg_flags, DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION) then
			return
		end

		local lifesteal_percent = self.bonus_lifesteal
		local lifesteal_amount = lifesteal_percent * damage / 100

		if lifesteal_amount > 0 then
			local ability = self:GetAbility()

			-- Lifesteal amount message
			SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, attacker, lifesteal_amount, nil)

			if inflictor then
				-- Spell Lifesteal
				attacker:HealWithParams(lifesteal_amount, ability, false, true, attacker, true)

				local particle1 = ParticleManager:CreateParticle("particles/items3_fx/octarine_core_lifesteal.vpcf", PATTACH_ABSORIGIN_FOLLOW, attacker)
				ParticleManager:SetParticleControl(particle1, 0, attacker:GetAbsOrigin())
				ParticleManager:ReleaseParticleIndex(particle1)
			else
				-- Normal Lifesteal
				attacker:HealWithParams(lifesteal_amount, ability, true, true, attacker, false)

				local particle2 = ParticleManager:CreateParticle("particles/generic_gameplay/generic_lifesteal.vpcf", PATTACH_ABSORIGIN_FOLLOW, attacker)
				ParticleManager:ReleaseParticleIndex(particle2)
			end
		end
	end
end

function modifier_death_knight_death_pit_effect:GetModifierHPRegenAmplify_Percentage()
  return 0 - math.abs(self.heal_reduction)
end

function modifier_death_knight_death_pit_effect:GetModifierHealAmplify_PercentageTarget()
  return 0 - math.abs(self.heal_reduction)
end

function modifier_death_knight_death_pit_effect:GetModifierLifestealRegenAmplify_Percentage()
  return 0 - math.abs(self.heal_reduction)
end

function modifier_death_knight_death_pit_effect:GetModifierSpellLifestealRegenAmplify_Percentage()
  return 0 - math.abs(self.heal_reduction)
end
