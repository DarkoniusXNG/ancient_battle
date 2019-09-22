if stealth_assassin_death_ward == nil then
	stealth_assassin_death_ward = class({})
end

LinkLuaModifier("modifier_custom_death_ward", "heroes/ryu/death_ward.lua", LUA_MODIFIER_MOTION_NONE)

function stealth_assassin_death_ward:IsStealable()
	return true
end

function stealth_assassin_death_ward:IsHiddenWhenStolen()
	return false
end

function stealth_assassin_death_ward:OnSpellStart()
	local unit_name = "npc_dota_custom_death_ward"
	if IsServer() then
		local point = self:GetCursorPosition()

		if not point then
			return
		end

		local caster = self:GetCaster()

		-- Create Death Ward unit
		local death_ward = CreateUnitByName(unit_name, point, true, caster, caster, caster:GetTeamNumber())

		-- Set on a clear space
		--Timers:CreateTimer(FrameTime(), function()
			--ResolveNPCPositions(point, 128)
		--end)

		death_ward:SetOwner(caster)
		death_ward:SetControllableByPlayer(caster:GetPlayerID(), true)

		-- Sound
		death_ward:EmitSound("Hero_WitchDoctor.Death_WardBuild")

		-- Set Death Ward damage
		local damage = self:GetSpecialValueFor("damage")
		-- Check for bonus damage talent
		local talent = caster:FindAbilityByName("special_bonus_unique_witch_doctor_5")
		if talent then
			if talent:GetLevel() ~= 0 then
				damage = damage + talent:GetSpecialValueFor("value")
			end
		end
		death_ward:SetBaseDamageMax(damage)
		death_ward:SetBaseDamageMin(damage)

		-- Apply modifiers to Death Ward
		death_ward:AddNewModifier(caster, self, "modifier_custom_death_ward", {})
		local ward_duration = self:GetSpecialValueFor("duration_tooltip")
		death_ward:AddNewModifier(caster, self, "modifier_kill", {duration = ward_duration})
		death_ward:AddNewModifier(caster, self, "modifier_phased", {duration = 0.03}) -- unit will insta unstuck after this built-in modifier expires.

		-- Variables needed for later
		self.ward_damage = damage
		self.ward_unit = death_ward
	end
end

function stealth_assassin_death_ward:OnProjectileHit_ExtraData(target, vLocation, extra_data)
	if self.ward_unit:IsNull() then
		return
	end

	-- If the owner of the Death Ward doesn't have Aghanim Scepter, don't continue
	local owner = self.ward_unit:GetOwner()
	if not owner:HasScepter() then
		return
	end

	-- Damage of the bounced projectile
	local damage = self.ward_damage

	-- Source of the damage
	local damage_source = self.ward_unit

	-- Damage table of bounced projectile
	local damage_table = {}
	damage_table.attacker = damage_source
	damage_table.damage = damage
	damage_table.damage_type = self:GetAbilityDamageType()
	damage_table.ability = self
	damage_table.victim = target

	ApplyDamage(damage_table)

	if extra_data.bounces_left >= 0 and owner:HasScepter() then
		extra_data.bounces_left = extra_data.bounces_left - 1
		local bounce_radius = self:GetSpecialValueFor("bounce_radius")
		local targets_flags = bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_NO_INVIS, DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE)
		local enemies = FindUnitsInRadius(damage_source:GetTeamNumber(), target:GetAbsOrigin(), nil, bounce_radius, self:GetAbilityTargetTeam(), self:GetAbilityTargetType(), targets_flags, FIND_CLOSEST, false)

		for _,enemy in pairs(enemies) do
			if enemy and enemy ~= target and not enemy:IsAttackImmune() and extra_data.bounces_left > 0 then

				local projectile = {
					Target = enemy,
					Source = target,
					Ability = self,
					EffectName = "particles/units/heroes/hero_witchdoctor/witchdoctor_ward_attack.vpcf",
					bDodgable = true,
					bProvidesVision = false,
					iMoveSpeed = damage_source:GetProjectileSpeed(),
					iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1,
					ExtraData = extra_data
				}

				ProjectileManager:CreateTrackingProjectile(projectile)
				break
			end
		end
	end
end

function stealth_assassin_death_ward:ProcsMagicStick()
	return true
end

---------------------------------------------------------------------------------------------------

if modifier_custom_death_ward == nil then
	modifier_custom_death_ward = class({})
end

function modifier_custom_death_ward:IsDebuff()
	return false
end

function modifier_custom_death_ward:IsHidden()
	return true
end

function modifier_custom_death_ward:IsPurgable()
	return false
end

function modifier_custom_death_ward:IsPurgeException()
	return false
end

function modifier_custom_death_ward:IsStunDebuff()
	return false
end

function modifier_custom_death_ward:RemoveOnDeath()
	return true
end

function modifier_custom_death_ward:OnCreated()
	local parent = self:GetParent()
	self.ward_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_witchdoctor/witchdoctor_ward_skull.vpcf", PATTACH_POINT_FOLLOW, parent)
	ParticleManager:SetParticleControlEnt(self.ward_particle, 0, parent, PATTACH_POINT_FOLLOW, "attach_attack1", parent:GetAbsOrigin(), true)
	ParticleManager:SetParticleControl(self.ward_particle, 2, parent:GetAbsOrigin())

	if IsServer() then
		local owner = parent:GetOwner()
		local attack_range_bonus = 0
		-- Check for bonus attack range talent
		local talent = owner:FindAbilityByName("special_bonus_unique_witch_doctor_1")
		if talent then
			if talent:GetLevel() ~= 0 then
				attack_range_bonus = talent:GetSpecialValueFor("value")
			end
		end

		-- Change Acquisition range if there is an attack range bonus
		parent:SetAcquisitionRange(parent:GetAcquisitionRange() + attack_range_bonus)
	end
