if perun_sky_wrath == nil then
	perun_sky_wrath = class({})
end

LinkLuaModifier("modifier_custom_sky_blinded", "heroes/perun/perun_sky_wrath.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_custom_sky_disabled", "heroes/perun/perun_sky_wrath.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_custom_sky_true_sight", "heroes/perun/perun_sky_wrath.lua", LUA_MODIFIER_MOTION_NONE)

function perun_sky_wrath:GetAOERadius()
	return self:GetSpecialValueFor("damage_radius")
end

function perun_sky_wrath:OnSpellStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()
	local team = caster:GetTeamNumber()

	-- KV variables
	local damage = self:GetSpecialValueFor("damage")
	local damage_radius = self:GetSpecialValueFor("damage_radius")
	local stun_duration = self:GetSpecialValueFor("stun_duration")
	local stun_radius = self:GetSpecialValueFor("stun_radius")
	local blind_radius = self:GetSpecialValueFor("blind_radius")
	local blind_duration = self:GetSpecialValueFor("blind_duration")
	local sight_duration = self:GetSpecialValueFor("true_sight_duration")
	local sight_radius = self:GetSpecialValueFor("true_sight_radius")

	-- Talent that increases damage
	local talent = caster:FindAbilityByName("special_bonus_unique_perun_1")
	if talent and talent:GetLevel() > 0 then
		damage = damage + talent:GetSpecialValueFor("value")
	end

	-- Main Particles
	local bolt_particle = ParticleManager:CreateParticle("particles/custom/perun_sky_wrath_new.vpcf", PATTACH_WORLDORIGIN, caster)
	ParticleManager:SetParticleControl(bolt_particle, 0, point)
	ParticleManager:SetParticleControl(bolt_particle, 1, Vector(point.x, point.y, 2000))
	ParticleManager:ReleaseParticleIndex(bolt_particle)

	local aoe_particle = ParticleManager:CreateParticle("particles/custom/perun_sky_wrath_aoe.vpcf", PATTACH_WORLDORIGIN, caster)
	ParticleManager:SetParticleControl(aoe_particle, 0, point)
	ParticleManager:SetParticleControl(aoe_particle, 1, Vector(damage_radius, 0, 0))
	ParticleManager:ReleaseParticleIndex(aoe_particle)

	-- Vision
	AddFOWViewer(team, point, sight_radius, sight_duration, false)

	-- True Sight thinker
	CreateModifierThinker(caster, self, "modifier_custom_sky_true_sight", {duration = sight_duration}, point, team, false)

	-- Lightning Bolt Sound
    EmitSoundOnLocationWithCaster(point, "Hero_Zuus.LightningBolt", caster)

	-- Split Earth Particle
	local nFXIndex = ParticleManager:CreateParticle("particles/units/heroes/hero_leshrac/leshrac_split_earth.vpcf", PATTACH_WORLDORIGIN, caster)
	ParticleManager:SetParticleControl(nFXIndex, 0, point)
	ParticleManager:SetParticleControl(nFXIndex, 1, Vector(stun_radius, 1, 1))
	ParticleManager:ReleaseParticleIndex(nFXIndex)

	-- Split Earth Sound
	EmitSoundOnLocationWithCaster(point, "Hero_Leshrac.Split_Earth", caster)

	-- Destroy trees
	GridNav:DestroyTreesAroundPoint(point, math.max(stun_radius, damage_radius), false)

    -- Find enemies to stun
	local enemies_to_stun = FindUnitsInRadius(
		team,
		point,
		nil,
		stun_radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
		DOTA_UNIT_TARGET_FLAG_NONE,
		FIND_ANY_ORDER,
		false
	)

	-- Apply stun to each enemy
	for _, enemy in pairs(enemies_to_stun) do
		if enemy and not enemy:IsNull() and not enemy:IsMagicImmune() and not enemy:IsInvulnerable() then
			-- Apply stun
			local duration = enemy:GetValueChangedByStatusResistance(stun_duration)
			enemy:AddNewModifier(caster, self, "modifier_custom_sky_disabled", {duration = duration})
		end
	end

	-- Find enemies to blind
	local enemies_to_blind = FindUnitsInRadius(
		team,
		point,
		nil,
		blind_radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
		DOTA_UNIT_TARGET_FLAG_NONE,
		FIND_ANY_ORDER,
		false
	)

	-- Apply blind to each enemy
	for _, enemy in pairs(enemies_to_blind) do
		if enemy and not enemy:IsNull() and not enemy:IsMagicImmune() and not enemy:IsInvulnerable() then
			-- Apply blind
			enemy:AddNewModifier(caster, self, "modifier_custom_sky_blinded", {duration = blind_duration})
		end
	end

	-- Find enemies to damage
	local enemies = FindUnitsInRadius(
		team,
		point,
		nil,
		damage_radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
		DOTA_UNIT_TARGET_FLAG_NONE,
		FIND_ANY_ORDER,
		false
	)

	local damage_table = {}
	damage_table.attacker = caster
	damage_table.damage_type = self:GetAbilityDamageType()
	damage_table.ability = self
	damage_table.damage = damage

	-- Apply damage to each enemy
	for _, enemy in pairs(enemies) do
		if enemy and not enemy:IsNull() and not enemy:IsMagicImmune() and not enemy:IsInvulnerable() then
			-- Apply damage
			damage_table.victim = enemy
			ApplyDamage(damage_table)
		end
	end
