perun_ion_blast = perun_ion_blast or class({})

function perun_ion_blast:GetCastRange(location, target)
	local caster = self:GetCaster()
	local base_cast_range = self.BaseClass.GetCastRange(self, location, target)

	-- Talent that makes it global
	local talent = caster:FindAbilityByName("special_bonus_unique_perun_4")
	if talent and talent:GetLevel() > 0 then
		return talent:GetSpecialValueFor("value")
	end

	return base_cast_range
end

function perun_ion_blast:OnSpellStart()
	local caster = self:GetCaster()
	local caster_pos = caster:GetOrigin()

	-- KV variables
	local projectile_speed = self:GetSpecialValueFor("projectile_speed")
	local start_radius = self:GetSpecialValueFor("start_radius")
	local end_radius = self:GetSpecialValueFor("end_radius")
	local distance = self:GetSpecialValueFor("distance")

	-- Talent that makes it global
	local talent = caster:FindAbilityByName("special_bonus_unique_perun_4")
	if talent and talent:GetLevel() > 0 then
		distance = talent:GetSpecialValueFor("value") - end_radius
	end

	-- Sound on caster
	caster:EmitSound("Hero_Tinker.Laser")

	-- Check if its a unit or point target
	local target_pos
	if self:GetCursorTarget() then
		target_pos = self:GetCursorTarget():GetOrigin()
	else
		target_pos = self:GetCursorPosition()
	end

	-- Calculate direction vector
	local direction = target_pos - caster_pos
	direction.z = 0.0
	direction = direction:Normalized()

	--projectile_speed = projectile_speed*(distance/(distance - start_radius))

	local info = {
		Source = caster,
		Ability = self,
		EffectName = "particles/ion_blast/ion_blast_projectile.vpcf",
		vSpawnOrigin = caster_pos + Vector(0, 0, 150),
		fDistance = distance + caster:GetCastRangeBonus(),
		fStartRadius = start_radius,
		fEndRadius = end_radius,
		bHasFrontalCone = false,
		bReplaceExisting = false,
		iUnitTargetTeam = self:GetAbilityTargetTeam(),
		iUnitTargetType = self:GetAbilityTargetType(),
		iUnitTargetFlags = self:GetAbilityTargetFlags(),
		bDeleteOnHit = false,
		vVelocity = direction*projectile_speed,
		bProvidesVision = false,
		--iVisionRadius = math.max(start_radius, end_radius), -- Vision has a duration in this case, thats why I am not using this
		--iVisionTeamNumber = caster:GetTeamNumber()
		--vAcceleration = vector,
		--bDrawsOnMinimap = false,
		--bVisibleToEnemies = true,
		--bIgnoreSource = true,
		--fMaxSpeed = projectile_speed,
	}

	ProjectileManager:CreateLinearProjectile(info)
end

function perun_ion_blast:OnProjectileThink(location)
	-- KV variables
	local vision_radius = self:GetSpecialValueFor("vision_radius")
	local tree_radius = self:GetSpecialValueFor("trees_radius")
	local vision_duration = self:GetSpecialValueFor("vision_duration")

	-- Destroy trees around the projectile
	GridNav:DestroyTreesAroundPoint(location, tree_radius, false)

	-- Give vision around the projectile
	AddFOWViewer(self:GetCaster():GetTeamNumber(), location, vision_radius, vision_duration, false)
end

function perun_ion_blast:OnProjectileHit(target, location)
	local caster = self:GetCaster()

	-- KV variables
	local damage = self:GetSpecialValueFor("damage")
	local vision_radius = self:GetSpecialValueFor("vision_radius")
	local tree_radius = self:GetSpecialValueFor("trees_radius")
	local vision_duration = self:GetSpecialValueFor("vision_duration")
	local mana_burn = self:GetSpecialValueFor("mana_burn")

	if target then
		if not target:IsMagicImmune() and not target:IsInvulnerable() then

			-- Damage
			local damage_table = {}
			damage_table.victim = target
			damage_table.attacker = caster
			damage_table.damage = damage
			damage_table.damage_type = self:GetAbilityDamageType() or DAMAGE_TYPE_PURE
			damage_table.ability = self

			ApplyDamage(damage_table)

			-- Sound on target
			target:EmitSound("Hero_Tinker.LaserImpact")

			-- Mana Removal
			local current_mana = target:GetMana()
			local mana_to_burn = math.min(current_mana, mana_burn)
			target:ReduceMana(mana_to_burn)

			-- Giving vision around the target hit
			--self:CreateVisibilityNode(location, vision_radius, vision_duration)
			AddFOWViewer(caster:GetTeamNumber(), location, vision_radius, vision_duration, false)

			-- Destroying trees around the target
			GridNav:DestroyTreesAroundPoint(location, tree_radius, false)

			local direction = location - caster:GetOrigin()
			direction.z = 0.0
			direction = direction:Normalized()

			-- Particle on the ground
			local nFXIndex = ParticleManager:CreateParticle("particles/units/heroes/hero_lina/lina_spell_dragon_slave_impact.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
			ParticleManager:SetParticleControlForward(nFXIndex, 1, direction)
			ParticleManager:ReleaseParticleIndex(nFXIndex)
		end
	end

	return false
end

function perun_ion_blast:ProcsMagicStick()
	return true
end
