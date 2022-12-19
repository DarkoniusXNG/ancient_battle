techies_custom_land_mines = class({})

LinkLuaModifier("modifier_techies_custom_land_mine", "heroes/techies/land_mines.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_techies_custom_mine_slow", "heroes/techies/mine_slow.lua", LUA_MODIFIER_MOTION_NONE)

function techies_custom_land_mines:GetAOERadius()
	return self:GetSpecialValueFor("small_radius")
end

function techies_custom_land_mines:OnSpellStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()

	if not point or not caster then
		return
	end

	-- Sound
	caster:EmitSound("Hero_Techies.RemoteMine.Plant") -- "Hero_Techies.StickyBomb.Plant"

	local mine_duration = self:GetSpecialValueFor("duration")
	local mine = CreateUnitByName("npc_dota_techies_land_mine", point, true, caster, caster, caster:GetTeamNumber())
	mine:SetOwner(caster:GetOwner())
	mine:SetControllableByPlayer(caster:GetPlayerID(), true)
	mine:SetDeathXP(20)
	mine:SetMaximumGoldBounty(30)
	mine:SetMinimumGoldBounty(30)
	mine:SetBaseMaxHealth(100)
	mine:SetMaxHealth(100)
	mine:SetHealth(100)
	mine:AddNewModifier(caster, self, "modifier_techies_custom_land_mine", {})
	mine:AddNewModifier(caster, self, "modifier_kill", {duration = mine_duration})

	-- Check for moving mines talent
	local talent = caster:FindAbilityByName("special_bonus_unique_techies_custom_5")
	if talent and talent:GetLevel() > 0 then
		mine:SetMoveCapability(DOTA_UNIT_CAP_MOVE_GROUND)
		mine:SetBaseMoveSpeed(talent:GetSpecialValueFor("value"))
	end
end

function techies_custom_land_mines:ProcsMagicStick()
	return true
end

-- Mine modifier ----------------------------------------------------------------------------------

if modifier_techies_custom_land_mine == nil then
	modifier_techies_custom_land_mine = class({})
end

function modifier_techies_custom_land_mine:IsHidden()
	return true
end

function modifier_techies_custom_land_mine:IsPurgable()
	return false
end

function modifier_techies_custom_land_mine:IsDebuff()
	return false
end

function modifier_techies_custom_land_mine:OnCreated()
	if not IsServer() then return end

	local ability = self:GetAbility()
	if not ability or ability:IsNull() then
		return
	end

	self.activated = false
	self.visible = true

	local activation_delay = ability:GetSpecialValueFor("activation_delay") -- also the fade time
	-- Check for activation delay talent
	local talent = self:GetCaster():FindAbilityByName("special_bonus_unique_techies_custom_3")
	if talent and talent:GetLevel() > 0 then
		activation_delay = activation_delay - math.abs(talent:GetSpecialValueFor("value"))
	end
	local think_interval = ability:GetSpecialValueFor("think_interval")
	self:StartIntervalThink(activation_delay - think_interval)
end

