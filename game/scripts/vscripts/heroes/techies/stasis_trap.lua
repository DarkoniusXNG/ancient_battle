techies_custom_stasis_trap = class({})

LinkLuaModifier("modifier_techies_custom_stasis_trap", "heroes/techies/stasis_trap.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_techies_custom_stasis_trap_stun", "heroes/techies/stasis_trap.lua", LUA_MODIFIER_MOTION_NONE)

function techies_custom_stasis_trap:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function techies_custom_stasis_trap:OnSpellStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()

	if not point or not caster then
		return
	end

	-- Sound
	caster:EmitSound("Hero_Techies.StasisTrap.Plant")

	local name = "npc_dota_techies_stasis_trap"

	-- Check for BIO mines talent
	local talent = caster:FindAbilityByName("special_bonus_unique_techies_custom_5")
	if talent and talent:GetLevel() > 0 then
		name = "npc_dota_techies_custom_stasis_trap_moving"
	end

	local trap_duration = self:GetSpecialValueFor("duration")
	local trap = CreateUnitByName(name, point, true, caster, caster, caster:GetTeamNumber())
	trap:SetOwner(caster:GetOwner())
	trap:SetControllableByPlayer(caster:GetPlayerID(), true)
	trap:SetDeathXP(10)
	trap:SetMaximumGoldBounty(15)
	trap:SetMinimumGoldBounty(15)
	trap:SetBaseMaxHealth(100)
	trap:SetMaxHealth(100)
	trap:SetHealth(100)
	trap:AddNewModifier(caster, self, "modifier_techies_custom_stasis_trap", {})
	trap:AddNewModifier(caster, self, "modifier_kill", {duration = trap_duration})
end

function techies_custom_stasis_trap:ProcsMagicStick()
	return true
end

-- Trap modifier ----------------------------------------------------------------------------------

if modifier_techies_custom_stasis_trap == nil then
	modifier_techies_custom_stasis_trap = class({})
end

function modifier_techies_custom_stasis_trap:IsHidden()
	return true
end

function modifier_techies_custom_stasis_trap:IsPurgable()
	return false
end

function modifier_techies_custom_stasis_trap:IsDebuff()
	return false
end

function modifier_techies_custom_stasis_trap:OnCreated()
	if not IsServer() then return end

	local ability = self:GetAbility()
	if not ability or ability:IsNull() then
		return
	end

	self.activated = false

	local activation_delay = ability:GetSpecialValueFor("activation_delay")
	local think_interval = ability:GetSpecialValueFor("think_interval")
	self:StartIntervalThink(activation_delay - think_interval)
end

