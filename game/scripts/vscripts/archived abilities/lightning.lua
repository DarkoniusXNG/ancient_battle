function Lightning( event )
	if event.target.GetInvulnCount == nil then
		-- event.target:IsTower() == false - with this condition only towers are affected, barracks and throne are not
		
		-- Basic variables
		local caster = event.caster
		local target = event.target
		local ability = event.ability
		
		-- Derived variables
		local caster_position = caster:GetAbsOrigin()
		local caster_team = caster:GetTeamNumber()
		local target_position = target:GetAbsOrigin()
		local ability_level = ability:GetLevel() - 1
		
		-- Damage and damage type
		local lightning_damage = ability:GetAbilityDamage()
		local lightning_damage_type = ability:GetAbilityDamageType()
		
		-- Ability specials
		local max_units = ability:GetLevelSpecialValueFor("max_units", ability_level)
		local radius = ability:GetLevelSpecialValueFor("radius", ability_level)
		
		-- Enemies in a radius around target hit
		local units = FindUnitsInRadius(caster_team, target_position, target, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, true)

		-- Particle on main target
		local lightningBolt = ParticleManager:CreateParticle("particles/items_fx/chain_lightning.vpcf", PATTACH_WORLDORIGIN, caster)
		ParticleManager:SetParticleControl(lightningBolt,0,Vector(caster_position.x,caster_position.y,caster_position.z + caster:GetBoundingMaxs().z ))	
		ParticleManager:SetParticleControl(lightningBolt,1,Vector(target_position.x,target_position.y,target_position.z + target:GetBoundingMaxs().z ))
		
		-- Damage the main target
		ApplyDamage({ victim = target, attacker = caster, damage = lightning_damage, damage_type = lightning_damage_type })
		
		-- Sound
		target:EmitSound("Hero_Zuus.ArcLightning.Target")
		
		-- Damaging other units and counting how many units we damaged
		local units_hit = 1
		for _,v in pairs(units) do
			if units_hit < max_units and v ~= target then
				local lightningBolt2 = ParticleManager:CreateParticle("particles/items_fx/chain_lightning.vpcf", PATTACH_WORLDORIGIN, caster)
				ParticleManager:SetParticleControl(lightningBolt2,0,Vector(caster_position.x,caster_position.y,caster_position.z + caster:GetBoundingMaxs().z ))	
				ParticleManager:SetParticleControl(lightningBolt2,1,Vector(v:GetAbsOrigin().x,v:GetAbsOrigin().y,v:GetAbsOrigin().z + v:GetBoundingMaxs().z ))	
				ApplyDamage({ victim = v, attacker = caster, damage = lightning_damage, damage_type = lightning_damage_type })
				units_hit = units_hit + 1
			end
		end
	end
end