function modifier_techies_custom_land_mine:OnIntervalThink()
	if not IsServer() then return end

	local function TableContains(t, element)
		if t == nil then return false end
		for _, v in pairs(t) do
			if v == element then
				return true
			end
		end
		return false
	end

	local ability = self:GetAbility()
	if not ability or ability:IsNull() then
		-- Remove the mine
		local parent = self:GetParent()
		if parent and not parent:IsNull() then
			parent:ForceKill(false)
		end
		-- Stop Interval think
		self:StartIntervalThink(-1)
		return
	end
	if self.activated then
		local small_radius = ability:GetSpecialValueFor("small_radius") -- also the trigger radius
		local big_radius = ability:GetSpecialValueFor("big_radius")

		local parent = self:GetParent()
		local team = parent:GetTeamNumber()
		local point = parent:GetAbsOrigin()

		if parent:IsOutOfGame() or parent:IsUnselectable() or parent:IsInvulnerable() then
			return
		end

		-- Targetting constants
		local target_team = DOTA_UNIT_TARGET_TEAM_ENEMY
		local target_type = bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BUILDING)
		local target_flags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES

		local enemies_big_radius = FindUnitsInRadius(team, point, nil, big_radius, target_team, target_type, target_flags, FIND_ANY_ORDER, false)
		local enemies_small_radius = FindUnitsInRadius(team, point, nil, small_radius, target_team, target_type, target_flags, FIND_ANY_ORDER, false)

		if #enemies_big_radius < 1 then
			self.visible = false
			return -- no need to continue
		else
			self.visible = true
		end

		local sound_needed = false
		local number_of_valid_enemies = 0
		for _, enemy in pairs(enemies_small_radius) do
			-- Add here which enemy units should be ignored
			if enemy and not enemy:IsNull() then
				if not enemy:IsCustomWardTypeUnit() and not enemy:HasFlyMovementCapability() then
					number_of_valid_enemies = number_of_valid_enemies + 1
				end
				if not enemy:CanEntityBeSeenByMyTeam(parent) then
					sound_needed = true
				end
			end
		end

		if number_of_valid_enemies > 0 then
			-- Stop Interval think
			self:StartIntervalThink(-1)

			-- Sound alert only if enemies cant see it
			if sound_needed then
				parent:EmitSound("Hero_Techies.StickyBomb.Priming") -- "Hero_Techies.LandMine.Priming" ; "Hero_Techies.RemoteMine.Priming"
			end

			local delay = ability:GetSpecialValueFor("detonation_delay")
			local think_interval = ability:GetSpecialValueFor("think_interval")
			local small_radius_dmg = ability:GetSpecialValueFor("small_radius_damage")
			local big_radius_dmg = ability:GetSpecialValueFor("big_radius_damage")
			local building_dmg_reduction = ability:GetSpecialValueFor("building_dmg_reduction")

			local caster = self:GetCaster()
			if not caster or caster:IsNull() then
				-- Remove the mine
				if parent and not parent:IsNull() then
					parent:ForceKill(false)
				end
				return
			end

			-- Check for mine slow talent
			local talent2 = caster:FindAbilityByName("special_bonus_unique_techies_custom_1")
			local has_talent = talent2 and talent2:GetLevel() > 0
			local slow_duration = 0
			if has_talent then
				slow_duration = talent2:GetSpecialValueFor("value")
			end

			-- Damage table
			local damage_table = {}
			damage_table.attacker = caster
			damage_table.damage_type = DAMAGE_TYPE_PHYSICAL -- Composite dmg doesn't exist anymore, so we reduce the physical dmg with magic resistance
			damage_table.damage_flags = DOTA_DAMAGE_FLAG_BYPASSES_BLOCK
			damage_table.ability = ability

			Timers:CreateTimer(delay, function()
				if parent:IsNull() then
					return
				end
				if parent:IsAlive() and not parent:IsOutOfGame() and not parent:IsUnselectable() and not parent:IsInvulnerable() then
					local parent_team = parent:GetTeamNumber() -- we check this again if mine changed teams somehow
					local parent_origin = parent:GetAbsOrigin() -- we check this again if mine changed position
					--local parent_death_xp = parent:GetDeathXP()
					local enemies_big_radius = FindUnitsInRadius(parent_team, parent_origin, nil, big_radius, target_team, target_type, target_flags, FIND_ANY_ORDER, false)
					local enemies_small_radius = FindUnitsInRadius(parent_team, parent_origin, nil, small_radius, target_team, target_type, target_flags, FIND_ANY_ORDER, false)
					for _, enemy in pairs(enemies_big_radius) do
						if enemy and not enemy:IsNull() and not enemy:IsCustomWardTypeUnit() and not enemy:HasFlyMovementCapability() then
							-- Apply mine slow if talent is learned
							if has_talent then
								enemy:AddNewModifier(parent, ability, "modifier_techies_custom_mine_slow", {duration = slow_duration})
							end

							-- Victim
							damage_table.victim = enemy

							-- Calculate damage
							local mine_dmg = big_radius_dmg
							-- Increase the damage if enemy is closer to the center
							if TableContains(enemies_small_radius, enemy) then
								mine_dmg = small_radius_dmg
							end
							local enemy_magic_resist = enemy:GetMagicalArmorValue()
							local composite_dmg = mine_dmg * (1 - enemy_magic_resist)
							damage_table.damage = composite_dmg
							if enemy:IsBuilding() or enemy:IsBarracks() or enemy:IsTower() or enemy:IsFort() then
								damage_table.damage = composite_dmg * building_dmg_reduction / 100
							end

							-- Explode (damage)
							ApplyDamage(damage_table)
						end
					end

					-- Hide the mine
					parent:AddNoDraw()

					-- Explode particles
					local pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_techies/techies_land_mine_explode.vpcf", PATTACH_CUSTOMORIGIN, parent)
					ParticleManager:SetParticleControl(pfx, 0, parent_origin)
					ParticleManager:SetParticleControl(pfx, 2, Vector(big_radius, big_radius, big_radius))

					-- Destroy trees
					GridNav:DestroyTreesAroundPoint(parent_origin, big_radius, false)

					Timers:CreateTimer(5.0, function()
						ParticleManager:DestroyParticle(pfx, true)
						ParticleManager:ReleaseParticleIndex(pfx)
					end)

					-- Explode sound
					parent:EmitSound("Hero_Techies.StickyBomb.Detonate") -- Hero_Techies.LandMine.Detonate

					-- Remove the mine
					parent:ForceKill(false)

					-- local hero_flags = bit.bor(DOTA_UNIT_TARGET_FLAG_DEAD, DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS, DOTA_UNIT_TARGET_FLAG_NOT_CREEP_HERO)
					-- local enemy_heroes_around = FindUnitsInRadius(parent_team, parent_origin, nil, 1500, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, hero_flags, FIND_ANY_ORDER, false)
					-- local number_of_heroes = #enemy_heroes_around
					-- for _, hero in pairs(enemy_heroes_around) do
						-- if number_of_heroes > 0 then
							-- hero:AddExperience(parent_death_xp/number_of_heroes, DOTA_ModifyXP_CreepKill, false, false)
						-- end
					-- end
				end
			end)
		end
	else
		local think_interval = ability:GetSpecialValueFor("think_interval")
		-- Change Interval think
		self:StartIntervalThink(think_interval)
		self.activated = true
		self.visible = false
	end
end

function modifier_techies_custom_land_mine:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
		MODIFIER_PROPERTY_DISABLE_HEALING,
	}
end

function modifier_techies_custom_land_mine:GetAbsoluteNoDamageMagical()
	return 1
end

function modifier_techies_custom_land_mine:GetAbsoluteNoDamagePure()
	return 1
end

function modifier_techies_custom_land_mine:GetDisableHealing()
	return 1
end

function modifier_techies_custom_land_mine:CheckState()
	return {
		[MODIFIER_STATE_MAGIC_IMMUNE] = true,
		[MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
		[MODIFIER_STATE_INVISIBLE] = not self.visible,
	}
end
