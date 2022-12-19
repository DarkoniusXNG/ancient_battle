techies_custom_suicide = class({})

LinkLuaModifier("modifier_techies_custom_suicide_stun", "heroes/techies/suicide.lua", LUA_MODIFIER_MOTION_NONE) -- for shard
LinkLuaModifier("modifier_techies_custom_suicide_silence", "heroes/techies/suicide.lua", LUA_MODIFIER_MOTION_NONE) -- for talent
LinkLuaModifier("modifier_techies_custom_blast_off", "heroes/techies/suicide.lua", LUA_MODIFIER_MOTION_BOTH) -- for shard

function techies_custom_suicide:GetAOERadius()
	return self:GetSpecialValueFor("small_radius")
end

function techies_custom_suicide:GetCooldown(level)
	local caster = self:GetCaster()
	local base_cooldown = self.BaseClass.GetCooldown(self, level)

	-- Talent that decreases cooldown
	local talent = caster:FindAbilityByName("special_bonus_unique_techies_custom_4")
	if talent and talent:GetLevel() > 0 then
	  return base_cooldown - math.abs(talent:GetSpecialValueFor("value"))
	end

	return base_cooldown
end

function techies_custom_suicide:GetCastRange(location, target)
  local caster = self:GetCaster()

  if caster:HasShardCustom() then
    return self:GetSpecialValueFor("shard_cast_range")
  end

  return self.BaseClass.GetCastRange(self, location, target)
end

function techies_custom_suicide:OnSpellStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()

	if not point or not caster then
		return
	end

	-- Check if caster has a shard
	if caster:HasShardCustom() then
		-- Cast sound
		caster:EmitSound("Hero_Techies.BlastOff.Cast")
		-- Add the blast off modifier
		local modifier_table = {point_x = point.x, point_y = point.y, point_z = point.z}
		caster:AddNewModifier(caster, ability, "modifier_techies_custom_blast_off", modifier_table)
	else
		self:PrimaryEffect(point)
		-- Create the vision and kill the caster
		self:CreateVisibilityNode(point, vision_radius, vision_duration)
		caster:Kill(self, caster)
	end
end

