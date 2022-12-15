LinkLuaModifier("modifier_breath_fire_haze_burn", "heroes/brewmaster/breath_of_fire.lua", LUA_MODIFIER_MOTION_NONE)

if brewmaster_custom_breath_of_fire == nil then
	brewmaster_custom_breath_of_fire = class({})
end

function brewmaster_custom_breath_of_fire:OnSpellStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()

	if not point then
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
	local caster = self:GetCaster()

	-- KV variables
	local initial_damage = self:GetSpecialValueFor("initial_damage")
	local duration = self:GetSpecialValueFor("burn_duration")

	if target then
		local damage_table = {}
		damage_table.victim = target
		damage_table.attacker = caster
		damage_table.damage_type = self:GetAbilityDamageType() or DAMAGE_TYPE_MAGICAL
		damage_table.ability = self
		damage_table.damage = initial_damage

		-- Apply Initial Damage
		ApplyDamage(damage_table)

		-- Apply burn modifier only if the target has drunken haze debuff
		if target:HasModifier("modifier_custom_drunken_haze_debuff") then
			target:AddNewModifier(caster, self, "modifier_breath_fire_haze_burn", {duration = duration})
		end
	end

	return false
end

-----------------------------------------------------------------------------------------------------------------------------------------------------

if modifier_breath_fire_haze_burn == nil then
  modifier_breath_fire_haze_burn = class({})
end

function modifier_breath_fire_haze_burn:IsHidden()
	return false -- needs tooltip
end

function modifier_breath_fire_haze_burn:IsDebuff()
	return true
end

function modifier_breath_fire_haze_burn:IsPurgable()
	return true
end

function modifier_breath_fire_haze_burn:GetEffectName()
	return "particles/units/heroes/hero_phoenix/phoenix_fire_spirit_burn_creep.vpcf"
end

function modifier_breath_fire_haze_burn:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW -- follow_origin
end

function modifier_breath_fire_haze_burn:OnCreated()
	local parent = self:GetParent()
	local ability = self:GetAbility()

	local think_interval = 0.2
	if ability then
		think_interval = ability:GetSpecialValueFor("burn_damage_interval")
	end
	if IsServer() then
		-- Ignite Sound
		parent:EmitSound("Hero_BrewMaster.CinderBrew.Ignite")

		-- Start burning
		self:StartIntervalThink(think_interval)
		self:OnIntervalThink()
	end
end

function modifier_breath_fire_haze_burn:OnIntervalThink()
	if not IsServer() then
		return
	end

	local caster = self:GetCaster()
	local ability = self:GetAbility()
	local parent = self:GetParent()

	if not caster or caster:IsNull() then
		return
	end

	local damage_per_second = 50
	local damage_interval = 0.2
	local damage_type = DAMAGE_TYPE_MAGICAL

	local damage_table = {}
	damage_table.victim = parent
	damage_table.attacker = caster

	if ability then
		damage_per_second = ability:GetSpecialValueFor("burn_damage_per_second")
		damage_interval = ability:GetSpecialValueFor("burn_damage_interval")
		damage_type = ability:GetAbilityDamageType()
		damage_table.ability = ability
	end

	-- Talent that increases damage per second
	local talent = caster:FindAbilityByName("special_bonus_unique_brewmaster_drunken_haze_burn")
	if talent and talent:GetLevel() > 0 then
		damage_per_second = damage_per_second + talent:GetSpecialValueFor("value")
	end

	local damage_per_interval = damage_per_second*damage_interval

	damage_table.damage_type = damage_type
	damage_table.damage = damage_per_interval

	-- Apply Burn Damage
	ApplyDamage(damage_table)
end
