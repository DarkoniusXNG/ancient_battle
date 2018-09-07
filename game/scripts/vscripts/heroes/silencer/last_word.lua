-- Called OnSpellStart
function LastWordStart(event)	
	local target = event.target
	local caster = event.caster
	local ability = event.ability
	
	-- Checking if target has spell block, if target has spell block, there is no need to execute the spell
	if not target:TriggerSpellAbsorb(ability) then
		ability:ApplyDataDrivenModifier(caster, target, "modifier_last_word_active", {})
		
		if caster:GetName() ~= "npc_dota_hero_silencer" then
			caster:RemoveModifierByName("modifier_last_word_aura_applier")
		end
	end
end

-- Called OnSpentMana inside modifier_last_word_aura_effect
function SpellCastCheckPassive(keys)
	local caster = keys.caster
	local target = keys.unit
	local ability = keys.ability
	local cast_ability = keys.event_ability
	
	local forbidden_ability_behavior = bit.bor(DOTA_ABILITY_BEHAVIOR_UNIT_TARGET, DOTA_ABILITY_BEHAVIOR_AUTOCAST, DOTA_ABILITY_BEHAVIOR_ATTACK)
	
	-- If the ability was unlearned, or lotus orb reflected and the aura_applier stayed on the target for some reason, then we do this:
	if not ability then
		caster:RemoveModifierByName("modifier_last_word_aura_applier")
		return nil
	end
	
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
	
	ability:ApplyDataDrivenModifier(caster, target, "modifier_last_word_silence_passive",{})
end

-- Called OnSpentMana inside modifier_last_word_active
function SpellCastCheckActive(keys)
	local caster = keys.caster
	local target = keys.unit
	local ability = keys.ability
	local cast_ability = keys.event_ability
	
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
	
	target:RemoveModifierByName("modifier_last_word_active")
	
	-- ability is nil if last word is reflected by lotus orb because its on the target which doesn't have the actual Last Word ability
	if ability then
		ability:ApplyDataDrivenModifier(caster, target, "modifier_last_word_silence_active",{})
	else
		return nil
	end
end

-- Called OnDestroy inside modifier_last_word_active
function LastWordStopSound(keys)
	local sound_name = "Hero_Silencer.LastWord.Target"
	local target = keys.target

	StopSoundEvent(sound_name, target)
	StopSoundOn(sound_name, target)
end

-- Called OnCreated inside modifier_last_word_silence_active and modifier_custom_last_word_disarm_debuff
function LastWordDamage(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	
	local full_damage = ability:GetLevelSpecialValueFor("damage", ability:GetLevel() - 1)
	local actual_damage = full_damage*0.5
	
	local damage_table = {}
	damage_table.victim = target
	damage_table.attacker = caster
	damage_table.damage = actual_damage
	damage_table.damage_type = ability:GetAbilityDamageType()
	damage_table.ability = ability
	
	ApplyDamage(damage_table)
end
