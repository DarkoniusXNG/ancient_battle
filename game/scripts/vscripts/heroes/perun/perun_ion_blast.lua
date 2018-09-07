if perun_ion_blast == nil then
	perun_ion_blast = class({})
end

function perun_ion_blast:OnSpellStart()
	local caster = self:GetCaster()
	local caster_pos = caster:GetOrigin()
	
	-- KV variables
	local projectile_speed = self:GetSpecialValueFor("ion_blast_speed")
	local start_radius = self:GetSpecialValueFor("ion_blast_width_initial")
	local end_radius = self:GetSpecialValueFor("ion_blast_width_end")
	local distance = self:GetSpecialValueFor("ion_blast_distance")
	
	-- Sound on caster
	EmitSoundOn("Hero_Tinker.Laser", caster)

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

	projectile_speed = projectile_speed*(distance/(distance - start_radius))

	local info = {
		EffectName = "particles/units/heroes/hero_windrunner/windrunner_spell_powershot.vpcf",
		--EffectName = "particles/projectile_linear/perun_ion_blast_projectile.vpcf",
		Ability = self,
		vSpawnOrigin = caster_pos, 
		fStartRadius = start_radius,
		fEndRadius = end_radius,
		vVelocity = direction*projectile_speed,
		fDistance = distance,
		Source = caster,
		bHasFrontalCone = false,
		bReplaceExisting = false,
		iUnitTargetTeam = self:GetAbilityTargetTeam(),
		iUnitTargetType = self:GetAbilityTargetType(),
		iUnitTargetFlags = self:GetAbilityTargetFlags(),
		bDeleteOnHit = false,
		bProvidesVision = false,
	}

	ProjectileManager:CreateLinearProjectile(info)
end

function perun_ion_blast:OnProjectileThink(location)
	-- KV variables
	local vision_radius = self:GetSpecialValueFor("ion_blast_vision_radius")
	local tree_radius = self:GetSpecialValueFor("ion_blast_trees_radius")
	local vision_duration = self:GetSpecialValueFor("ion_blast_vision_duration")
	
	-- Destroy trees around the projectile
	GridNav:DestroyTreesAroundPoint(location, tree_radius, false)
	
	-- Give vision around the projectile
	AddFOWViewer(self:GetCaster():GetTeamNumber(), location, vision_radius, vision_duration, false)
end

function perun_ion_blast:OnProjectileHit(target, location)
	local caster = self:GetCaster()
	
	-- KV variables
	local damage = self:GetSpecialValueFor("ion_blast_damage")
	local vision_radius = self:GetSpecialValueFor("ion_blast_vision_radius")
	local tree_radius = self:GetSpecialValueFor("ion_blast_trees_radius")
	local vision_duration = self:GetSpecialValueFor("ion_blast_vision_duration")
	local mana_burn = self:GetSpecialValueFor("ion_blast_mana_burn")
	
	if target then
		if (not target:IsMagicImmune()) and (not target:IsInvulnerable()) then
			
			-- Damage
			local damage_table = {}
			damage_table.victim = target
			damage_table.attacker = caster
			damage_table.damage = damage
			damage_table.damage_type = self:GetAbilityDamageType() or DAMAGE_TYPE_PURE
			damage_table.ability = self

			ApplyDamage(damage_table)
			
			-- Sound on target
			EmitSoundOn("Hero_Tinker.LaserImpact", target)
			
			-- Mana Drain
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