end

function perun_sky_wrath:ProcsMagicStick()
	return true
end

---------------------------------------------------------------------------------------------------

modifier_custom_sky_disabled = class({})

function modifier_custom_sky_disabled:IsHidden()
  return true
end

function modifier_custom_sky_disabled:IsDebuff()
  return true
end

function modifier_custom_sky_disabled:IsPurgable()
  return true
end

function modifier_custom_sky_disabled:IsStunDebuff()
  return true
end

function modifier_custom_sky_disabled:GetEffectName()
  return "particles/generic_gameplay/generic_stunned.vpcf"
end

function modifier_custom_sky_disabled:GetEffectAttachType()
  return PATTACH_OVERHEAD_FOLLOW
end

function modifier_custom_sky_disabled:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
  }
end

function modifier_custom_sky_disabled:GetOverrideAnimation()
  return ACT_DOTA_DISABLED
end

function modifier_custom_sky_disabled:CheckState()
  return {
    [MODIFIER_STATE_STUNNED] = true,
  }
end

---------------------------------------------------------------------------------------------------

modifier_custom_sky_blinded = class({})

function modifier_custom_sky_blinded:IsHidden()
  return false
end

function modifier_custom_sky_blinded:IsDebuff()
  return true
end

function modifier_custom_sky_blinded:IsPurgable()
  return true
end

function modifier_custom_sky_blinded:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.blind_pct = ability:GetSpecialValueFor("miss_chance")
  end
end

modifier_custom_sky_blinded.OnRefresh = modifier_custom_sky_blinded.OnCreated

function modifier_custom_sky_blinded:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MISS_PERCENTAGE,
  }
end

function modifier_custom_sky_blinded:GetModifierMiss_Percentage()
  return self.blind_pct or self:GetAbility():GetSpecialValueFor("miss_chance")
end

---------------------------------------------------------------------------------------------------

modifier_custom_sky_true_sight = class({})

function modifier_custom_sky_true_sight:IsHidden()
  return true
end

function modifier_custom_sky_true_sight:IsPurgable()
  return false
end

function modifier_custom_sky_true_sight:IsAura()
  return true
end

function modifier_custom_sky_true_sight:GetModifierAura()
  return "modifier_truesight"
end

function modifier_custom_sky_true_sight:GetAuraRadius()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    return ability:GetSpecialValueFor("true_sight_radius")
  else
    return 750
  end
end

function modifier_custom_sky_true_sight:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_custom_sky_true_sight:GetAuraSearchType()
  return DOTA_UNIT_TARGET_ALL
end

function modifier_custom_sky_true_sight:GetAuraSearchFlags()
  return bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_INVULNERABLE)
end
