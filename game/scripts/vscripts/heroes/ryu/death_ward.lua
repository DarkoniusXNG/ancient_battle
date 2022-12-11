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
	local point = self:GetCursorPosition()

	if not point then
		return
	end

	local caster = self:GetCaster()

	-- Create Death Ward unit
	local death_ward = CreateUnitByName(unit_name, point, true, caster, caster, caster:GetTeamNumber())
	death_ward:SetOwner(caster)
	death_ward:SetControllableByPlayer(caster:GetPlayerID(), true)

	-- Sound
	death_ward:EmitSound("Hero_WitchDoctor.Death_WardBuild")

	-- Set Death Ward damage
	--local damage = self:GetSpecialValueFor("damage")
	-- Check for bonus damage talent
	--local talent = caster:FindAbilityByName("special_bonus_unique_stealth_assassin_1")
	--if talent and talent:GetLevel() > 0 then
		--damage = damage + talent:GetSpecialValueFor("value")
	--end
	--death_ward:SetBaseDamageMax(damage)
	--death_ward:SetBaseDamageMin(damage)

	-- Apply modifiers to Death Ward
	death_ward:AddNewModifier(caster, self, "modifier_custom_death_ward", {})
	local ward_duration = self:GetSpecialValueFor("duration_tooltip")
	death_ward:AddNewModifier(caster, self, "modifier_kill", {duration = ward_duration})
	death_ward:AddNewModifier(caster, self, "modifier_phased", {duration = 0.03}) -- unit will insta unstuck after this built-in modifier expires.

	-- Variable needed for later
	self.ward_unit = death_ward
end

function stealth_assassin_death_ward:OnProjectileHit_ExtraData(target, location, data)
	-- If target doesn't exist (disjointed), don't continue
	if not target or target:IsNull() then
		return
	end

	-- Get ward owner and source of the damage
	local owner
	local damage_source
	if not self.ward_unit or self.ward_unit:IsNull() then
		local caster = self:GetCaster()
		owner = caster
		damage_source = caster
	else
		owner = self.ward_unit:GetOwner()
		damage_source = self.ward_unit
	end

	-- If owner doesn't exist, don't continue
	if not owner or owner:IsNull() then
		return
	end

	-- if damage_source doesn't exist, don't continue
	if not damage_source or damage_source:IsNull() then
		return
	end

	-- Damage of the projectile -- Getting the damage of the death ward unit will not be correct because of buffs and auras
	local damage = self:GetSpecialValueFor("damage")
	-- Check for bonus damage talent
	local talent = owner:FindAbilityByName("special_bonus_unique_stealth_assassin_1")
	if talent and talent:GetLevel() > 0 then
		damage = damage + talent:GetSpecialValueFor("value")
	end

	-- Damage table of the projectile
	local damage_table = {}
	damage_table.attacker = damage_source
	damage_table.damage = damage
	damage_table.damage_type = self:GetAbilityDamageType()
	damage_table.ability = self
	damage_table.victim = target
	damage_table.damage_flags = bit.bor(DOTA_DAMAGE_FLAG_BYPASSES_BLOCK, DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL)

	ApplyDamage(damage_table)

	-- If the owner of the Death Ward doesn't have Aghanim Scepter, don't continue
	if not owner:HasScepter() then
		return
	end

	-- Copy data table into new_data table
	local new_data = {}
	for k, v in pairs(data) do
		new_data[k] = v
	end

	-- Mark the target as hit
	new_data[tostring(target:GetEntityIndex())] = 1

	local bounce_radius = self:GetSpecialValueFor("scepter_bounce_radius")
	local targets_flags = bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_NOT_ATTACK_IMMUNE, DOTA_UNIT_TARGET_FLAG_NO_INVIS, DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE)
	-- Find the nearest enemy and fire a projectile from target towards that enemy
	local enemies = FindUnitsInRadius(damage_source:GetTeamNumber(), target:GetAbsOrigin(), nil, bounce_radius, self:GetAbilityTargetTeam(), self:GetAbilityTargetType(), targets_flags, FIND_CLOSEST, false)
	for _, enemy in ipairs(enemies) do
		if enemy ~= target and new_data[tostring(enemy:GetEntityIndex())] ~= 1 then
			local projectile_info = {
				Target = enemy,
				Source = target,
				Ability = self,
				EffectName = "particles/units/heroes/hero_witchdoctor/witchdoctor_ward_attack.vpcf",
				bDodgable = true,
				bProvidesVision = false,
				bVisibleToEnemies = true,
				bReplaceExisting = false,
				iMoveSpeed = damage_source:GetProjectileSpeed(),
				bIsAttack = false,
				iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_HITLOCATION, --DOTA_PROJECTILE_ATTACHMENT_ATTACK_1
				ExtraData = new_data,
			}

			ProjectileManager:CreateTrackingProjectile(projectile_info)
			break
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

	local owner = self:GetCaster()
	local attack_range_bonus = 0
	-- Check for bonus attack range talent
	local talent = owner:FindAbilityByName("special_bonus_unique_stealth_assassin_2")
	if talent and talent:GetLevel() > 0 then
		attack_range_bonus = talent:GetSpecialValueFor("value")
	end

	self.attack_range_bonus = attack_range_bonus

	if IsServer() then
		-- Change Acquisition range if there is an attack range bonus
		parent:SetAcquisitionRange(parent:GetAcquisitionRange() + attack_range_bonus)

		-- Change Vision
		local day_vision = math.max(parent:GetAttackRange() + attack_range_bonus, 1200)
		local night_vision = math.max(parent:GetAttackRange() + attack_range_bonus, 800)
		parent:SetDayTimeVisionRange(day_vision)
		parent:SetNightTimeVisionRange(night_vision)
	end
