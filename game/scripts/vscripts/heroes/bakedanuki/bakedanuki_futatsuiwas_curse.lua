bakedanuki_futatsuiwas_curse = class({})

LinkLuaModifier( "modifier_bakedanuki_futatsuiwas_curse", "heroes/bakedanuki/modifier_bakedanuki_futatsuiwas_curse", LUA_MODIFIER_MOTION_NONE )

function bakedanuki_futatsuiwas_curse:OnAbilityPhaseStart()
	self:PlayEffects1()
	return true -- if success
end

function bakedanuki_futatsuiwas_curse:OnSpellStart()
	-- unit identifier
	local caster = self:GetCaster()

	-- load data
	local duration = self:GetSpecialValueFor( "hex_duration" )
	local radius = self:GetSpecialValueFor( "search_radius" )
	local range = self:GetSpecialValueFor( "search_range" )
	local point = caster:GetOrigin() + caster:GetForwardVector() * range

	-- find enemies in the area in front of the caster (like Shadowraze)
	local enemies = FindUnitsInRadius(
		caster:GetTeamNumber(),	-- int, your team number
		point,	-- point, center point
		nil,	-- handle, cacheUnit. (not known)
		radius,	-- float, radius. or use FIND_UNITS_EVERYWHERE
		DOTA_UNIT_TARGET_TEAM_ENEMY,	-- int, team filter
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,	-- int, type filter
		DOTA_UNIT_TARGET_FLAG_NONE,	-- int, flag filter
		FIND_ANY_ORDER,	-- int, order filter
		false	-- bool, can grow cache
	)

	-- if no unit found, return
	if #enemies<1 then
		return
	end

	-- filter target unit: hero, creep-hero, illusion, summon, creep
	local filter = {}
	local target
	for _, enemy in pairs(enemies) do
		if enemy:IsRealHero() then
			filter[1] = enemy
		elseif enemy:IsConsideredHero() then
			filter[2] = enemy
		elseif enemy:IsOwnedByAnyPlayer() then
			filter[3] = enemy
		else
			filter[4] = enemy
		end
	end
	for i = 1, 4 do
		if filter[i] then
			target = filter[i]
			break
		end
	end

	if target then
		-- Get real duration
		local real_duration = target:GetValueChangedByStatusResistance(duration)
		-- Add modifier
		target:AddNewModifier(caster, self, "modifier_bakedanuki_futatsuiwas_curse", {duration = real_duration})
	end

	self:PlayEffects2()
end

function bakedanuki_futatsuiwas_curse:PlayEffects1()
	-- Get Resources
	local particle_cast = "particles/units/heroes/hero_dark_willow/dark_willow_wisp_spell_marker.vpcf"
	local sound_cast = "Hero_DarkWillow.Fear.Location"

	-- Get data
	local caster = self:GetCaster()
	local radius = self:GetSpecialValueFor( "search_radius" )
	local range = self:GetSpecialValueFor( "search_range" )
	local point = caster:GetOrigin() + caster:GetForwardVector() * range

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, nil )
	ParticleManager:SetParticleControl( effect_cast, 0, point )
	ParticleManager:SetParticleControl( effect_cast, 1, Vector(radius+50, radius+50, radius+50) )
	ParticleManager:ReleaseParticleIndex( effect_cast )

	EmitSoundOnLocationWithCaster( point, sound_cast, caster )
end

function bakedanuki_futatsuiwas_curse:PlayEffects2()
	-- Get Resources
	local particle_cast = "particles/units/heroes/hero_dark_willow/dark_willow_wisp_spell.vpcf"

	-- Get data
	local caster = self:GetCaster()
	local radius = self:GetSpecialValueFor( "search_radius" )
	local range = self:GetSpecialValueFor( "search_range" )
	local point = caster:GetOrigin() + caster:GetForwardVector() * range

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, nil )
	ParticleManager:SetParticleControl( effect_cast, 0, point )
	ParticleManager:SetParticleControl( effect_cast, 1, Vector(radius, radius, radius) )
	ParticleManager:ReleaseParticleIndex( effect_cast )
end
