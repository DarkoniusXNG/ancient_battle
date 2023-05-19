modifier_custom_last_word_aura_effect = class({})

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
	return {
		MODIFIER_EVENT_ON_SPENT_MANA,
	}
end

if IsServer() then
	function modifier_custom_last_word_aura_effect:OnSpentMana(event)
		local parent = self:GetParent()
		local caster = self:GetCaster()
		local ability = self:GetAbility()

		if caster:PassivesDisabled() then
			return
		end

		-- Check if unit that spent mana has this modifier
		if event.unit ~= parent then
			return
		end

		local cast_ability = event.ability
		local cast_ability_behavior
		-- If there isn't a cast ability, or if its mana cost was zero, then do nothing
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

		-- If casted_ability is an item then do nothing
		if cast_ability:IsItem() then
			return
		end

		local duration = ability:GetSpecialValueFor("silence_duration_passive")
		parent:AddNewModifier(caster, ability, "modifier_custom_last_word_silence_passive", {duration = duration})
	end
end
