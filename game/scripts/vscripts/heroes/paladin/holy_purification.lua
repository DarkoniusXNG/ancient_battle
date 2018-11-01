if paladin_holy_purification == nil then
	paladin_holy_purification = class({})
end

function paladin_holy_purification:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function paladin_holy_purification:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	
	local caster_team = caster:GetTeamNumber()
	local target_team = target:GetTeamNumber()
	
	local radius = self:GetSpecialValueFor("radius")
	local damage_and_heal = self:GetSpecialValueFor("heal")
	
	local heal_particle_name_1 = "particles/units/heroes/hero_omniknight/omniknight_purification.vpcf"
	local heal_particle_name_2 = "particles/econ/items/omniknight/hammer_ti6_immortal/omniknight_purification_immortal_cast.vpcf"
	local heal_hit_particle_name = "particles/units/heroes/hero_omniknight/omniknight_purification_hit.vpcf"
	
	
	if IsServer() then
		-- Init damage table
		local damage_table = {}
		damage_table.attacker = caster
		damage_table.damage = damage_and_heal
		damage_table.damage_type = DAMAGE_TYPE_PURE
		damage_table.ability = self
		
		-- Check if the target is an ally or enemy
		if caster_team == target_team then
			-- Sound on target (ally)
			target:EmitSound("Hero_Omniknight.Purification")
			
			-- Heal Particle
			local heal_particle = ParticleManager:CreateParticle(heal_particle_name_1, PATTACH_ABSORIGIN_FOLLOW, target)
			ParticleManager:SetParticleControl(heal_particle, 0, target:GetAbsOrigin())
			ParticleManager:SetParticleControl(heal_particle, 1, Vector(radius, radius, radius))
			ParticleManager:ReleaseParticleIndex(heal_particle)
			
			-- Heal the target (ally)
			target:Heal(damage_and_heal, self)

			local target_teams = DOTA_UNIT_TARGET_TEAM_ENEMY
			local target_types = bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC)
			local target_flags = DOTA_UNIT_TARGET_FLAG_NONE

			local enemies = FindUnitsInRadius(caster_team, target:GetAbsOrigin(), nil, radius, target_teams, target_types, target_flags, FIND_CLOSEST, false)
			for _,enemy in pairs(enemies) do
				-- Particles on enemies
				local hit_pfx = ParticleManager:CreateParticle(heal_hit_particle_name, PATTACH_ABSORIGIN_FOLLOW, enemy)
				ParticleManager:SetParticleControlEnt(hit_pfx, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
				ParticleManager:SetParticleControlEnt(hit_pfx, 1, enemy, PATTACH_POINT_FOLLOW, "attach_hitloc", enemy:GetAbsOrigin(), true)
				ParticleManager:SetParticleControl(hit_pfx, 3, Vector(radius, 0, 0))
				ParticleManager:ReleaseParticleIndex(hit_pfx)
				
				local particle = ParticleManager:CreateParticle(heal_particle_name_2, PATTACH_ABSORIGIN_FOLLOW, enemy)
				ParticleManager:SetParticleControl(particle, 0, enemy:GetAbsOrigin())
				ParticleManager:SetParticleControl(particle, 1, enemy:GetAbsOrigin())
				ParticleManager:ReleaseParticleIndex(particle)
				
				-- Damage enemies
				damage_table.victim = enemy
				ApplyDamage(damage_table)
			end
		else
			-- Spell block check
			if not target:TriggerSpellAbsorb(self) then
				-- Sound on target (enemy)
				target:EmitSound("Hero_Omniknight.Purification")
				
				-- Particles when cast on enemy
				local heal_particle = ParticleManager:CreateParticle(heal_particle_name_1, PATTACH_ABSORIGIN_FOLLOW, target)
				ParticleManager:SetParticleControl(heal_particle, 0, target:GetAbsOrigin())
				ParticleManager:SetParticleControl(heal_particle, 1, Vector(radius/2, radius/2, radius/2))
				ParticleManager:ReleaseParticleIndex(heal_particle)
				
				local particle = ParticleManager:CreateParticle(heal_particle_name_2, PATTACH_ABSORIGIN_FOLLOW, target)
				ParticleManager:SetParticleControl(particle, 0, target:GetAbsOrigin())
				ParticleManager:SetParticleControl(particle, 1, target:GetAbsOrigin())
				ParticleManager:ReleaseParticleIndex(particle)

				-- invulnerability check
				if not target:IsInvulnerable() then
					damage_table.victim = target
					ApplyDamage(damage_table)
				end
				
				local target_teams = DOTA_UNIT_TARGET_TEAM_FRIENDLY
				local target_types = bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC)
				local target_flags = DOTA_UNIT_TARGET_FLAG_NONE
			
				local allies = FindUnitsInRadius(caster_team, target:GetAbsOrigin(), nil, radius, target_teams, target_types, target_flags, FIND_CLOSEST, false)
				for _,ally in pairs(allies) do
					-- Particles on allies
					local hit_pfx = ParticleManager:CreateParticle(heal_hit_particle_name, PATTACH_ABSORIGIN_FOLLOW, ally)
					ParticleManager:SetParticleControlEnt(hit_pfx, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
					ParticleManager:SetParticleControlEnt(hit_pfx, 1, ally, PATTACH_POINT_FOLLOW, "attach_hitloc", ally:GetAbsOrigin(), true)
					ParticleManager:SetParticleControl(hit_pfx, 3, Vector(radius, 0, 0))
					ParticleManager:ReleaseParticleIndex(hit_pfx)
					
					-- Heal allies
					ally:Heal(damage_and_heal, self)
				end
			end
		end
	end
end

function paladin_holy_purification:ProcsMagicStick()
	return true
end

if guardian_angel_holy_purification == nil then
	guardian_angel_holy_purification = paladin_holy_purification
end
