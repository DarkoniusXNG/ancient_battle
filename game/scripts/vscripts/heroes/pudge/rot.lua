pudge_custom_rot = class({})

LinkLuaModifier("modifier_pudge_custom_rot_aura_applier", "heroes/pudge/rot.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_pudge_custom_rot_aura_effect", "heroes/pudge/rot.lua", LUA_MODIFIER_MOTION_NONE)

function pudge_custom_rot:OnToggle()
	local caster = self:GetCaster()
	if self:GetToggleState() then
		caster:AddNewModifier(caster, self, "modifier_pudge_custom_rot_aura_applier", {})

		if not caster:IsChanneling() then
			caster:StartGesture(ACT_DOTA_CAST_ABILITY_ROT)
		end
	else
		local rot_mod = caster:FindModifierByName("modifier_pudge_custom_rot_aura_applier")
		if rot_mod then
			rot_mod:Destroy()
		end
		caster:FadeGesture(ACT_DOTA_CAST_ABILITY_ROT)
	end
end

function pudge_custom_rot:ProcsMagicStick()
	return false
end

---------------------------------------------------------------------------------------------------

modifier_pudge_custom_rot_aura_applier = class({})

function modifier_pudge_custom_rot_aura_applier:IsHidden()
    return false
end

function modifier_pudge_custom_rot_aura_applier:IsPurgable()
    return false
end

function modifier_pudge_custom_rot_aura_applier:IsDebuff()
	return false
end

function modifier_pudge_custom_rot_aura_applier:RemoveOnDeath()
    return true
end

function modifier_pudge_custom_rot_aura_applier:IsAura()
	return true
end

function modifier_pudge_custom_rot_aura_applier:GetModifierAura()
	return "modifier_pudge_custom_rot_aura_effect"
end

function modifier_pudge_custom_rot_aura_applier:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_pudge_custom_rot_aura_applier:GetAuraSearchType()
	return bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC)
end

function modifier_pudge_custom_rot_aura_applier:GetAuraRadius()
	local parent = self:GetParent()
	local ability = self:GetAbility()
	if parent:HasScepter() then
		return ability:GetSpecialValueFor("scepter_radius")
	else
		return ability:GetSpecialValueFor("radius")
	end
end

function modifier_pudge_custom_rot_aura_applier:OnCreated()
	local parent = self:GetParent()
	local ability = self:GetAbility()

	self.radius = 250
	self.interval = 0.2
	if ability and not ability:IsNull() then
		self.radius = ability:GetSpecialValueFor("radius")
		self.interval = ability:GetSpecialValueFor("damage_interval")
	end

	if IsServer() then
		-- Sound
		parent:EmitSound("Hero_Pudge.Rot")

		-- Particle
		local nFXIndex = ParticleManager:CreateParticle("particles/units/heroes/hero_pudge/pudge_rot.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
		ParticleManager:SetParticleControl(nFXIndex, 1, Vector(self:GetAuraRadius(), 1, self:GetAuraRadius()))
		self:AddParticle(nFXIndex, false, false, -1, false, false)

		-- Start thinking
		self:StartIntervalThink(self.interval)
		self:OnIntervalThink()
	end
end

function modifier_pudge_custom_rot_aura_applier:OnDestroy()
	if IsServer() then
		self:GetParent():StopSound("Hero_Pudge.Rot")
	end
end

function modifier_pudge_custom_rot_aura_applier:OnIntervalThink()
	if not IsServer() then
		return
	end

	local parent = self:GetParent()
	local ability = self:GetAbility()

	if not parent or parent:IsNull() or not parent:IsAlive() then
		return
	end

	local radius = 250
	local damage_per_second = 30

	if ability and not ability:IsNull() then
		damage_per_second = ability:GetSpecialValueFor("damage_per_second")
		radius = ability:GetSpecialValueFor("radius")
		if parent:HasScepter() then
			damage_per_second = ability:GetSpecialValueFor("scepter_damage_per_second")
			radius = ability:GetSpecialValueFor("scepter_radius")
		end
	end

	local damage_per_interval = damage_per_second * self.interval

	local target_teams = DOTA_UNIT_TARGET_TEAM_ENEMY or self:GetAuraSearchTeam()
	local target_types = bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC) or self:GetAuraSearchType()
	local target_flags = DOTA_UNIT_TARGET_FLAG_NONE

	-- Init damage table
	local damage_table = {}
	damage_table.attacker = parent
	damage_table.damage = damage_per_interval
	damage_table.damage_type = DAMAGE_TYPE_MAGICAL
	damage_table.ability = ability

	-- Damage enemies
	local enemies = FindUnitsInRadius(parent:GetTeamNumber(), parent:GetAbsOrigin(), nil, radius, target_teams, target_types, target_flags, FIND_ANY_ORDER, false)
	for _, enemy in pairs(enemies) do
		if enemy and not enemy:IsNull() then
			damage_table.victim = enemy
			ApplyDamage(damage_table)
		end
	end

	-- Damage the parent (caster)
	damage_table.victim = parent
	ApplyDamage(damage_table)