function techies_custom_suicide:PrimaryEffect(point)
	local caster = self:GetCaster()
	
	local function TableContains(t, element)
		if t == nil then return false end
		for _, v in pairs(t) do
			if v == element then
				return true
			end
		end
		return false
	end

	-- Targetting constants
	local target_team = DOTA_UNIT_TARGET_TEAM_ENEMY
	local target_type = bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BUILDING)
	local target_flags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES

	local team = caster:GetTeamNumber()

	-- KV
	local small_radius = self:GetSpecialValueFor("small_radius")
	local big_radius = self:GetSpecialValueFor("big_radius")
	local small_radius_dmg = self:GetSpecialValueFor("small_radius_damage")
	local big_radius_dmg = self:GetSpecialValueFor("big_radius_damage")
	local building_dmg_reduction = self:GetSpecialValueFor("building_dmg_reduction")
	local vision_radius = self:GetSpecialValueFor("vision_radius")
	local vision_duration = self:GetSpecialValueFor("vision_duration")

	-- Damage table
	local damage_table = {}
	damage_table.attacker = caster
	damage_table.damage_type = DAMAGE_TYPE_PHYSICAL -- Composite dmg doesn't exist anymore, so we reduce the physical dmg with magic resistance
	damage_table.damage_flags = DOTA_DAMAGE_FLAG_BYPASSES_BLOCK
	damage_table.ability = self

	local enemies_big_radius = FindUnitsInRadius(team, point, nil, big_radius, target_team, target_type, target_flags, FIND_ANY_ORDER, false)
	local enemies_small_radius = FindUnitsInRadius(team, point, nil, small_radius, target_team, target_type, target_flags, FIND_ANY_ORDER, false)

	-- Sound
	caster:EmitSound("Hero_Techies.Suicide")
	
	-- Check for silence talent
	local talent = caster:FindAbilityByName("special_bonus_unique_techies_custom_2")
	local has_talent = talent and talent:GetLevel() > 0
	local silence_duration = 0
	if has_talent then
		silence_duration = talent:GetSpecialValueFor("value")
	end

	-- Check for shard
	local has_shard = caster:HasShardCustom()
	local stun_duration = self:GetSpecialValueFor("shard_stun_duration")

	for _, enemy in pairs(enemies_big_radius) do
		if enemy and not enemy:IsNull() and not enemy:IsCustomWardTypeUnit() then
			-- Apply silence if talent is learned
			if has_talent then
				enemy:AddNewModifier(caster, self, "modifier_techies_custom_suicide_silence", {duration = silence_duration})
			end

			-- Apply stun if caster has shard
			if has_shard then
				local actual_duration = enemy:GetValueChangedByStatusResistance(stun_duration)
				enemy:AddNewModifier(caster, self, "modifier_techies_custom_suicide_stun", {duration = actual_duration})
			end

			-- Victim
			damage_table.victim = enemy

			-- Calculate damage
			local dmg = big_radius_dmg
			-- Increase the damage if enemy is closer to the center
			if TableContains(enemies_small_radius, enemy) then
				dmg = small_radius_dmg
			end
			local enemy_magic_resist = enemy:GetMagicalArmorValue()
			local composite_dmg = dmg * (1 - enemy_magic_resist)
			damage_table.damage = composite_dmg
			if enemy:IsBuilding() or enemy:IsBarracks() or enemy:IsTower() or enemy:IsFort() then
				damage_table.damage = composite_dmg * building_dmg_reduction / 100
			end

			-- Explode (damage)
			ApplyDamage(damage_table)
		end
	end

	-- Explode particles
	local pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_techies/techies_suicide_base.vpcf", PATTACH_CUSTOMORIGIN, caster) -- PATTACH_ABSORIGIN
	ParticleManager:SetParticleControl(pfx, 0, point)
	ParticleManager:SetParticleControl(pfx, 2, Vector(big_radius, big_radius, big_radius))
	ParticleManager:ReleaseParticleIndex(pfx)
	--local pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_techies/techies_blast_off.vpcf", PATTACH_WORLDORIGIN, caster)
	--ParticleManager:SetParticleControl(pfx, 0, point)
	--ParticleManager:ReleaseParticleIndex(pfx)

	-- Destroy trees
	GridNav:DestroyTreesAroundPoint(point, big_radius, false)

	-- Timers:CreateTimer(5.0, function()
		-- ParticleManager:DestroyParticle(pfx, true)
		-- ParticleManager:ReleaseParticleIndex(pfx)
	-- end)
end

function techies_custom_suicide:ProcsMagicStick()
	return true
end

---------------------------------------------------------------------------------------------------

modifier_techies_custom_suicide_stun = class({})

function modifier_techies_custom_suicide_stun:IsHidden() -- needs tooltip
	return false
end

function modifier_techies_custom_suicide_stun:IsDebuff()
	return true
end

function modifier_techies_custom_suicide_stun:IsStunDebuff()
	return true
end

function modifier_techies_custom_suicide_stun:IsPurgable()
	return true
end

function modifier_techies_custom_suicide_stun:GetEffectName()
	return "particles/generic_gameplay/generic_stunned.vpcf"
end

function modifier_techies_custom_suicide_stun:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end

function modifier_techies_custom_suicide_stun:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
	}
end

function modifier_techies_custom_suicide_stun:GetOverrideAnimation()
	return ACT_DOTA_DISABLED
end

function modifier_techies_custom_suicide_stun:CheckState()
	return {
		[MODIFIER_STATE_STUNNED] = true,
	}
end

---------------------------------------------------------------------------------------------------

modifier_techies_custom_suicide_silence = class({})

function modifier_techies_custom_suicide_silence:IsHidden() -- needs tooltip
	return false
end

function modifier_techies_custom_suicide_silence:IsPurgable()
	return true
end

function modifier_techies_custom_suicide_silence:IsDebuff()
	return true
end

function modifier_techies_custom_suicide_silence:CheckState()
	return {
		[MODIFIER_STATE_SILENCED] = true,
	}
end

function modifier_techies_custom_suicide_silence:GetEffectName()
	return "particles/generic_gameplay/generic_silence.vpcf"
end

function modifier_techies_custom_suicide_silence:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end

---------------------------------------------------------------------------------------------------

modifier_techies_custom_blast_off = class({})

