LinkLuaModifier("modifier_breath_fire_haze_burn", "heroes/brewmaster/breath_of_fire.lua", LUA_MODIFIER_MOTION_NONE)

brewmaster_custom_breath_of_fire = class({})

function brewmaster_custom_breath_of_fire:OnSpellStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()

	if not caster or not point then
		return
	end

	-- Linear projectile values
	local projectile_name = "particles/units/heroes/hero_dragon_knight/dragon_knight_breathe_fire.vpcf"
	local projectile_distance = self:GetSpecialValueFor("distance")
	local projectile_start_radius = self:GetSpecialValueFor("start_radius")
	local projectile_end_radius = self:GetSpecialValueFor("end_radius")
	local projectile_speed = self:GetSpecialValueFor("speed")
	local projectile_direction = point - caster:GetOrigin()
	projectile_direction.z = 0
	projectile_direction = projectile_direction:Normalized()

	-- Create Linear projectile
	local info = {
		Source = caster,
		Ability = self,
		EffectName = projectile_name,
		vSpawnOrigin = caster:GetAbsOrigin(),
		fDistance = projectile_distance,
		fStartRadius = projectile_start_radius,
		fEndRadius = projectile_end_radius,
		--bHasFrontalCone = true,
		bReplaceExisting = false,
		iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		iUnitTargetType = bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
		--iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
		--fExpireTime = 10,
	    bDeleteOnHit = false,
	    vVelocity = projectile_direction*projectile_speed,
	    bProvidesVision = true,
	    iVisionRadius = math.max(projectile_start_radius, projectile_end_radius),
		iVisionTeamNumber = caster:GetTeamNumber()
		--vAcceleration = vector,
		--bDrawsOnMinimap = false,
		--bVisibleToEnemies = true,
		--bIgnoreSource = true,
		--fMaxSpeed = projectile_speed,
	}

	ProjectileManager:CreateLinearProjectile(info)

	-- Sound
	caster:EmitSound("Hero_DragonKnight.BreathFire")
end


function brewmaster_custom_breath_of_fire:OnProjectileHit(target, location)
	-- If target doesn't exist, don't continue
	if not target or target:IsNull() then
		return false
	end

	local caster = self:GetCaster()

	-- KVs
	local initial_damage = self:GetSpecialValueFor("initial_damage")
	local hero_duration = self:GetSpecialValueFor("burn_duration_heroes")
	local creep_duration = self:GetSpecialValueFor("burn_duration_creeps")

	-- Apply burn modifier only if the target has drunken haze debuff
	if target:HasModifier("modifier_custom_drunken_haze_debuff") then
		if target:IsRealHero() then
			target:AddNewModifier(caster, self, "modifier_breath_fire_haze_burn", {duration = hero_duration})
		else
			target:AddNewModifier(caster, self, "modifier_breath_fire_haze_burn", {duration = creep_duration})
		end
	end

	local damage_table = {}
	damage_table.victim = target
	damage_table.attacker = caster
	damage_table.damage_type = self:GetAbilityDamageType() or DAMAGE_TYPE_MAGICAL
	damage_table.ability = self
	damage_table.damage = initial_damage

	-- Apply Initial Damage
	ApplyDamage(damage_table)

	return false
end

-----------------------------------------------------------------------------------------------------------------------------------------------------

modifier_breath_fire_haze_burn = modifier_breath_fire_haze_burn or class({})

function modifier_breath_fire_haze_burn:IsHidden()
	return false -- needs tooltip
end

function modifier_breath_fire_haze_burn:IsDebuff()
	return true
end

function modifier_breath_fire_haze_burn:IsPurgable()
	return true
end

--function modifier_breath_fire_haze_burn:GetAttributes()
	--return MODIFIER_ATTRIBUTE_MULTIPLE
--end

function modifier_breath_fire_haze_burn:OnCreated()
	self:OnRefresh()

	if IsServer() then
		local parent = self:GetParent()
		-- Ignite Sound
		parent:EmitSound("Hero_BrewMaster.CinderBrew.Ignite")

		-- Start burning
		self:OnIntervalThink()
		self:StartIntervalThink(self.interval)
	end
end

function modifier_breath_fire_haze_burn:OnRefresh()
	local caster = self:GetCaster()
	local ability = self:GetAbility()

	self.dps = 50
	self.interval = 0.2

	if ability and not ability:IsNull() then
		self.dps = ability:GetSpecialValueFor("burn_damage_per_second")
		self.interval = ability:GetSpecialValueFor("burn_damage_interval")
	end

	-- Talent that increases damage per second
	local talent = caster:FindAbilityByName("special_bonus_unique_brewmaster_drunken_haze_burn")
	if talent and talent:GetLevel() > 0 then
		self.dps = self.dps + talent:GetSpecialValueFor("value")
	end
end

function modifier_breath_fire_haze_burn:OnIntervalThink()
	if not IsServer() then
		return
	end

	local caster = self:GetCaster()
	local parent = self:GetParent()

	-- Don't apply damage if source or target don't exist
	if not parent or parent:IsNull() or not parent:IsAlive() or not caster or caster:IsNull() then
		self:StartIntervalThink(-1)
		self:Destroy()
		return
	end

	local damage_per_interval = self.dps * self.interval

	local damage_table = {}
	damage_table.victim = parent
	damage_table.attacker = caster
	damage_table.damage_type = DAMAGE_TYPE_MAGICAL
	damage_table.damage = damage_per_interval
	damage_table.ability = self:GetAbility()

	-- Apply Burn Damage
	ApplyDamage(damage_table)
end

function modifier_breath_fire_haze_burn:GetEffectName()
	return "particles/units/heroes/hero_phoenix/phoenix_fire_spirit_burn_creep.vpcf"
end

function modifier_breath_fire_haze_burn:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW -- follow_origin
end
