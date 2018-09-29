if modifier_custom_last_word_active == nil then
	modifier_custom_last_word_active = class({})
end

function modifier_custom_last_word_active:IsHidden()
	return false
end

function modifier_custom_last_word_active:IsDebuff()
	return true
end

function modifier_custom_last_word_active:IsPurgable()
	return true
end

function modifier_custom_last_word_active:OnCreated()
	local parent = self:GetParent()
	local ability = self:GetAbility()
	
	if IsServer() then
		-- Sound on unit (parent)
		parent:EmitSound("Hero_Silencer.LastWord.Target")
		
		if ability == nil then
			-- Lotus Orb fix
			ability = caster:FindAbilityByName("silencer_custom_last_word") or parent:FindAbilityByName("silencer_custom_last_word")
		end
		
		if ability then
			local timer_duration = ability:GetSpecialValueFor("debuff_duration")
			self:StartIntervalThink(timer_duration)
		end
	end
end

function modifier_custom_last_word_active:OnIntervalThink()
	local parent = self:GetParent()
	local caster = self:GetCaster()
	local ability = self:GetAbility()

	if IsServer() then
		if ability == nil then
			-- Lotus Orb fix
			ability = caster:FindAbilityByName("silencer_custom_last_word") or parent:FindAbilityByName("silencer_custom_last_word")
		end

		if ability then
			local silence_duration = ability:GetSpecialValueFor("silence_duration_active")
			local disarm_duration = ability:GetSpecialValueFor("disarm_duration")
			parent:AddNewModifier(caster, ability, "modifier_custom_last_word_silence_active", {duration = silence_duration})
			parent:AddNewModifier(caster, ability, "modifier_custom_last_word_disarm", {duration = disarm_duration})

			-- Damage
			local full_damage = ability:GetSpecialValueFor("damage")
			
			local damage_table = {}
			damage_table.victim = parent
			damage_table.attacker = caster
			damage_table.damage = full_damage
			damage_table.damage_type = ability:GetAbilityDamageType()
			damage_table.ability = ability

			ApplyDamage(damage_table)
		else
			return nil
		end
	end
end

function modifier_custom_last_word_active:OnDestroy()
	local sound_name = "Hero_Silencer.LastWord.Target"
	local parent = self:GetParent()
	
	if IsServer() then
		parent:StopSound(sound_name)
	end
end

function modifier_custom_last_word_active:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_PROVIDES_FOW_POSITION,
		MODIFIER_EVENT_ON_SPENT_MANA,
	}

	return funcs
end

function modifier_custom_last_word_active:CheckState()
	local state = {
	[MODIFIER_STATE_PROVIDES_VISION] = true,
	}

	return state
end

function modifier_custom_last_word_active:GetModifierProvidesFOWVision()
	return 1
end

function modifier_custom_last_word_active:OnSpentMana(event)
	local caster = self:GetCaster()
	local parent = self:GetParent()
	local ability = self:GetAbility()
	local cast_ability = event.ability
	
	if IsServer() and event.unit == parent then
		local forbidden_ability_behavior = bit.bor(DOTA_ABILITY_BEHAVIOR_UNIT_TARGET, DOTA_ABILITY_BEHAVIOR_AUTOCAST, DOTA_ABILITY_BEHAVIOR_ATTACK)

		local cast_ability_behavior
		-- If there isn't a cast ability, or if its mana cost was zero, do nothing
		if not cast_ability or cast_ability:GetManaCost(cast_ability:GetLevel() - 1) == 0 then
			return nil
		else
			cast_ability_behavior = cast_ability:GetBehavior()
		end
		
		-- If cast ability is autocasted and an attack ability then do nothing
		if cast_ability_behavior == forbidden_ability_behavior then
			return nil
		end
		
		-- Ignore items and check for spell reflect
		if cast_ability:IsItem() then
			return nil
		end
		
		-- Stop interval think
		self:StartIntervalThink(-1)
		
		-- Setting duration is safer instead of removing the modifier
		self:SetDuration(0.1, false)
		
		if ability == nil then
			-- Lotus Orb fix
			ability = caster:FindAbilityByName("silencer_custom_last_word") or parent:FindAbilityByName("silencer_custom_last_word")
		end
		
		if ability then
			local silence_duration = ability:GetSpecialValueFor("silence_duration_active")
			parent:AddNewModifier(caster, ability, "modifier_custom_last_word_silence_active", {duration = silence_duration})
			
			-- Damage
			local full_damage = ability:GetSpecialValueFor("damage")
			
			local damage_table = {}
			damage_table.victim = parent
			damage_table.attacker = caster
			damage_table.damage = full_damage/2
			damage_table.damage_type = ability:GetAbilityDamageType()
			damage_table.ability = ability

			ApplyDamage(damage_table)
		else
			return nil
		end
	end
end

function modifier_custom_last_word_active:GetEffectName()
	return "particles/units/heroes/hero_silencer/silencer_last_word_status.vpcf"
end

function modifier_custom_last_word_active:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end