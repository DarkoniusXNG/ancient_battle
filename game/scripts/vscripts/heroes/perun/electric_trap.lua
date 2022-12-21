perun_electric_trap = class({})

LinkLuaModifier("modifier_perun_electric_trap", "heroes/perun/electric_trap.lua", LUA_MODIFIER_MOTION_NONE)

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
	local trap = CreateUnitByName("npc_dota_custom_electric_trap", point, true, caster, caster, caster:GetTeamNumber())
	trap:SetOwner(caster:GetOwner())
	trap:SetControllableByPlayer(caster:GetPlayerID(), true)
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
	if not IsServer() then return end

	self:StartIntervalThink(0.1)
end

function modifier_perun_electric_trap:OnIntervalThink()
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

	local radius = ability:GetSpecialValueFor("radius")

	local parent = self:GetParent()
	local team = parent:GetTeamNumber()
	local point = parent:GetAbsOrigin()

	if parent:IsOutOfGame() or parent:IsUnselectable() or parent:IsInvulnerable() then
		return
	end

	-- Targetting constants
	local target_team = DOTA_UNIT_TARGET_TEAM_ENEMY
	local target_type = bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
	local target_flags = DOTA_UNIT_TARGET_FLAG_NONE

	local all_enemies = FindUnitsInRadius(team, point, nil, radius, target_team, target_type, target_flags, FIND_ANY_ORDER, false)
	local number_of_valid_enemies = 0
	for _, enemy in pairs(all_enemies) do
		if enemy and not enemy:IsNull() and not enemy:IsCustomWardTypeUnit() then
			number_of_valid_enemies = number_of_valid_enemies + 1
		end
	end

	if number_of_valid_enemies > 0 then
		-- Stop Interval think
		self:StartIntervalThink(-1)

		local delay = ability:GetSpecialValueFor("delay")
		local damage = ability:GetSpecialValueFor("damage")

		-- Damage table
		local damage_table = {}
		damage_table.attacker = caster
		damage_table.damage = damage
		damage_table.damage_type = DAMAGE_TYPE_MAGICAL
		damage_table.ability = ability

		Timers:CreateTimer(delay, function()
			if parent:IsNull() then
				return
			end
			if parent:IsAlive() and not parent:IsOutOfGame() and not parent:IsUnselectable() and not parent:IsInvulnerable() then
				local parent_team = parent:GetTeamNumber()
				local parent_origin = parent:GetAbsOrigin()
				local all = FindUnitsInRadius(parent_team, parent_origin, nil, radius, target_team, target_type, target_flags, FIND_ANY_ORDER, false)
				local enemies_again = {}
				for _, enemy in pairs(all) do
					if enemy and not enemy:IsNull() and not enemy:IsCustomWardTypeUnit() then
						table.insert(enemies_again, enemy)
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
						if not enemy:IsNull() then
							-- Victim
							damage_table.victim = enemy

							-- Explode (damage)
							ApplyDamage(damage_table)
						end
					end

					parent:ForceKill(false)
				else
					self:StartIntervalThink(0.1)
				end
			end
		end)
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
