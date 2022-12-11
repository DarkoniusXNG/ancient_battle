sohei_guard = class({})

LinkLuaModifier("modifier_sohei_guard_reflect", "heroes/sohei/sohei_guard.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_sohei_guard_knockback", "heroes/sohei/sohei_guard.lua", LUA_MODIFIER_MOTION_HORIZONTAL)

function sohei_guard:OnSpellStart()
	local caster = self:GetCaster()
	local caster_loc = caster:GetAbsOrigin()

	-- Sound
	caster:EmitSound("Sohei.Guard")
	--caster:EmitSound("Hero_Antimage.Counterspell.Cast")

	-- Check if the caster is stunned or banished
	if caster:IsStunned() or caster:IsOutOfGame() then
		local hp_cost_percent = self:GetSpecialValueFor("hp_cost")
		local max_hp = caster:GetMaxHealth()
		local current_hp = caster:GetHealth()
		local hp_cost = max_hp * hp_cost_percent / 100
		if hp_cost >= current_hp then
			caster:Kill(self, caster)
			return
		else
			caster:SetHealth(current_hp - hp_cost)
		end
	end

	-- Strong Dispel
	caster:Purge(false, true, false, true, false)

	-- Cancel Flurry of Blows
	caster:RemoveModifierByName("modifier_sohei_flurry_self")

	-- Apply the buff
	local duration = self:GetSpecialValueFor("guard_duration")
	--caster:AddNewModifier(caster, self, "modifier_item_lotus_orb_active", {duration = duration})
	caster:AddNewModifier(caster, self, "modifier_sohei_guard_reflect", {duration = duration})

	-- AoE knockback
	local radius = self:GetSpecialValueFor("knockback_max_distance")
	local pushTargets = FindUnitsInRadius(
		caster:GetTeamNumber(),
		caster_loc,
		nil,
		radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
		FIND_ANY_ORDER,
		false
	)

	for _, target in pairs(pushTargets) do
		if target and not target:IsNull() then
			local target_loc = target:GetAbsOrigin()
			local direction = target_loc - caster_loc
			local distance = radius - direction:Length2D() + caster:GetPaddedCollisionRadius()
			local knockback_duration = self:GetSpecialValueFor("knockback_duration")
			local ki_strike = caster:FindAbilityByName("sohei_momentum_strike")

			if caster:HasShardCustom() and ki_strike and ki_strike:GetLevel() > 0 then
				direction.z = 0
				direction = direction:Normalized()
				target:AddNewModifier(caster, self, "modifier_sohei_momentum_strike_knockback", {
					duration = knockback_duration,
					distance = radius,
					speed = radius / knockback_duration,
					direction_x = direction.x,
					direction_y = direction.y,
				})
				target:AddNewModifier(caster, self, "modifier_sohei_momentum_strike_slow", {duration = ki_strike:GetSpecialValueFor("slow_duration")})
			else
				target:AddNewModifier(caster, self, "modifier_sohei_guard_knockback", {
					duration = knockback_duration,
					distance = distance,
					tree_radius = target:GetPaddedCollisionRadius(),
				})
			end
		end
	end
end

function sohei_guard:OnProjectileHit_ExtraData(target, location, extra_data)
  if not target or not location then
    return
  end

  if target:IsMagicImmune() or target:IsAttackImmune() then
    return
  end

  local attacker = self:GetCaster()
  local damage = extra_data.damage --self.reflect_damage -- use this if ExtraData doesn't work

  target:EmitSound("Sohei.GuardHit")

  -- Initialize damage table
  local damage_table = {
    attacker = attacker,
    damage = damage,
    damage_type = DAMAGE_TYPE_PHYSICAL,
    damage_flags = bit.bor(DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL),
    ability = self,
    victim = target,
  }

  -- Apply damage
  ApplyDamage(damage_table)

  return true
end

---------------------------------------------------------------------------------------------------

-- Guard projectile reflect modifier
modifier_sohei_guard_reflect = class({})

function modifier_sohei_guard_reflect:IsHidden()
	return false
