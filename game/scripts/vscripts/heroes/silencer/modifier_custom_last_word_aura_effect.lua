if modifier_custom_last_word_aura_effect == nil then
	modifier_custom_last_word_aura_effect = class({})
end

function modifier_custom_last_word_aura_effect:IsHidden()
	return false
end

function modifier_custom_last_word_aura_effect:IsPurgable()
	return false
end

function modifier_custom_last_word_aura_effect:IsDebuff()
	return true
end

function modifier_custom_last_word_aura_effect:OnCreated()
	-- maybe some particle
end

function modifier_custom_last_word_aura_effect:OnRefresh()
	-- maybe some particle
end

function modifier_custom_last_word_aura_effect:OnDestroy()
	-- maybe some particle
end

function modifier_custom_last_word_aura_effect:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_SPENT_MANA,
	}

	return funcs
end

function modifier_custom_last_word_aura_effect:OnSpentMana(event)
	local parent = self:GetParent()
	local caster = self:GetCaster()
	local ability = self:GetAbility()

	if caster:PassivesDisabled() then
		return nil
	end

	if IsServer() and event.unit == parent then
		local cast_ability = event.ability
		local forbidden_ability_behavior = bit.bor(DOTA_ABILITY_BEHAVIOR_UNIT_TARGET, DOTA_ABILITY_BEHAVIOR_AUTOCAST, DOTA_ABILITY_BEHAVIOR_ATTACK)

		local cast_ability_behavior
		-- If there isn't a cast ability, or if its mana cost was zero, then do nothing
		if not cast_ability or cast_ability:GetManaCost(cast_ability:GetLevel() - 1) == 0 then
			return nil
		else
			cast_ability_behavior = cast_ability:GetBehavior()
		end

		-- If cast ability is autocasted and an attack ability then do nothing
		if cast_ability_behavior == forbidden_ability_behavior then
			return nil
		end

		-- If casted_ability is an item then do nothing
		if cast_ability:IsItem() then
			return nil
		end

		local duration = ability:GetSpecialValueFor("silence_duration_passive")
		parent:AddNewModifier(caster, ability, "modifier_custom_last_word_silence_passive", {duration = duration})
	end
end
