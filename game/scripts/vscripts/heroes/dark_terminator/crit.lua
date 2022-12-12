LinkLuaModifier("modifier_dark_terminator_crit_attack", "heroes/dark_terminator/crit.lua", LUA_MODIFIER_MOTION_NONE)

dark_terminator_crit = class({})

function dark_terminator_crit:OnSpellStart()
	local caster = self:GetCaster()
	local caster_loc = caster:GetAbsOrigin()
	local radius = caster:GetAttackRange()
	local attack_interval = self:GetSpecialValueFor("attack_interval")

	local enemies = FindUnitsInRadius(
		caster:GetTeamNumber(),
		caster_loc,
		nil,
		radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
		bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_NOT_ATTACK_IMMUNE, DOTA_UNIT_TARGET_FLAG_NO_INVIS),
		FIND_ANY_ORDER,
		false
	)

	local max_count = 0
	for _, v in pairs(enemies) do
		max_count = max_count + 1
	end

	if max_count < 1 then
		return
	end

	local count = 0
	Timers:CreateTimer(function()
		if not caster or caster:IsNull() then
			return
		end
		if not caster:IsAlive() then
			return
		end
		local enemy = enemies[count]
		if enemy and not enemy:IsNull() then
			if enemy:IsAlive() and not enemy:IsAttackImmune() and caster:CanEntityBeSeenByMyTeam(enemy) and not caster:IsDisarmed() then
				-- Add a crit before the instant attack
				local buff = caster:AddNewModifier(caster, self, "modifier_dark_terminator_crit_attack", {})
				-- Instant attack
				caster:PerformAttack(enemy, true, true, true, false, false, false, false)
				-- Remove the crit when the instant attack is over
				buff:Destroy()
			end
		end
		count = count + 1
		if count > max_count then
			return
		end
		return attack_interval
	end)
end

---------------------------------------------------------------------------------------------------

modifier_dark_terminator_crit_attack = class({})

function modifier_dark_terminator_crit_attack:IsHidden()
	return true
end

function modifier_dark_terminator_crit_attack:IsDebuff()
	return false
end

function modifier_dark_terminator_crit_attack:IsPurgable()
	return false
end

function modifier_dark_terminator_crit_attack:RemoveOnDeath()
	return true
end

function modifier_dark_terminator_crit_attack:OnCreated()
	self.crit_multiplier = self:GetAbility():GetSpecialValueFor("crit_multiplier")
end

function modifier_dark_terminator_crit_attack:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
		MODIFIER_PROPERTY_PROJECTILE_NAME,
		MODIFIER_PROPERTY_TRANSLATE_ATTACK_SOUND,
	}
end

if IsServer() then
	function modifier_dark_terminator_crit_attack:GetModifierPreAttack_CriticalStrike(event)
		local target = event.target

		-- Check if attacked entity exists
		if not target or target:IsNull() then
			return 0
		end

		-- Check if attacked entity is an item, rune or something weird
		if target.GetUnitName == nil then
			return 0
		end

		-- Don't affect buildings, wards, invulnerable and dead units.
		if target:IsTower() or target:IsBarracks() or target:IsBuilding() or target:IsOther() or target:IsInvulnerable() or not target:IsAlive() then
			return 0
		end

		return self.crit_multiplier * 100
	end
end

function modifier_dark_terminator_crit_attack:GetModifierProjectileName()
	local r = RandomInt(1, 3)
	if r == 1 then
		return "particles/units/heroes/hero_tinker/tinker_missile.vpcf"
	elseif r == 2 then
		return "particles/units/heroes/hero_gyrocopter/gyro_base_attack.vpcf"
	else
		return "particles/units/heroes/hero_techies/techies_base_attack.vpcf"
	end
end

function modifier_dark_terminator_crit_attack:GetAttackSound()
	return "Hero_Gyrocopter.FlackCannon"
end