end

---------------------------------------------------------------------------------------------------

modifier_pudge_custom_rot_aura_effect = class({})

function modifier_pudge_custom_rot_aura_effect:IsHidden()
    return false
end

function modifier_pudge_custom_rot_aura_effect:IsPurgable()
    return false
end

function modifier_pudge_custom_rot_aura_effect:IsDebuff()
	return true
end

function modifier_pudge_custom_rot_aura_effect:OnCreated()
	local caster = self:GetCaster()
	local parent = self:GetParent()
	local ability = self:GetAbility()
	local slow = -14
	if ability and not ability:IsNull() then
		slow = ability:GetSpecialValueFor("move_speed_slow")
		if caster:HasScepter() then
			self.heal_reduction = ability:GetSpecialValueFor("scepter_heal_reduction")
		end
	end

	if IsServer() then
		-- Talent that increases the slow
		local talent = caster:FindAbilityByName("special_bonus_unique_pudge_custom_1")
		if talent and talent:GetLevel() > 0 then
			slow = slow - math.abs(talent:GetSpecialValueFor("value"))
		end

		-- Status Resistance fix
		self.slow = parent:GetValueChangedByStatusResistance(slow)

		-- Particle
		local nFXIndex = ParticleManager:CreateParticle("particles/units/heroes/hero_pudge/pudge_rot_recipient.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
		self:AddParticle(nFXIndex, false, false, -1, false, false)
	else
		self.slow = slow
	end
end

function modifier_pudge_custom_rot_aura_effect:OnRefresh()
	local caster = self:GetCaster()
	local parent = self:GetParent()
	local ability = self:GetAbility()
	local slow = -14
	if ability and not ability:IsNull() then
		slow = ability:GetSpecialValueFor("move_speed_slow")
		if caster:HasScepter() then
			self.heal_reduction = ability:GetSpecialValueFor("scepter_heal_reduction")
		end
	end

	if IsServer() then
		-- Talent that increases the slow
		local talent = caster:FindAbilityByName("special_bonus_unique_pudge_custom_1")
		if talent and talent:GetLevel() > 0 then
			slow = slow - math.abs(talent:GetSpecialValueFor("value"))
		end

		-- Status Resistance fix
		self.slow = parent:GetValueChangedByStatusResistance(slow)
	else
		self.slow = slow
	end
end

function modifier_pudge_custom_rot_aura_effect:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
		MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET,
		MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE,
		MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE,
	}

	return funcs
end

function modifier_pudge_custom_rot_aura_effect:GetModifierMoveSpeedBonus_Percentage()
	return 0 - math.abs(self.slow)
end

function modifier_pudge_custom_rot_aura_effect:GetModifierHPRegenAmplify_Percentage()
  if self.heal_reduction and self:GetCaster():HasScepter() then
    return 0 - math.abs(self.heal_reduction)
  end

  return 0
end

function modifier_pudge_custom_rot_aura_effect:GetModifierHealAmplify_PercentageTarget()
  if self.heal_reduction and self:GetCaster():HasScepter() then
    return 0 - math.abs(self.heal_reduction)
  end

  return 0
end

function modifier_pudge_custom_rot_aura_effect:GetModifierLifestealRegenAmplify_Percentage()
  if self.heal_reduction and self:GetCaster():HasScepter() then
    return 0 - math.abs(self.heal_reduction)
  end

  return 0
end

function modifier_pudge_custom_rot_aura_effect:GetModifierSpellLifestealRegenAmplify_Percentage()
  if self.heal_reduction and self:GetCaster():HasScepter() then
    return 0 - math.abs(self.heal_reduction)
  end

  return 0
end
