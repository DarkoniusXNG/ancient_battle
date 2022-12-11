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
	local caster = self:GetCaster()
	local parent = self:GetParent()
	local ability = self:GetAbility()

	if IsServer() then
		-- Sound on unit (parent)
		parent:EmitSound("Hero_Silencer.LastWord.Target")

		if not ability or ability:IsNull() then
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
	if not IsServer() then
		return
	end

	local parent = self:GetParent()
	local caster = self:GetCaster()
	local ability = self:GetAbility()

	if not ability or ability:IsNull() then
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
	return {
		MODIFIER_PROPERTY_PROVIDES_FOW_POSITION,
		MODIFIER_EVENT_ON_SPENT_MANA,
	}
end

function modifier_custom_last_word_active:CheckState()
	return {
		[MODIFIER_STATE_PROVIDES_VISION] = true,
	}
end

function modifier_custom_last_word_active:GetModifierProvidesFOWVision()
	return 1
end

if IsServer() then
	function modifier_custom_last_word_active:OnSpentMana(event)
		local caster = self:GetCaster()
		local parent = self:GetParent()
		local ability = self:GetAbility()
		local cast_ability = event.ability

		-- Check if unit that spent mana has this modifier
		if event.unit ~= parent then
			return
		end

		local cast_ability_behavior
		-- If there isn't a cast ability, or if its mana cost was zero, do nothing
		if not cast_ability or cast_ability:GetManaCost(cast_ability:GetLevel() - 1) == 0 then
			return
		else
			cast_ability_behavior = cast_ability:GetBehavior()
			if type(cast_ability_behavior) == 'userdata' then
				cast_ability_behavior = tonumber(tostring(cast_ability_behavior))
			end
		end

		-- If cast ability is an attack ability (orb effect) then do nothing
		if HasBit(cast_ability_behavior, DOTA_ABILITY_BEHAVIOR_ATTACK) then
			return
		end

		-- Ignore items and check for spell reflect
		if cast_ability:IsItem() then
			return
		end

		-- Stop interval think
		self:StartIntervalThink(-1)

		-- Setting duration is safer instead of removing the modifier
		self:SetDuration(0.1, false)

		if not ability or ability:IsNull() then
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
		end
	end
end

function modifier_custom_last_word_active:GetEffectName()
	return "particles/units/heroes/hero_silencer/silencer_last_word_status.vpcf"
end

function modifier_custom_last_word_active:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end
