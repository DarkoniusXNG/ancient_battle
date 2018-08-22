-- Called OnSpellStart
function TransmuteStart(event)
	local target = event.target
	local caster = event.caster
	local ability = event.ability
	local ability_level = ability:GetLevel() - 1
	
	local stun_hero_duration = ability:GetLevelSpecialValueFor("stun_duration", ability_level)
	local gold_bounty_multiplier = ability:GetLevelSpecialValueFor("gold_bounty_multiplier", ability_level)
	
	-- Checking if target has spell block, if target has spell block, there is no need to execute the spell
	if not target:TriggerSpellAbsorb(ability) then
		if target:IsHero() then
			-- Target is a real hero or illusion of a hero.
			ability:ApplyDataDrivenModifier(caster, target, "modifier_custom_transmuted_hero", {["duration"] = stun_hero_duration})
		else
			local gold_bounty = target:GetGoldBounty()
			local new_gold_bounty = math.ceil(gold_bounty * gold_bounty_multiplier)
			target:SetMinimumGoldBounty(new_gold_bounty)
			target:SetMaximumGoldBounty(new_gold_bounty)
			target:AddNoDraw()
			local particle = ParticleManager:CreateParticle("particles/items2_fx/hand_of_midas.vpcf",PATTACH_CUSTOMORIGIN,nil)
			ParticleManager:SetParticleControlEnt(particle, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
			ParticleManager:SetParticleControlEnt(particle, 1, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
			target:Kill(nil, caster) -- Kill the creep. This increments the caster's last hit counter.
			
			-- Message Particle, has a bunch of options
			local symbol = 0 -- "+" presymbol
			local color = Vector(255, 200, 33) -- Gold color
			local lifetime = 2
			local digits = string.len(new_gold_bounty) + 1
			local particleName = "particles/units/heroes/hero_alchemist/alchemist_lasthit_msg_gold.vpcf"
			local particle = ParticleManager:CreateParticle( particleName, PATTACH_ABSORIGIN, target)
			ParticleManager:SetParticleControl(particle, 1, Vector(symbol, new_gold_bounty, symbol))
			ParticleManager:SetParticleControl(particle, 2, Vector(lifetime, digits, 0))
			ParticleManager:SetParticleControl(particle, 3, color)
		end
	end
end