end

function modifier_custom_death_ward:OnDestroy()
	if self.ward_particle then
		ParticleManager:DestroyParticle(self.ward_particle, true)
		ParticleManager:ReleaseParticleIndex(self.ward_particle)
	end
end

function modifier_custom_death_ward:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
		MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_DISABLE_HEALING,
		MODIFIER_EVENT_ON_ATTACK_START,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end

function modifier_custom_death_ward:GetAbsoluteNoDamagePhysical()
	return 1
end

function modifier_custom_death_ward:GetAbsoluteNoDamageMagical()
	return 1
end

function modifier_custom_death_ward:GetAbsoluteNoDamagePure()
	return 1
end

function modifier_custom_death_ward:GetModifierAttackRangeBonus()
	return self.attack_range_bonus
end

function modifier_custom_death_ward:GetModifierAttackSpeedBonus_Constant()
  return -30
end

function modifier_custom_death_ward:GetDisableHealing()
	return 1
end

if IsServer() then
	function modifier_custom_death_ward:OnAttackStart(event)
		local parent = self:GetParent()
		local attacker = event.attacker
		local target = event.target

		-- Check if attacker exists
		if not attacker or attacker:IsNull() then
			return
		end

		-- Check if attacker has this modifier
		if attacker ~= parent then
			return
		end

		-- Check if attacked entity exists
		if not target or target:IsNull() then
			return
		end

		-- Check if attacked entity is an item, rune or something weird
		if target.GetUnitName == nil then
			return
		end

		-- Attack Sound
		parent:EmitSound("Hero_WitchDoctor_Ward.Attack")
	end

	function modifier_custom_death_ward:OnAttackLanded(event)
		local parent = self:GetParent()
		local owner = self:GetCaster() --parent:GetOwner()
		local attacker = event.attacker
		local target = event.target

		-- Check if attacker exists
		if not attacker or attacker:IsNull() then
			return
		end

		-- Check if attacked entity exists
		if not target or target:IsNull() then
			return
		end

		-- Don't trigger when attacking items or runes; this also prevents bouncing off items or runes
		if target.GetUnitName == nil then
			return
		end

		local ability = self:GetAbility()
		if not ability or ability:IsNull() then
			return
		end

		-- Handle attacks to destroy the Death Ward
		if target == parent then
			local total_hp = parent:GetMaxHealth() -- it should be divideable with 16, 4 and 8
			local creep_attacks_to_destroy = 16
			local melee_hero_attacks_to_destroy = 4
			local ranged_hero_attacks_to_destroy = 8

			creep_attacks_to_destroy = ability:GetSpecialValueFor("creep_hits_to_kill")
			melee_hero_attacks_to_destroy = ability:GetSpecialValueFor("melee_hero_hits_to_kill")
			ranged_hero_attacks_to_destroy = ability:GetSpecialValueFor("ranged_hero_hits_to_kill")

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

		if attacker == parent then
			-- Damage of the projectile
			local damage = ability:GetSpecialValueFor("damage")
			-- Check for bonus damage talent
			local talent = owner:FindAbilityByName("special_bonus_unique_stealth_assassin_1")
			if talent and talent:GetLevel() > 0 then
				damage = damage + talent:GetSpecialValueFor("value")
			end

			local damage_source = parent

			-- Damage table of the projectile
			local damage_table = {}
			damage_table.attacker = damage_source
			damage_table.damage = damage
			damage_table.damage_type = ability:GetAbilityDamageType()
			damage_table.ability = ability
			damage_table.victim = target
			damage_table.damage_flags = bit.bor(DOTA_DAMAGE_FLAG_BYPASSES_BLOCK, DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL)

			ApplyDamage(damage_table)

			-- If the owner of the Death Ward doesn't have Aghanim Scepter, don't continue
			if not owner:HasScepter() then
				return
			end

			-- Initialize data table for the scepter bounce
			local data = {}

			-- Mark the target as hit
			data[tostring(target:GetEntityIndex())] = 1

			local bounce_radius = ability:GetSpecialValueFor("scepter_bounce_radius")
			local targets_flags = bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_NOT_ATTACK_IMMUNE, DOTA_UNIT_TARGET_FLAG_NO_INVIS, DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE)

			-- Find closest enemy and fire a projectile from the attacked target towards that enemy
			local enemies = FindUnitsInRadius(parent:GetTeamNumber(), target:GetAbsOrigin(), nil, bounce_radius, ability:GetAbilityTargetTeam(), ability:GetAbilityTargetType(), targets_flags, FIND_CLOSEST, false)
			for _, enemy in ipairs(enemies) do
				if enemy ~= target then
					local projectile_info = {
						Target = enemy,
						Source = target,
						Ability = ability,
						EffectName = "particles/units/heroes/hero_witchdoctor/witchdoctor_ward_attack.vpcf",
						bDodgable = true,
						bProvidesVision = false,
						bVisibleToEnemies = true,
						bReplaceExisting = false,
						iMoveSpeed = parent:GetProjectileSpeed(),
						bIsAttack = false,
						iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_HITLOCATION,--DOTA_PROJECTILE_ATTACHMENT_ATTACK_1,
						ExtraData = data,
					}

					ProjectileManager:CreateTrackingProjectile(projectile_info)
					break
				end
			end
		end
	end

	function modifier_custom_death_ward:CheckState()
		--local parent = self:GetParent()
		local owner = self:GetCaster() --parent:GetOwner()
		return {
			[MODIFIER_STATE_CANNOT_MISS] = owner:HasScepter(),
		}
	end
end