end

function modifier_custom_death_ward:OnDestroy()
	if self.ward_particle then
		ParticleManager:DestroyParticle(self.ward_particle, true)
		ParticleManager:ReleaseParticleIndex(self.ward_particle)
	end
end

function modifier_custom_death_ward:DeclareFunctions()
	local funcs ={
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
		MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
		MODIFIER_EVENT_ON_ATTACK_START,
		MODIFIER_EVENT_ON_ATTACK_LANDED
	}
	return funcs
end

function modifier_custom_death_ward:GetAbsoluteNoDamagePhysical()
  return 1
end

function modifier_custom_death_ward:GetAbsoluteNoDamagePure()
  return 1
end

function modifier_custom_death_ward:GetModifierAttackRangeBonus()
	local attack_range_bonus = 0
	if IsServer() then
		local parent = self:GetParent()
		local owner = parent:GetOwner()
		-- Check for bonus attack range talent
		local talent = owner:FindAbilityByName("special_bonus_unique_witch_doctor_1")
		if talent then
			if talent:GetLevel() ~= 0 then
				attack_range_bonus = talent:GetSpecialValueFor("value")
			end
		end
	end
	return attack_range_bonus
end

function modifier_custom_death_ward:OnAttackStart(event)
	local parent = self:GetParent()
	local attacker = event.attacker
	local target = event.target

	if attacker ~= parent then
		return
	end

	if target == nil then
		return
	end

	if target:IsNull() or attacker:IsNull() then
		return
	end

	-- Attack Sound
	parent:EmitSound("Hero_WitchDoctor_Ward.Attack")
end

function modifier_custom_death_ward:OnAttackLanded(event)
	local parent = self:GetParent()
	local owner = parent:GetOwner()
	local attacker = event.attacker
	local target = event.target

	if target ~= parent and attacker ~= parent then
		return
	end

	if target == nil or attacker == nil then
		return
	end

	if target:IsNull() or attacker:IsNull() then
		return
	end

	-- Don't trigger when someone attacks items; this also prevents bouncing off items
	if target.GetUnitName == nil then
		return
	end

	if not IsServer() then
		return
	end

	-- Handle attacks to destroy the Death Ward
	if target == parent then
		local total_hp = parent:GetMaxHealth() -- it should be divideable with 16, 4 and 8
		local creep_attacks_to_destroy = 16
		local melee_hero_attacks_to_destroy = 4
		local ranged_hero_attacks_to_destroy = 8

		local ability = self:GetAbility()
		if ability then
			creep_attacks_to_destroy = ability:GetSpecialValueFor("creep_hits_to_kill")
			melee_hero_attacks_to_destroy = ability:GetSpecialValueFor("melee_hero_hits_to_kill")
			ranged_hero_attacks_to_destroy = ability:GetSpecialValueFor("ranged_hero_hits_to_kill")
		end

		local damage = total_hp/creep_attacks_to_destroy
		if attacker:IsRealHero() then
			damage = total_hp/melee_hero_attacks_to_destroy
			if attacker:IsRangedAttacker() then
				damage = total_hp/ranged_hero_attacks_to_destroy
			end
		end

		-- To prevent dead wards staying in memory (preventing SetHealth(0) or SetHealth(-value) )
		if parent:GetHealth() - damage <= 0 then
			parent:Kill(ability, attacker)
		else
			parent:SetHealth(parent:GetHealth() - damage)
		end
	end

	-- Handle bounces with Aghanim Scepter
	if attacker == parent then
		-- If the owner of the Death Ward doesn't have Aghanim Scepter, don't continue
		if not owner:HasScepter() then
			return
		end

		local bounce_radius = 650
		local number_of_bounces = 4
		local targets_team = DOTA_UNIT_TARGET_TEAM_ENEMY
		local targets_type = bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC)
		local targets_flags = bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_NO_INVIS, DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE)

		local ability = self:GetAbility()
		if ability then
			bounce_radius = ability:GetSpecialValueFor("bounce_radius")
			number_of_bounces = ability:GetSpecialValueFor("bounces_scepter")
			targets_team = ability:GetAbilityTargetTeam()
			targets_type = ability:GetAbilityTargetType()
		end

		-- Find closest unit, doesn't matter if its a hero or not
		local targets = FindUnitsInRadius(parent:GetTeamNumber(), target:GetAbsOrigin(), nil, bounce_radius, targets_team, targets_type, targets_flags, FIND_CLOSEST, false)
		for _,enemy in pairs(targets) do
			if enemy and enemy ~= target and not enemy:IsAttackImmune() and number_of_bounces > 0 then
				local projectile = {
					Target = enemy,
					Source = target,
					Ability = ability,
					EffectName = "particles/units/heroes/hero_witchdoctor/witchdoctor_ward_attack.vpcf",
					bDodgable = true,
					bProvidesVision = false,
					iMoveSpeed = parent:GetProjectileSpeed(),
					iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1,
					ExtraData = {
						bounces_left = number_of_bounces,
					}
				}
				ProjectileManager:CreateTrackingProjectile(projectile)
				break
			end
		end
	end
end

if IsServer() then
	function modifier_custom_death_ward:CheckState()
		local parent = self:GetParent()
		local owner = parent:GetOwner()

		local state = {
			[MODIFIER_STATE_CANNOT_MISS] = owner:HasScepter(),
		}
		return state
	end
end

