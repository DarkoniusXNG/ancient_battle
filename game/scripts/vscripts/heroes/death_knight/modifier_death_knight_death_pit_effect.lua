if modifier_death_knight_death_pit_effect == nil then
	modifier_death_knight_death_pit_effect = class({})
end

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

	self.move_speed_slow = ability:GetSpecialValueFor("move_speed_slow")
	self.heal_reduction = ability:GetSpecialValueFor("heal_reduction")
	self.bonus_lifesteal = ability:GetSpecialValueFor("bonus_lifesteal")

	if IsServer() then
		local parent = self:GetParent()
		local caster = ability:GetCaster() -- modifier:GetCaster() in this case will probably return a thinker and not a real caster of the spell

		-- Talent that increases healing reduction
		local talent = caster:FindAbilityByName("special_bonus_unique_death_knight_death_pit_heal_reduction")
		if talent then
			if talent:GetLevel() > 0 then
				self.heal_reduction = ability:GetSpecialValueFor("heal_reduction") + talent:GetSpecialValueFor("value")
			end
		end

		-- Sound on unit that is affected
		parent:EmitSound("Hero_AbyssalUnderlord.Pit.TargetHero")
	end
end

modifier_death_knight_death_pit_effect.OnRefresh = modifier_death_knight_death_pit_effect.OnCreated

function modifier_death_knight_death_pit_effect:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_EVENT_ON_HEALTH_GAINED,
		MODIFIER_EVENT_ON_TAKEDAMAGE
	}

	return funcs
end

function modifier_death_knight_death_pit_effect:GetModifierMoveSpeedBonus_Percentage()
	return self.move_speed_slow
end

function modifier_death_knight_death_pit_effect:OnHealthGained(event)
	if IsServer() then
		if event.unit == self:GetParent() and event.gain > 0 then
			local affected_unit = event.unit or self:GetParent()

			local heal_reduction = self.heal_reduction
			local new_heal_percentage = 1 - heal_reduction/100

			local original_health_gain = event.gain
			local new_health_gain = original_health_gain*new_heal_percentage

			local new_HP = affected_unit:GetHealth() - original_health_gain + new_health_gain
			new_HP = math.max(new_HP, 1)

			affected_unit:SetHealth(new_HP)
		end
	end
end

function modifier_death_knight_death_pit_effect:OnTakeDamage(event)
	if IsServer() then
		if event.unit == self:GetParent() and event.damage > 0 then
			local affected_unit = event.unit or self:GetParent()
			local lifesteal_percent = self.bonus_lifesteal
			local damage = event.damage
			local damage_flags = event.damage_flags
			local attacker = event.attacker

			if HasBit(damage_flags, DOTA_DAMAGE_FLAG_HPLOSS) or HasBit(damage_flags, DOTA_DAMAGE_FLAG_REFLECTION) or HasBit(damage_flags, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL) then
				return nil
			end

			if attacker == affected_unit then
				return nil
			end

			if not attacker:IsAlive() then
				return nil
			end
			
			local heal_amount = lifesteal_percent*damage/100
			attacker:Heal(heal_amount, self:GetAbility())
			
			-- Heal Amount message
			SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, attacker, heal_amount, nil)
			
			-- Lifesteal Particle
			local lifesteal_particle_name = "particles/generic_gameplay/generic_lifesteal.vpcf"
			local lifesteal_particle_index = ParticleManager:CreateParticle(lifesteal_particle_name, PATTACH_ABSORIGIN_FOLLOW, attacker)
			ParticleManager:SetParticleControl(lifesteal_particle_index, 0, attacker:GetAbsOrigin())
			ParticleManager:ReleaseParticleIndex(lifesteal_particle_index)
		end
	end
end
