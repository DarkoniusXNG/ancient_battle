-- Called OnAttackLanded
function DesolateCheck(event)
	local caster = event.caster
	local target = event.target
	local ability = event.ability
	
	if target.GetInvulnCount == nil then -- if not target:IsBuilding() then
		local target_location = target:GetAbsOrigin()
		local ability_level = ability:GetLevel() - 1
		local radius = ability:GetLevelSpecialValueFor("radius", ability_level)
		local agi_dmg_multiplier = ability:GetLevelSpecialValueFor("damage_multiplier", ability_level)
		
		-- Calculate damage
		local caster_agility = caster:GetAgility()
		local desolate_damage = math.ceil(caster_agility*agi_dmg_multiplier)
		
		local damage_table = {}
		damage_table.attacker = caster
		damage_table.damage_type = ability:GetAbilityDamageType()
		damage_table.ability = ability
		damage_table.victim = target
		damage_table.damage = desolate_damage
		
		-- Finding target's allies in a radius
		local enemies = FindUnitsInRadius(target:GetTeam(), target_location, nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 0, 0, false)
		-- Number of enemies around the target hero or unit
		local number_of_nearby_enemies = #enemies
		
		if number_of_nearby_enemies < 2 then
			-- Applying the damage
			ApplyDamage(damage_table)
			-- Particle
			local particleName = "particles/units/heroes/hero_riki/riki_backstab.vpcf"
			local particle = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN_FOLLOW, target)
			Timers:CreateTimer(1.0, function()
				ParticleManager:DestroyParticle(particle,false)
			end)
			-- Sound
			caster:EmitSound("Hero_Riki.Backstab")
		end
	end
end