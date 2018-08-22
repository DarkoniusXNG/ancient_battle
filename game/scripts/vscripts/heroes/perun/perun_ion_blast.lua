if perun_ion_blast == nil then
	perun_ion_blast = class({})
end

function perun_ion_blast:OnSpellStart()
	self.ion_blast_speed = self:GetSpecialValueFor("ion_blast_speed")
	self.ion_blast_width_initial = self:GetSpecialValueFor("ion_blast_width_initial")
	self.ion_blast_width_end = self:GetSpecialValueFor("ion_blast_width_end")
	self.ion_blast_distance = self:GetSpecialValueFor("ion_blast_distance")
	self.ion_blast_damage = self:GetSpecialValueFor("ion_blast_damage")
	self.ion_blast_mana_burn = self:GetSpecialValueFor("ion_blast_mana_burn")
	self.ion_blast_vision_radius = self:GetSpecialValueFor("ion_blast_vision_radius")
	self.ion_blast_tree_radius = self:GetSpecialValueFor("ion_blast_trees_radius")
	self.ion_blast_vision_duration = self:GetSpecialValueFor("ion_blast_vision_duration")

	EmitSoundOn("Hero_Tinker.Laser", self:GetCaster())

	local vPos = nil
	if self:GetCursorTarget() then
		vPos = self:GetCursorTarget():GetOrigin()
	else
		vPos = self:GetCursorPosition()
	end

	local vDirection = vPos - self:GetCaster():GetOrigin()
	vDirection.z = 0.0
	vDirection = vDirection:Normalized()

	self.ion_blast_speed = self.ion_blast_speed * (self.ion_blast_distance / (self.ion_blast_distance - self.ion_blast_width_initial))

	local info = {
		EffectName = "particles/units/heroes/hero_windrunner/windrunner_spell_powershot.vpcf",
		--EffectName = "particles/projectile_linear/perun_ion_blast_projectile.vpcf",
		Ability = self,
		vSpawnOrigin = self:GetCaster():GetOrigin(), 
		fStartRadius = self.ion_blast_width_initial,
		fEndRadius = self.ion_blast_width_end,
		vVelocity = vDirection * self.ion_blast_speed,
		fDistance = self.ion_blast_distance,
		Source = self:GetCaster(),
		iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
	}

	ProjectileManager:CreateLinearProjectile(info)
end

function perun_ion_blast:OnProjectileThink(vLocation)
	-- Destroy trees around the projectile
	GridNav:DestroyTreesAroundPoint(vLocation, self.ion_blast_tree_radius, false)
	-- Give vision around the projectile
	AddFOWViewer(self:GetCaster():GetTeamNumber(), vLocation, self.ion_blast_vision_radius, self.ion_blast_vision_duration, false)
end

function perun_ion_blast:OnProjectileHit(hTarget, vLocation)
	if hTarget ~= nil and (not hTarget:IsMagicImmune()) and (not hTarget:IsInvulnerable()) then
		-- Damage Part
		local damage_table = {
			victim = hTarget,
			attacker = self:GetCaster(),
			damage = self.ion_blast_damage,
			damage_type = DAMAGE_TYPE_PURE,
			ability = self
		}

		ApplyDamage(damage_table)
		
		-- Sound
		EmitSoundOn("Hero_Tinker.LaserImpact", hTarget)
		
		-- Mana Burn Part
		local current_mana = hTarget:GetMana()
		local mana_to_burn = math.min(current_mana, self.ion_blast_mana_burn)
		hTarget:ReduceMana(mana_to_burn)
		
		-- Giving vision Part around the target
		self:CreateVisibilityNode(vLocation, self.ion_blast_vision_radius, self.ion_blast_vision_duration)
		
		-- Destroying trees around the target
		GridNav:DestroyTreesAroundPoint(vLocation, self.ion_blast_tree_radius, false)
		
		local vDirection = vLocation - self:GetCaster():GetOrigin()
		vDirection.z = 0.0
		vDirection = vDirection:Normalized()
		
		local nFXIndex = ParticleManager:CreateParticle("particles/units/heroes/hero_lina/lina_spell_dragon_slave_impact.vpcf", PATTACH_ABSORIGIN_FOLLOW, hTarget)
		ParticleManager:SetParticleControlForward(nFXIndex, 1, vDirection)
		ParticleManager:ReleaseParticleIndex(nFXIndex)
	end

	return false
end