-- Called OnSpellStart
function BerserkStart(event)
	local caster = event.caster
	local ability = event.ability
	
	local duration = ability:GetLevelSpecialValueFor("duration", ability:GetLevel() - 1)
	
	if caster:IsRangedAttacker() then
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_item_custom_berserk_ranged", {["duration"] = duration})
	else
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_item_custom_berserk_melee", {["duration"] = duration})
	end
end

-- Called OnAttackLanded
function LifestealOnAttackLanded(keys)
	local target = keys.target
	local ability = keys.ability
	local attacker = keys.attacker
	local damage_on_attack = keys.DamageOnAttack
	
	local lifesteal_melee = ability:GetLevelSpecialValueFor("lifesteal_percent_melee", ability:GetLevel() - 1)
	local lifesteal_ranged = ability:GetLevelSpecialValueFor("lifesteal_percent_ranged", ability:GetLevel() - 1)
	
	if target and attacker then
		if (target.GetInvulnCount == nil) then
			if attacker:IsRealHero() then
				if not HasOtherUniqueAttackModifiers(attacker) then
					local lifesteal_amount
					if attacker:IsRangedAttacker() then
						lifesteal_amount = damage_on_attack*lifesteal_ranged*0.01
					else
						lifesteal_amount = damage_on_attack*lifesteal_melee*0.01
					end
					if lifesteal_amount > 0 and attacker:IsAlive() then
						attacker:Heal(lifesteal_amount, attacker)
						local lifesteal_particle = "particles/generic_gameplay/generic_lifesteal.vpcf"
						local lifesteal_fx = ParticleManager:CreateParticle(lifesteal_particle, PATTACH_ABSORIGIN_FOLLOW, attacker)
						ParticleManager:SetParticleControl(lifesteal_fx, 0, attacker:GetAbsOrigin())
						ParticleManager:ReleaseParticleIndex(lifesteal_fx)
					end
				end
			else
				local lifesteal_particle = "particles/generic_gameplay/generic_lifesteal.vpcf"
				local lifesteal_fx = ParticleManager:CreateParticle(lifesteal_particle, PATTACH_ABSORIGIN_FOLLOW, attacker)
				ParticleManager:SetParticleControl(lifesteal_fx, 0, attacker:GetAbsOrigin())
				ParticleManager:ReleaseParticleIndex(lifesteal_fx)
			end
		end
	end
end

function HasOtherUniqueAttackModifiers(unit)

	local list_of_passive_orbs ={
	"modifier_item_mask_of_death",
	"modifier_item_satanic"
	}
	
	local list_of_autocast_orbs ={
	"modifier_dark_arrow",
	"modifier_incinerate_orb",
	"modifier_glaives_of_silence_orb"
	}
	
	if unit then
		for i = 1, #list_of_passive_orbs do
			if unit:HasModifier(list_of_passive_orbs[i]) then
				return true
			end
		end
		
		for j = 1, #list_of_autocast_orbs do
			local current_modifier_name = list_of_autocast_orbs[j]
			if unit:HasModifier(current_modifier_name) then
				local modifier = unit:FindModifierByName(current_modifier_name)
				if modifier then
					local ability = modifier:GetAbility()
					if ability then
						if ability:GetAutoCastState() then
							return true
						end
					end
				end
			end
		end
		
		return false
	end
end