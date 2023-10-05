firelord_meteor_push = firelord_meteor_push or class({})

LinkLuaModifier("modifier_firelord_meteor_burn_debuff", "heroes/firelord/firelord_meteor_push.lua", LUA_MODIFIER_MOTION_NONE )

function firelord_meteor_push:GetAOERadius()
	return self:GetSpecialValueFor("meteor_radius")
end

function firelord_meteor_push:OnSpellStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()

	if not point then
		return
	end

	local caster_location = caster:GetOrigin()
	local caster_team = caster:GetTeamNumber()

	local direction = point - caster_location
	direction.z = 0
	direction = direction:Normalized()

	-- KV variables
	local delay = self:GetSpecialValueFor("land_delay")
	local travel_speed = self:GetSpecialValueFor("travel_speed")
	local travel_distance = self:GetSpecialValueFor("travel_distance")
	local meteor_radius = self:GetSpecialValueFor("meteor_radius")
	local vision_radius = self:GetSpecialValueFor("vision_radius")
	local impact_damage = self:GetSpecialValueFor("damage_on_impact")
	local impact_radius = self:GetSpecialValueFor("impact_radius")
	local debuff_duration = self:GetSpecialValueFor("burn_duration")
	local knockback_duration = self:GetSpecialValueFor("knockback_duration")
	local knockback_distance = self:GetSpecialValueFor("max_knockback_distance")

	local velocity = direction * travel_speed
	local height = 1000 -- or 500

	--Start the meteor in the air in a place where it'll be moving the same speed when flying and when rolling.
	--local meteor_fly_original_point = (point - (velocity * delay)) + Vector (0, 0, height)
	local meteor_fly_original_point = caster_location + Vector(0, 0, height)

	--Create a particle effect consisting of the meteor falling from the sky and landing at the target point.
	local particle_effect = ParticleManager:CreateParticle("particles/units/heroes/hero_invoker/invoker_chaos_meteor_fly.vpcf", PATTACH_ABSORIGIN, caster)
	ParticleManager:SetParticleControl(particle_effect, 0, meteor_fly_original_point)
	ParticleManager:SetParticleControl(particle_effect, 1, point)
	ParticleManager:SetParticleControl(particle_effect, 2, Vector(delay, 0, 0))
	ParticleManager:ReleaseParticleIndex(particle_effect)

	-- Create Sound
	EmitSoundOnLocationWithCaster(point, "Hero_Invoker.ChaosMeteor.Cast", caster)
	--caster:EmitSound("Hero_Invoker.ChaosMeteor.Loop")

	-- Knockback table used when meteor lands
	local knockback_table =
	{
		should_stun = 0,
		knockback_duration = knockback_duration,
		duration = knockback_duration,
		knockback_distance = knockback_distance, --impact_radius/2,
		knockback_height = 50,
		center_x = point.x,
		center_y = point.y,
		center_z = point.z
	}

	local ability = self
	Timers:CreateTimer(delay, function()
		-- Emit Impact Sound
		EmitSoundOnLocationWithCaster(point, "Hero_Invoker.ChaosMeteor.Impact", caster)

		-- Impact effects on enemies in a radius
		local target_type = bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
		local enemies = FindUnitsInRadius(caster_team, point, nil, impact_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, target_type, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
		for _, enemy in pairs(enemies) do
			if enemy then
				-- Impact damage
				ApplyDamage({victim = enemy, attacker = caster, ability = ability, damage = impact_damage, damage_type = DAMAGE_TYPE_MAGICAL})

				-- Apply burn debuff
				enemy:AddNewModifier(caster, ability, "modifier_firelord_meteor_burn_debuff", {duration = debuff_duration})

				-- Apply knockback debuff caused by impact
				enemy:RemoveModifierByName("modifier_knockback")
				enemy:AddNewModifier(caster, nil, "modifier_knockback", knockback_table)
			end
		end

		-- Apply knockback effect to the caster as well if he is near the meteor on impact
		if (caster:GetAbsOrigin() - point):Length2D() <= impact_radius then
			caster:RemoveModifierByName("modifier_knockback")
			caster:AddNewModifier(caster, nil, "modifier_knockback", knockback_table)
		end

		--local meteor_duration = travel_distance/travel_speed
		local start_radius = meteor_radius
		local end_radius = meteor_radius

		local projectile_info = {
			Source = caster,
			Ability = ability,
			EffectName = "particles/units/heroes/hero_invoker/invoker_chaos_meteor.vpcf",
			vSpawnOrigin = point,
			fDistance = travel_distance,
			fStartRadius = start_radius,
			fEndRadius = end_radius,
			bHasFrontalCone = false,
			bReplaceExisting = false,
			iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
			iUnitTargetType = ability:GetAbilityTargetType(),
			iUnitTargetFlags = ability:GetAbilityTargetFlags(),
			--fExpireTime = GameRules:GetGameTime() + meteor_duration,
			bDeleteOnHit = false,
			vVelocity = velocity,
			bProvidesVision = true,
			iVisionRadius = math.max(meteor_radius, vision_radius, impact_radius),
			iVisionTeamNumber = caster_team,
			--vAcceleration = vector,
			bDrawsOnMinimap = false,
			bVisibleToEnemies = true,
			--bIgnoreSource = true,
			--fMaxSpeed = projectile_speed,
			--iMoveSpeed = travel_speed,
		}

		-- Create a meteor ball that will apply burn debuff on enemies hit
		ProjectileManager:CreateLinearProjectile(projectile_info)
    end)
end

function firelord_meteor_push:OnProjectileThink(location)
	local tree_radius = self:GetSpecialValueFor("meteor_radius")

	-- Destroy trees around the projectile
	GridNav:DestroyTreesAroundPoint(location, tree_radius, false)
end

function firelord_meteor_push:OnProjectileHit(target, location)
	local caster = self:GetCaster()
	local debuff_duration = self:GetSpecialValueFor("burn_duration")

	if target then
		if not target:IsMagicImmune() and not target:IsInvulnerable() then
			-- Apply debuff
			target:AddNewModifier(caster, self, "modifier_firelord_meteor_burn_debuff", {duration = debuff_duration})
		end
	end

	return false
end

function firelord_meteor_push:ProcsMagicStick()
	return true
end

---------------------------------------------------------------------------------------------------

modifier_firelord_meteor_burn_debuff = modifier_firelord_meteor_burn_debuff or class({})

function modifier_firelord_meteor_burn_debuff:IsHidden() -- needs tooltip
	return false
end

function modifier_firelord_meteor_burn_debuff:IsDebuff()
	return true
end

function modifier_firelord_meteor_burn_debuff:IsStunDebuff()
	return false
end

function modifier_firelord_meteor_burn_debuff:IsPurgable()
	return true
end

function modifier_firelord_meteor_burn_debuff:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_firelord_meteor_burn_debuff:OnCreated()
	if IsServer() then
		local ability = self:GetAbility()
		local damage_interval = 0.5
		if ability and not ability:IsNull() then
			damage_interval = ability:GetSpecialValueFor("damage_interval")
		end

		self:OnIntervalThink()
		self:StartIntervalThink(damage_interval)
	end
end

function modifier_firelord_meteor_burn_debuff:OnIntervalThink()
	if not IsServer() then return end

	local damage_per_second = 26
	local damage_interval = 0.5
	local ability = self:GetAbility()
	if ability and not ability:IsNull() then
		damage_per_second = ability:GetSpecialValueFor("damage_per_second")
		damage_interval = ability:GetSpecialValueFor("damage_interval")
	end

	local parent = self:GetParent()
	local caster = self:GetCaster()
	if not parent or parent:IsNull() or not caster or caster:IsNull() then
		self:StartIntervalThink(-1)
		self:Destroy()
		return
	end

	local damage_table = {
		victim = parent,
		attacker = caster,
		damage = damage_per_second*damage_interval,
		damage_type = DAMAGE_TYPE_MAGICAL,
		ability = ability,
	}

	-- Damage
	ApplyDamage(damage_table)

	-- Sound
	parent:EmitSound("Hero_Invoker.ChaosMeteor.Damage")
end

function modifier_firelord_meteor_burn_debuff:GetEffectName()
	return "particles/units/heroes/hero_invoker/invoker_chaos_meteor_burn_debuff.vpcf"
end

function modifier_firelord_meteor_burn_debuff:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end
