if perun_electric_trap == nil then
	perun_electric_trap = class({})
end

LinkLuaModifier("modifier_perun_electric_trap", "heroes/perun/electric_trap.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_custom_electric_trap_stun", "heroes/perun/electric_trap.lua", LUA_MODIFIER_MOTION_NONE)

function perun_electric_trap:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function perun_electric_trap:OnSpellStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()

	if not point or not caster then
		return
	end

	-- Sound
	caster:EmitSound("Hero_Techies.StasisTrap.Plant")

	local trap_duration = self:GetSpecialValueFor("duration")
	local trap = CreateUnitByName("npc_dota_techies_stasis_trap", point, true, caster, caster, caster:GetTeamNumber())
	trap:SetOwner(caster)
	trap:SetDeathXP(12)
	trap:SetMaximumGoldBounty(20)
	trap:SetMinimumGoldBounty(10)
	trap:AddNewModifier(caster, self, "modifier_perun_electric_trap", {})
	trap:AddNewModifier(caster, self, "modifier_kill", {duration = trap_duration})
end

function perun_electric_trap:ProcsMagicStick()
	return true
end

-- Trap modifier -----------------------------------------------------------------------------------------------------

if modifier_perun_electric_trap == nil then
	modifier_perun_electric_trap = class({})
end

function modifier_perun_electric_trap:IsHidden()
	return true
end

function modifier_perun_electric_trap:IsPurgable()
	return false
end

function modifier_perun_electric_trap:IsDebuff()
	return false
end

function modifier_perun_electric_trap:OnCreated()
	if IsServer() then
		self:StartIntervalThink(0.15)
	end
end

function modifier_perun_electric_trap:OnIntervalThink()
	local ability = self:GetAbility()
	local radius = ability:GetSpecialValueFor("radius")

	if IsServer() then
		local parent = self:GetParent()
		local mine_team = parent:GetTeamNumber()
		local point = parent:GetAbsOrigin()

		if parent:IsOutOfGame() or parent:IsUnselectable() then
			return
		end

		-- Targetting constants
		local target_team = DOTA_UNIT_TARGET_TEAM_ENEMY
		local target_type = bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
		local target_flags = DOTA_UNIT_TARGET_FLAG_NONE

		local all_enemies = FindUnitsInRadius(mine_team, point, nil, radius, target_team, target_type, target_flags, FIND_ANY_ORDER, false)
		local number_of_valid_enemies = 0
		for _, enemy in pairs(all_enemies) do
			if enemy then
				local name = enemy:GetUnitName()
				if name ~= "npc_dota_custom_electric_trap" and name ~= "npc_dota_techies_stasis_trap" then
					number_of_valid_enemies = number_of_valid_enemies + 1
				end
			end
		end

		if number_of_valid_enemies > 0 then
			-- Stop Interval think
			self:StartIntervalThink(-1)

			local delay = ability:GetSpecialValueFor("delay")
			local stun_duration = ability:GetSpecialValueFor("stun_duration")

			Timers:CreateTimer(delay, function()
				if parent:IsNull() then
					return
				end
				if parent:IsAlive() and (not parent:IsOutOfGame()) and (not parent:IsUnselectable()) then
					local parent_team = parent:GetTeamNumber()
					local parent_origin = parent:GetAbsOrigin()
					--local parent_death_xp = parent:GetDeathXP()
					local all = FindUnitsInRadius(parent_team, parent_origin, nil, radius, target_team, target_type, target_flags, FIND_ANY_ORDER, false)
					local enemies_again = {}
					for _, enemy in pairs(all) do
						if enemy then
							local name = enemy:GetUnitName()
							if name ~= "npc_dota_custom_electric_trap" and name ~= "npc_dota_techies_stasis_trap" then
								table.insert(enemies_again, enemy)
							end
						end
					end

					if #enemies_again > 0 then

						-- Hide parent
						parent:AddNoDraw()

						-- Stasis Trap particles
						local particle_explode = "particles/units/heroes/hero_techies/techies_stasis_trap_explode.vpcf"
						local particle_explode_fx = ParticleManager:CreateParticle(particle_explode, PATTACH_WORLDORIGIN, parent)
						ParticleManager:SetParticleControl(particle_explode_fx, 0, parent:GetAbsOrigin())
						ParticleManager:SetParticleControl(particle_explode_fx, 1, Vector(radius, 1, 1))
						ParticleManager:SetParticleControl(particle_explode_fx, 3, parent:GetAbsOrigin())
						ParticleManager:ReleaseParticleIndex(particle_explode_fx)

						-- Stasis trap sound
						parent:EmitSound("Hero_Techies.ReactiveTazer.Detonate")

						for _, enemy in pairs(enemies_again) do
							if enemy then
								-- Status Resistance fix
								local enemy_stun_duration = enemy:GetValueChangedByStatusResistance(stun_duration)
								-- Apply Electric Trap stun debuff to the enemy
								enemy:AddNewModifier(parent, ability, "modifier_custom_electric_trap_stun", {duration = enemy_stun_duration})
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
					else
						self:StartIntervalThink(0.15)
					end
				end
			end)
		end
	end
end

function modifier_perun_electric_trap:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
		MODIFIER_PROPERTY_DISABLE_HEALING,
	}
end

function modifier_perun_electric_trap:GetAbsoluteNoDamageMagical()
	return 1
end

function modifier_perun_electric_trap:GetAbsoluteNoDamagePure()
	return 1
end

function modifier_perun_electric_trap:GetDisableHealing()
	return 1
end

function modifier_perun_electric_trap:CheckState()
	return {
		[MODIFIER_STATE_MAGIC_IMMUNE] = true,
		[MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true,
	}
end

-- Stun modifier -----------------------------------------------------------------------------------------------------

if modifier_custom_electric_trap_stun == nil then
	modifier_custom_electric_trap_stun = class({})
end

function modifier_custom_electric_trap_stun:IsHidden()
	return false
end

function modifier_custom_electric_trap_stun:IsDebuff()
	return true
end

function modifier_custom_electric_trap_stun:IsStunDebuff()
	return true
end

function modifier_custom_electric_trap_stun:IsPurgable()
	return true
end

function modifier_custom_electric_trap_stun:CheckState()
	return {
		[MODIFIER_STATE_STUNNED] = true,
		[MODIFIER_STATE_FROZEN] = true
	}
end

function modifier_custom_electric_trap_stun:GetStatusEffectName()
	return "particles/status_fx/status_effect_techies_stasis.vpcf"
end
