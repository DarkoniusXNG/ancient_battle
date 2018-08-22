-- Called OnSpellStart
function ManaFlareStart(event)
	local caster = event.caster
	
	caster:StartGesture(ACT_DOTA_RUN)
end

-- Called OnChannelFinish or OnChannelInterrupted
function ManaFlareEnd(event)
	local caster = event.caster
	
	caster:RemoveGesture(ACT_DOTA_RUN)
	caster:InterruptChannel()
	caster:StopSound("Hero_Juggernaut.HealingWard.Loop")
	
	if caster:HasModifier("modifier_mana_flare_armor_buff") then
		caster:RemoveModifierByName("modifier_mana_flare_armor_buff")
	end
	if caster:HasModifier("modifier_mana_flare_aura_applier") then
		caster:RemoveModifierByName("modifier_mana_flare_aura_applier")
	end
end

-- Called OnSpentMana inside modifier_mana_flare_debuff
function ManaFlareDamage(event)
	local caster = event.caster
	local unit = event.unit
	local ability = event.ability
	local ability_cast = event.event_ability
	local mana_cost = ability_cast:GetManaCost(-1)
	local damage_per_used_mana = ability:GetLevelSpecialValueFor("damage_per_used_mana", ability:GetLevel() - 1)
	local damage_type = ability:GetAbilityDamageType()

	-- If the ability or item has no mana cost -> do nothing
	if mana_cost == 0 then
		return
	end

	-- Calculating and applying damage
	local mana_flare_damage = mana_cost * damage_per_used_mana
	ApplyDamage({victim = unit, attacker = caster, ability = ability, damage = mana_flare_damage, damage_type = damage_type})

	-- Sounds
	unit:EmitSound("Hero_Pugna.NetherWard.Target")
	caster:EmitSound("Hero_Pugna.NetherWard.Attack")
	
	-- Basic particles
	local attackName = "particles/units/heroes/hero_pugna/pugna_ward_attack.vpcf"
	local attack = ParticleManager:CreateParticle(attackName, PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(attack, 1, unit:GetAbsOrigin())

	-- Additional particles
	if mana_flare_damage < 150 then
		local attackName = "particles/units/heroes/hero_pugna/pugna_ward_attack_light.vpcf"
		local attack = ParticleManager:CreateParticle(attackName, PATTACH_ABSORIGIN_FOLLOW, caster)
		ParticleManager:SetParticleControl(attack, 1, unit:GetAbsOrigin())
	elseif mana_flare_damage < 250 then
		local attackName = "particles/units/heroes/hero_pugna/pugna_ward_attack_medium.vpcf"
		local attack = ParticleManager:CreateParticle(attackName, PATTACH_ABSORIGIN_FOLLOW, caster)
		ParticleManager:SetParticleControl(attack, 1, unit:GetAbsOrigin())
	else
		local attackName = "particles/units/heroes/hero_pugna/pugna_ward_attack_heavy.vpcf"
		local attack = ParticleManager:CreateParticle(attackName, PATTACH_ABSORIGIN_FOLLOW, caster)
		ParticleManager:SetParticleControl(attack, 1, unit:GetAbsOrigin())
	end	
end