function modifier_techies_custom_stasis_trap:OnIntervalThink()
	if not IsServer() then return end

	local caster = self:GetCaster()
	local ability = self:GetAbility()
	if not ability or ability:IsNull() or not caster or caster:IsNull() then
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
		local radius = ability:GetSpecialValueFor("radius")

		local parent = self:GetParent()
		local mine_team = parent:GetTeamNumber()
		local point = parent:GetAbsOrigin()

		if parent:IsOutOfGame() or parent:IsUnselectable() or parent:IsInvulnerable() then
			return
		end

		if (caster:GetAbsOrigin() - parent:GetAbsOrigin()):Length2D() <= 1000 then
			self.allow_ms = true
		else
			self.allow_ms = false
		end

		-- Targetting constants
		local target_team = DOTA_UNIT_TARGET_TEAM_ENEMY
		local target_type = bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
		local target_flags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES

		local all_enemies = FindUnitsInRadius(mine_team, point, nil, radius, target_team, target_type, target_flags, FIND_ANY_ORDER, false)
		local number_of_valid_enemies = 0
		for _, enemy in pairs(all_enemies) do
			-- Add here which enemy units should be ignored
			if enemy and not enemy:IsNull() and not enemy:IsCustomWardTypeUnit() and not enemy:HasFlyMovementCapability() then
				number_of_valid_enemies = number_of_valid_enemies + 1
			end
		end

		if number_of_valid_enemies > 0 then
			-- Stop Interval think
			self:StartIntervalThink(-1)

			local delay = ability:GetSpecialValueFor("detonation_delay")
			local stun_duration = ability:GetSpecialValueFor("stun_duration")
			local think_interval = ability:GetSpecialValueFor("think_interval")

			local modifier = self
			Timers:CreateTimer(delay, function()
				if parent:IsNull() then
					return
				end
				if parent:IsAlive() and not parent:IsOutOfGame() and not parent:IsUnselectable() and not parent:IsInvulnerable() then
					local parent_team = parent:GetTeamNumber() -- we check this again if trap changed teams somehow
					local parent_origin = parent:GetAbsOrigin() -- we check this again if trap changed position
					--local parent_death_xp = parent:GetDeathXP()
					local all = FindUnitsInRadius(parent_team, parent_origin, nil, radius, target_team, target_type, target_flags, FIND_ANY_ORDER, false)
					local enemies_again = {}
					for _, enemy in pairs(all) do
						if enemy and not enemy:IsNull() and not enemy:IsCustomWardTypeUnit() and not enemy:HasFlyMovementCapability() then
							table.insert(enemies_again, enemy)
						end
					end

					if #enemies_again > 0 then

						-- Hide parent
						parent:AddNoDraw()

						-- Stasis Trap particles
						local particle_explode = "particles/units/heroes/hero_techies/techies_stasis_trap_explode.vpcf"
						local particle_explode_fx = ParticleManager:CreateParticle(particle_explode, PATTACH_WORLDORIGIN, parent)
						ParticleManager:SetParticleControl(particle_explode_fx, 0, parent_origin)
						ParticleManager:SetParticleControl(particle_explode_fx, 1, Vector(radius, radius, 1))
						ParticleManager:SetParticleControl(particle_explode_fx, 3, parent_origin)
						ParticleManager:ReleaseParticleIndex(particle_explode_fx)

						-- Stasis trap sound
						parent:EmitSound("Hero_Techies.ReactiveTazer.Detonate")

						for _, enemy in pairs(enemies_again) do
							if enemy and not enemy:IsNull() and not enemy:IsMagicImmune() then
								-- Status Resistance fix
								local enemy_stun_duration = enemy:GetValueChangedByStatusResistance(stun_duration)
								-- Apply Electric Trap stun debuff to the enemy
								enemy:AddNewModifier(parent, ability, "modifier_techies_custom_stasis_trap_stun", {duration = enemy_stun_duration})
							end
						end

						parent:ForceKill(false)

						-- local hero_flags = bit.bor(DOTA_UNIT_TARGET_FLAG_DEAD, DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS, DOTA_UNIT_TARGET_FLAG_NOT_CREEP_HERO)
						-- local enemy_heroes_around = FindUnitsInRadius(parent_team, parent_origin, nil, 1500, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, hero_flags, FIND_ANY_ORDER, false)
						-- local number_of_heroes = #enemy_heroes_around
						-- for _, hero in pairs(enemy_heroes_around) do
							-- if number_of_heroes > 0 then
								-- hero:AddExperience(parent_death_xp/number_of_heroes, DOTA_ModifyXP_CreepKill, false, false)
							-- end
						-- end
					elseif modifier and not modifier:IsNull() then
						modifier:StartIntervalThink(think_interval)
					end
				end
			end)
		end
	else
		local think_interval = ability:GetSpecialValueFor("think_interval")
		-- Change Interval think
		self:StartIntervalThink(think_interval)
		self.activated = true
	end
end

function modifier_techies_custom_stasis_trap:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
		MODIFIER_PROPERTY_DISABLE_HEALING,
	}
end

function modifier_techies_custom_stasis_trap:GetAbsoluteNoDamageMagical()
	return 1
end

function modifier_techies_custom_stasis_trap:GetAbsoluteNoDamagePure()
	return 1
end

function modifier_techies_custom_stasis_trap:GetDisableHealing()
	return 1
end

function modifier_techies_custom_stasis_trap:CheckState()
	return {
		[MODIFIER_STATE_MAGIC_IMMUNE] = true,
		[MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
		[MODIFIER_STATE_ROOTED] = not self.allow_ms,
	}
end

-- Stun modifier -----------------------------------------------------------------------------------------------------

if modifier_techies_custom_stasis_trap_stun == nil then
	modifier_techies_custom_stasis_trap_stun = class({})
end

function modifier_techies_custom_stasis_trap_stun:IsHidden()
	return false
end

function modifier_techies_custom_stasis_trap_stun:IsDebuff()
	return true
end

function modifier_techies_custom_stasis_trap_stun:IsStunDebuff()
	return true
end

function modifier_techies_custom_stasis_trap_stun:IsPurgable()
	return true
end

function modifier_techies_custom_stasis_trap_stun:CheckState()
	return {
		[MODIFIER_STATE_STUNNED] = true,
		[MODIFIER_STATE_FROZEN] = true,
	}
end

function modifier_techies_custom_stasis_trap_stun:GetStatusEffectName()
	return "particles/status_fx/status_effect_techies_stasis.vpcf"
end

function modifier_techies_custom_stasis_trap_stun:StatusEffectPriority()
	return MODIFIER_PRIORITY_NORMAL
end