function modifier_techies_custom_blast_off:IsHidden()
  return true
end

function modifier_techies_custom_blast_off:IsDebuff()
  return false
end

function modifier_techies_custom_blast_off:IsPurgable()
  return false
end

function modifier_techies_custom_blast_off:RemoveOnDeath()
  return true
end

-- function modifier_techies_custom_blast_off:DeclareFunctions()
  -- return {
    -- MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
  -- }
-- end

-- function modifier_techies_custom_blast_off:GetOverrideAnimation()
  -- return ACT_DOTA_RUN
-- end

function modifier_techies_custom_blast_off:GetPriority()
  return DOTA_MOTION_CONTROLLER_PRIORITY_HIGHEST
end

function modifier_techies_custom_blast_off:CheckState()
  return {
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
  }
end

if IsServer() then
  function modifier_techies_custom_blast_off:OnCreated(event)
    local parent = self:GetParent()
	local parent_loc = parent:GetAbsOrigin()

    -- Data sent with AddNewModifier (not available on the client)
	local point = Vector(event.point_x, event.point_y, event.point_z)
	self.jump_duration = 1
	self.jump_max_height = 300
    self.direction = (point - parent_loc):Normalized()
    self.distance = (point - parent_loc):Length2D()
    self.speed = self.distance / self.jump_duration
	self.time_elapsed = 0
	self.current_height = 0

    ProjectileManager:ProjectileDodge(parent)

    if not self:ApplyHorizontalMotionController() or not self:ApplyVerticalMotionController() then
      self:Destroy()
      return
    end

    -- Trail particle
    --local particleName = "particles/units/heroes/hero_techies/techies_blast_off_trail.vpcf"
    --local trail_pfx = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN_FOLLOW, parent)
    --ParticleManager:SetParticleControl(trail_pfx, 0, start_pos)
    --ParticleManager:SetParticleControl(trail_pfx, 1, end_pos)
    --ParticleManager:ReleaseParticleIndex(trail_pfx)
  end

  function modifier_techies_custom_blast_off:OnDestroy()
    local parent = self:GetParent()
    local ability = self:GetAbility()

    if not parent or parent:IsNull() then
      -- big problem if this happens
      return
	end

    local parent_origin = parent:GetAbsOrigin()

    parent:RemoveHorizontalMotionController(self)
	parent:RemoveVerticalMotionController(self)

    -- Unstuck the parent
    FindClearSpaceForUnit(parent, parent_origin, false)
    ResolveNPCPositions(parent_origin, 128)

    -- Change facing of the parent
    parent:FaceTowards(parent_origin + 128*self.direction)

    if ability and not ability:IsNull() then
      ability:PrimaryEffect(parent_origin)
    end
  end

  function modifier_techies_custom_blast_off:UpdateHorizontalMotion(parent, deltaTime)
    if not parent or parent:IsNull() or not parent:IsAlive() then
      return
    end

	-- Check if we're still jumping
	if self.time_elapsed < self.jump_duration then
		-- Move parent towards the target point
		local new_location = parent:GetAbsOrigin() + self.direction * self.speed * deltaTime
		parent:SetAbsOrigin(new_location)
	else
		self:Destroy()
	end
  end
  
  function modifier_boss_shielder_jump:UpdateVerticalMotion(parent, deltaTime)
	if not parent or parent:IsNull() or not parent:IsAlive() then
      return
    end

	-- Calculate height as a parabola
	local t = self.time_elapsed / self.jump_duration
	self.current_height = self.current_height + deltaTime * self.jump_max_height * (4-8*t)

	-- Set the new height
	parent:SetAbsOrigin(GetGroundPosition(parent:GetAbsOrigin(), parent) + Vector(0, 0, self.current_height))

	-- Increase the time elapsed
	self.time_elapsed = self.time_elapsed + deltaTime
  end

  function modifier_techies_custom_blast_off:OnHorizontalMotionInterrupted()
    self:Destroy()
  end
  
  function modifier_techies_custom_blast_off:OnVerticalMotionInterrupted()
    self:Destroy()
  end
end

function modifier_techies_custom_blast_off:GetEffectName()
	return "particles/units/heroes/hero_techies/techies_blast_off_trail.vpcf"
end

function modifier_techies_custom_blast_off:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end
