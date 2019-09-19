-- Called OnSpellStart
function Cripple(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local target_location = target:GetAbsOrigin()
	local blink_disable_damage = 50
	
	-- Checking if target has spell block, if target has spell block, there is no need to execute the spell
	if not target:TriggerSpellAbsorb(ability) then
		--print("Target doesn't have Spell Block.")
		ability:ApplyDataDrivenModifier(caster, target, "item_modifier_custom_rod_of_atos_crippled", nil)
		ApplyDamage({victim = target, attacker = caster, ability = ability, damage = blink_disable_damage, damage_type = ability:GetAbilityDamageType()})
		-- Sound
		EmitSoundOnLocationWithCaster(target_location, "DOTA_Item.RodOfAtos.Target", caster) -- DOTA_Item.RodOfAtos.Activate
	end
end