end

function modifier_sohei_guard_reflect:IsDebuff()
	return false
end

function modifier_sohei_guard_reflect:IsPurgable()
	return true
end

function modifier_sohei_guard_reflect:GetEffectName()
	return "particles/hero/sohei/guard.vpcf"
end

function modifier_sohei_guard_reflect:GetEffectAttachType()
	return PATTACH_CENTER_FOLLOW
end

function modifier_sohei_guard_reflect:OnCreated()
  if IsServer() then
    local parent = self:GetParent()

    --if self.nPreviewFX == nil then
      --self.nPreviewFX = ParticleManager:CreateParticle("particles/hero/sohei/reflection_shield.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
      --self.nPreviewFX = ParticleManager:CreateParticle("particles/units/heroes/hero_antimage/antimage_spellshield_reflect.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, parent)
    --end

    if parent.stored_reflected_spells == nil then
      parent.stored_reflected_spells = {}
    end
  end
end

function modifier_sohei_guard_reflect:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_AVOID_DAMAGE,
		MODIFIER_PROPERTY_ABSORB_SPELL,
		MODIFIER_PROPERTY_REFLECT_SPELL,
		MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
	}
end

if IsServer() then
	function modifier_sohei_guard_reflect:GetModifierAvoidDamage(event)
		local parent = self:GetParent()
		local ability = self:GetAbility()
		local attacker = event.attacker
		if event.ranged_attack == true and event.damage_category == DOTA_DAMAGE_CATEGORY_ATTACK and not attacker:IsNull() then
			local info = {
				EffectName = attacker:GetRangedProjectileName(),
				Ability = ability,
				Source = parent,
				vSourceLoc = parent:GetAbsOrigin(),
				Target = attacker,
				iMoveSpeed = attacker:GetProjectileSpeed(),
				bDodgeable = true,
				bProvidesVision = true,
				iVisionRadius = 250,
				iVisionTeamNumber = parent:GetTeamNumber(),
				--bIsAttack = true,
				--bReplaceExisting = false,
				--bIgnoreObstructions = true,
				iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1, -- DOTA_PROJECTILE_ATTACHMENT_HITLOCATION,
				bDrawsOnMinimap = false,
				bVisibleToEnemies = true,
				ExtraData = {
					damage = math.max(event.original_damage, event.damage),
				}
			}

			-- Create a tracking projectile
			ProjectileManager:CreateTrackingProjectile(info)

			-- If ExtraData doesn't work
			--if ability then
				--ability.reflect_damage = math.max(event.original_damage, event.damage)
			--end

			parent:EmitSound("Sohei.GuardProc")

			return 1
		end

		return 0
	end

	-- Spell Block
	function modifier_sohei_guard_reflect:GetAbsorbSpell(event)
		local caster = event.ability:GetCaster()
		if caster:GetTeamNumber() == self:GetParent():GetTeamNumber() then
			return 0
		end
		return 1
	end

	-- Spell Reflect
	function modifier_sohei_guard_reflect:GetReflectSpell(event)
		local parent = self:GetParent()
		local cast_ability = event.ability
		local ability_name = cast_ability:GetAbilityName()
		local target = cast_ability:GetCaster()
		local ability_level = cast_ability:GetLevel()
		local ability_behaviour = cast_ability:GetBehavior()
		if type(ability_behaviour) == 'userdata' then
			ability_behaviour = tonumber(tostring(ability_behaviour))
		end

		local exception_list = {
			["rubick_spell_steal"] = true,
			["morphling_replicate"] = true,
			--["grimstroke_soul_chain"] = true,
			--["legion_commander_duel"] = true,
		}

		-- Do not reflect allied spells for any reason
		if target:GetTeamNumber() == parent:GetTeamNumber() then
			return 0
		end

		-- Check if cast_ability is marked as reflected spell
		-- (reflecting reflected spells should not be possible)
		if cast_ability.reflected_spell then
			return 0
		end

		local reflecting_modifiers = {
			"modifier_item_lotus_orb_active", -- Lotus Orb active
			"modifier_item_reactive_reflect", -- Reflection Shard active
			"modifier_item_mirror_shield",    -- Mirror Shield
			"modifier_antimage_counterspell", -- Anti-Mage Counter Spell active
			self:GetName(),
		}

		-- Check for reflecting modifiers
		for i = 1, #reflecting_modifiers do
			if target:HasModifier(reflecting_modifiers[i]) then
				-- If target has reflecting modifiers don't continue to prevent infinite loops
				-- (reflecting reflected spells should not be possible)
				return 0
			end
		end

		-- If ability is on the exception list do nothing
		if exception_list[ability_name] then
			return 0
		end

		-- If ability is channeling, dont reflect it because channeling abilities are buggy as hell
		if bit.band(ability_behaviour, DOTA_ABILITY_BEHAVIOR_CHANNELLED) == DOTA_ABILITY_BEHAVIOR_CHANNELLED then
			return 0
		end

		-- Check if the parent already has the reflected ability
		local old = false
		for _, ability in pairs(parent.stored_reflected_spells) do
			if ability and not ability:IsNull() then
				if ability:GetAbilityName() == ability_name then
					old = true
					break
				end
			end
		end

		-- Reflect Sound
		--parent:EmitSound("Hero_Antimage.Counterspell.Target")
		parent:EmitSound("Item.LotusOrb.Activate")

		-- Reflect particles
		local burst = ParticleManager:CreateParticle("particles/hero/sohei/immunity_sphere_yellow.vpcf", PATTACH_ABSORIGIN, parent)
		local leaves = ParticleManager:CreateParticle("particles/hero/sohei/reflect_sakura_leaves.vpcf", PATTACH_ABSORIGIN, parent)
		Timers:CreateTimer(1.5, function()
			ParticleManager:DestroyParticle(burst, false)
			ParticleManager:ReleaseParticleIndex(burst)
			ParticleManager:DestroyParticle(leaves, false)
			ParticleManager:ReleaseParticleIndex(leaves)
		end)

		local reflect_ability
		local parent_ability
		if old then
			reflect_ability = parent:FindAbilityByName(ability_name)
		else
			parent_ability = parent:FindAbilityByName(ability_name)
			if parent_ability then
				-- This is a rare case (Rubick stole the spell and then casted that same spell on the target he stole it from and target has modifier_sohei_guard_reflect)
				-- when parent already has the event.ability naturally (it wasn't added or stolen), then it should not be stolen or hidden because that would mess up things
				-- We shouldn't duplicate abilities if the parent already has the event.ability
				parent:SetCursorCastTarget(target) -- Set the target for the spell.
				parent_ability:OnSpellStart() -- Cast the spell back (to Rubick).
				return 0 -- Don't continue
			end
			reflect_ability = parent:AddAbility(ability_name) -- Add the spell to the parent for the first time
			if reflect_ability then
				reflect_ability:SetStolen(true) -- Just to be safe with some interactions.
				reflect_ability:SetHidden(true) -- Hide the ability on the parent.
				reflect_ability.reflected_spell = true  -- Tag this ability as reflected
				if parent.stored_reflected_spells == nil then
					parent.stored_reflected_spells = {}
				end
				table.insert(parent.stored_reflected_spells, reflect_ability) -- Store the spell reference for future use.
			end
		end

		if not reflect_ability then
			-- If reflect_ability becomes nil for some reason, don't continue
			return 0
		end

		reflect_ability:SetLevel(ability_level)       -- Set level to be the same as the level of the original ability
		parent:SetCursorCastTarget(target)            -- Set the target for the spell.
		reflect_ability:OnSpellStart()                -- Cast the spell.

		-- not putting 'return 1' at the end just in case Valve suddenly makes GetReflectSpell fully functional
	end

	function modifier_sohei_guard_reflect:OnDestroy()
		local parent = self:GetParent()
		parent:EmitSound("Item.LotusOrb.Destroy")
		-- if self.nPreviewFX then
			-- ParticleManager:DestroyParticle(self.nPreviewFX, false)
			-- ParticleManager:ReleaseParticleIndex(self.nPreviewFX)
			-- self.nPreviewFX = nil
		-- end
		for k, ability in pairs(parent.stored_reflected_spells) do
			if ability and not ability:IsNull() then
				Timers:CreateTimer(8, function()
					-- Check if ability is removed already
					if ability and not ability:IsNull() then
						--ability:RemoveSelf()
						if parent and not parent:IsNull() then
							parent:RemoveAbility(ability:GetAbilityName())
							parent.stored_reflected_spells[k] = nil
						end
					end
				end)
			end
		end
	end
end

function modifier_sohei_guard_reflect:GetModifierStatusResistanceStacking()
  local parent = self:GetParent()
  local talent = parent:FindAbilityByName("special_bonus_unique_sohei_6")
  if talent and talent:GetLevel() > 0 then
    return talent:GetSpecialValueFor("value")
  end
  return 0
end

---------------------------------------------------------------------------------------------------

modifier_sohei_guard_knockback = class({})

function modifier_sohei_guard_knockback:IsHidden()
	return true
end

function modifier_sohei_guard_knockback:IsDebuff()
	return true
end

function modifier_sohei_guard_knockback:IsPurgable()
	return false
end

function modifier_sohei_guard_knockback:IsStunDebuff()
	return false
end

function modifier_sohei_guard_knockback:GetPriority()
	return DOTA_MOTION_CONTROLLER_PRIORITY_HIGHEST
end

function modifier_sohei_guard_knockback:CheckState()
	return {
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
	}
end

function modifier_sohei_guard_knockback:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION_RATE,
	}
end

function modifier_sohei_guard_knockback:GetOverrideAnimation()
	return ACT_DOTA_FLAIL
end

function modifier_sohei_guard_knockback:GetOverrideAnimationRate()
	return 2.5
end

if IsServer() then
	function modifier_sohei_guard_knockback:OnCreated(event)
		local parent = self:GetParent()
		local caster = self:GetCaster()

		local difference = parent:GetAbsOrigin() - caster:GetAbsOrigin()

		-- Movement parameters
		self.direction = difference:Normalized()
		self.distance = event.distance
		self.tree_radius = event.tree_radius
		self.speed = event.distance / event.duration

		if self:ApplyHorizontalMotionController() == false then
			self:Destroy()
			return
		end
	end

	function modifier_sohei_guard_knockback:OnDestroy()
		local parent = self:GetParent()
		local parent_origin = parent:GetAbsOrigin()

		parent:RemoveHorizontalMotionController(self)

		-- Unstuck the parent
		FindClearSpaceForUnit(parent, parent_origin, false)
		ResolveNPCPositions(parent_origin, 128)
		GridNav:DestroyTreesAroundPoint(parent_origin, self.tree_radius, true)
	end

	function modifier_sohei_guard_knockback:UpdateHorizontalMotion(parent, deltaTime)
		if not parent or parent:IsNull() or not parent:IsAlive() then
			return
		end

		local parentOrigin = parent:GetAbsOrigin()
		local tickTraveled = self.speed * deltaTime
		tickTraveled = math.min(tickTraveled, self.distance)
		local tickOrigin = parentOrigin + tickTraveled * self.direction
		tickOrigin = Vector(tickOrigin.x, tickOrigin.y, GetGroundHeight(tickOrigin, parent))

		self.distance = self.distance - tickTraveled

		-- Unstucking (ResolveNPCPositions) is happening OnDestroy;
		parent:SetAbsOrigin(tickOrigin)

		GridNav:DestroyTreesAroundPoint(tickOrigin, self.tree_radius, false)
	end

	function modifier_sohei_guard_knockback:OnHorizontalMotionInterrupted()
		self:Destroy()
	end
end

function modifier_sohei_guard_knockback:GetEffectName()
  return "particles/hero/sohei/knockback.vpcf"
end

function modifier_sohei_guard_knockback:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end
