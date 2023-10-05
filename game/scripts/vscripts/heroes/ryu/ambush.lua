stealth_assassin_ambush = stealth_assassin_ambush or class({})

LinkLuaModifier("modifier_stealth_assassin_ambush_debuff", "heroes/ryu/ambush.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_stealth_assassin_ambush_mini_stun", "heroes/ryu/ambush.lua", LUA_MODIFIER_MOTION_NONE)

function stealth_assassin_ambush:CastFilterResultTarget(target)
	local default_result = self.BaseClass.CastFilterResultTarget(self, target)

	if target:IsCustomWardTypeUnit() then
		return UF_FAIL_CUSTOM
	end

	return default_result
end

function stealth_assassin_ambush:GetCustomCastErrorTarget(target)
	if target:IsCustomWardTypeUnit() then
		return "#dota_hud_error_cant_cast_on_other"
	end
	return ""
end

function stealth_assassin_ambush:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	-- Check for spell block and spell immunity (latter because of lotus)
	if target:TriggerSpellAbsorb(self) or target:IsMagicImmune() then
		return
	end

	-- KVs
	local radius = self:GetSpecialValueFor("radius")
	local base_damage = self:GetSpecialValueFor("base_damage")
	local hp_percent_damage = self:GetSpecialValueFor("max_hp_percent_damage")
	local mini_stun_duration = self:GetSpecialValueFor("mini_stun_duration")
	local slow_duration = self:GetSpecialValueFor("slow_duration")

	-- Status Resistance fix
	local actual_duration = target:GetValueChangedByStatusResistance(mini_stun_duration)

	-- Apply mini-stun
	target:AddNewModifier(caster, self, "modifier_stealth_assassin_ambush_mini_stun", {duration = actual_duration})

	-- Derived variables
	local target_location = target:GetAbsOrigin()
	local target_max_hp = target:GetMaxHealth()

	local damage_table = {}
	damage_table.attacker = caster
	damage_table.damage_type = self:GetAbilityDamageType()
	damage_table.ability = self
	damage_table.victim = target

	-- Targetting constants
	local target_team = DOTA_UNIT_TARGET_TEAM_FRIENDLY
	local target_type = bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
	local target_flags = DOTA_UNIT_TARGET_FLAG_NONE

	-- Finding target's allies in a radius
	local candidates = FindUnitsInRadius(target:GetTeamNumber(), target_location, nil, radius, target_team, target_type, target_flags, FIND_ANY_ORDER, false)

	-- Count the number of target's allies around the target hero or unit (excluding invalid units and the target itself)
	local number_of_nearby_enemies = 0
	for _, unit in pairs(candidates) do
		if unit and not unit:IsNull() and not unit:IsCustomWardTypeUnit() and unit ~= target then
			number_of_nearby_enemies = number_of_nearby_enemies + 1
		end
	end

	-- Calculating chance to fail (1 enemy - 20%; 2 enemies - 50%; 3 enemies - 66.67%; 4 enemies - 75%; 5 enemies - 80% ... 35 enemies - 97% etc.)
	local chance_to_fail
	if number_of_nearby_enemies > 1 then
		chance_to_fail = 100-(100/number_of_nearby_enemies)
	else
		if number_of_nearby_enemies == 1 then
			chance_to_fail = 20
		else
			chance_to_fail = 0
		end
	end

	-- Random number generation
	local random_number = RandomFloat(0, 100.0)

	-- Setting the damage
	if random_number > chance_to_fail then
		damage_table.damage = math.ceil(base_damage + hp_percent_damage*target_max_hp*0.01)

		-- Apply Slow debuff
		target:AddNewModifier(caster, self, "modifier_stealth_assassin_ambush_debuff", {duration = slow_duration})

		-- Sound (success)
		target:EmitSound("Hero_Riki.SleepDart.Damage")
	else
		damage_table.damage = base_damage

		-- Sound (fail)
		target:EmitSound("Hero_Riki.SleepDart.Target") --"Hero_OgreMagi.Fireblast.Target"
	end

	-- Applying the damage
	ApplyDamage(damage_table)
end

function stealth_assassin_ambush:ProcsMagicStick()
	return true
end

---------------------------------------------------------------------------------------------------

modifier_stealth_assassin_ambush_debuff = class({})

function modifier_stealth_assassin_ambush_debuff:IsHidden() -- needs tooltip
  return false
end

function modifier_stealth_assassin_ambush_debuff:IsDebuff()
  return true
end

function modifier_stealth_assassin_ambush_debuff:IsPurgable()
  return true
end

function modifier_stealth_assassin_ambush_debuff:OnCreated()
	local parent = self:GetParent()
	local ability = self:GetAbility()
	if ability and not ability:IsNull() then
		local move_speed_slow = ability:GetSpecialValueFor("move_speed_slow")

		if IsServer() then
			-- Slow should be affected by status resistance
			self.move_speed_slow = parent:GetValueChangedByStatusResistance(move_speed_slow)
		else
			self.move_speed_slow = move_speed_slow
		end
	end
end

modifier_stealth_assassin_ambush_debuff.OnRefresh = modifier_stealth_assassin_ambush_debuff.OnCreated

function modifier_stealth_assassin_ambush_debuff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
end

function modifier_stealth_assassin_ambush_debuff:GetModifierMoveSpeedBonus_Percentage()
	return 0 - math.abs(self.move_speed_slow)
end

--function modifier_stealth_assassin_ambush_debuff:GetEffectName()
	--return ""
--end

--function modifier_stealth_assassin_ambush_debuff:GetEffectAttachType()
	--return PATTACH_
--end

---------------------------------------------------------------------------------------------------

modifier_stealth_assassin_ambush_mini_stun = class({})

function modifier_stealth_assassin_ambush_mini_stun:IsHidden() -- doesn't need tooltip
	return true
end

function modifier_stealth_assassin_ambush_mini_stun:IsDebuff()
	return true
end

function modifier_stealth_assassin_ambush_mini_stun:IsStunDebuff()
	return true
end

function modifier_stealth_assassin_ambush_mini_stun:IsPurgable()
	return false
end

function modifier_stealth_assassin_ambush_mini_stun:GetEffectName()
	return "particles/generic_gameplay/generic_stunned.vpcf"
end

function modifier_stealth_assassin_ambush_mini_stun:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end

function modifier_stealth_assassin_ambush_mini_stun:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
	}
end

function modifier_stealth_assassin_ambush_mini_stun:GetOverrideAnimation()
	return ACT_DOTA_DISABLED
end

function modifier_stealth_assassin_ambush_mini_stun:CheckState()
	return {
		[MODIFIER_STATE_STUNNED] = true,
	}
end
