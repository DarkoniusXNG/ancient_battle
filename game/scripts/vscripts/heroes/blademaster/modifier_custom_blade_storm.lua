if modifier_custom_blade_storm == nil then
	modifier_custom_blade_storm = class({})
end

function modifier_custom_blade_storm:IsHidden()
	return false
end

function modifier_custom_blade_storm:IsDebuff()
	return false
end

function modifier_custom_blade_storm:IsPurgable()
	return false
end

function modifier_custom_blade_storm:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL
	}

	return funcs
end

function modifier_custom_blade_storm:GetOverrideAnimation(params)
	return ACT_DOTA_OVERRIDE_ABILITY_1
end

function modifier_custom_blade_storm:GetAbsoluteNoDamageMagical()
	return 1
end

function modifier_custom_blade_storm:CheckState()
	local state = {
	[MODIFIER_STATE_MAGIC_IMMUNE] = true,
	[MODIFIER_STATE_SILENCED] = true,
	}

	return state
end

function modifier_custom_blade_storm:OnCreated()
	local parent = self:GetParent()
	local ability = self:GetAbility()

	local radius = ability:GetSpecialValueFor("radius")
	local think_interval = ability:GetSpecialValueFor("think_interval")

	if IsServer() then
		-- Particle
		local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_juggernaut/juggernaut_blade_fury.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
		--ParticleManager:SetParticleControlEnt(particle, 0, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
		ParticleManager:SetParticleControl(particle, 5, Vector(radius, 0, 0))
		self.blade_storm_particle = particle
	
		-- Sound
		parent:EmitSound("Hero_Juggernaut.BladeFuryStart")

		-- Start thinking
		self:StartIntervalThink(think_interval)
	end
end

function modifier_custom_blade_storm:OnIntervalThink()
	local parent = self:GetParent()
	local ability = self:GetAbility()
	
	local damage_per_second = ability:GetSpecialValueFor("damage_per_second")
	local think_interval = ability:GetSpecialValueFor("think_interval")
	local radius = ability:GetSpecialValueFor("radius")
	local damage_to_buildings_percent = ability:GetSpecialValueFor("damage_to_buildings")
	
	if IsServer then
		local damage_per_tick = damage_per_second*think_interval
		local damage_to_buildings = damage_per_tick*damage_to_buildings_percent/100
		local parent_team = parent:GetTeamNumber()
		local parent_position = parent:GetAbsOrigin()
		
		-- Targetting constants
		local target_team = ability:GetAbilityTargetTeam() or DOTA_UNIT_TARGET_TEAM_ENEMY
		local target_type = bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
		local target_flags = ability:GetAbilityTargetFlags() or DOTA_UNIT_TARGET_FLAG_NONE
		
		-- Creating the damage table
		local damage_table = {}
		damage_table.attacker = parent
		damage_table.damage_type = ability:GetAbilityDamageType() or DAMAGE_TYPE_MAGICAL
		damage_table.ability = ability

		-- Damage enemies (not buildings) in a radius
		local enemies = FindUnitsInRadius(parent_team, parent_position, nil, radius, target_team, target_type, target_flags, FIND_ANY_ORDER, false)
		for _, enemy in pairs(enemies) do
			-- Sound on enemy
			enemy:EmitSound("Hero_Juggernaut.BladeFury.Impact")
			-- Apply damage
			damage_table.victim = enemy
			damage_table.damage = damage_per_tick
			ApplyDamage(damage_table)
		end
		
		-- Damage enemy buildings in a radius
		local buildings = FindUnitsInRadius(parent_team, parent_position, nil, radius, target_team, DOTA_UNIT_TARGET_BUILDING, target_flags, FIND_ANY_ORDER, false)
		for _, enemy_building in pairs(buildings) do
			-- Sound on building
			enemy_building:EmitSound("Hero_Juggernaut.BladeFury.Impact")
			-- Apply damage
			damage_table.victim = enemy_building
			damage_table.damage = damage_to_buildings
			ApplyDamage(damage_table)
		end
	end
end

function modifier_custom_blade_storm:OnDestroy()
	local parent = self:GetParent()
	if IsServer() then
		-- Stop the looping sound
		parent:StopSound("Hero_Juggernaut.BladeFuryStart")
		
		-- New Sound
		parent:EmitSound("Hero_Juggernaut.BladeFuryStop")
		
		-- Destroy particle
		if self.blade_storm_particle then
			ParticleManager:DestroyParticle(self.blade_storm_particle, true)
			ParticleManager:ReleaseParticleIndex(self.blade_storm_particle)
		end
	end
end
