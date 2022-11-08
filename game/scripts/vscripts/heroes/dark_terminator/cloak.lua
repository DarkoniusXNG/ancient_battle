dark_terminator_cloak = class({})

LinkLuaModifier("modifier_dark_terminator_cloak", "heroes/dark_terminator/cloak.lua", LUA_MODIFIER_MOTION_NONE)

function dark_terminator_cloak:OnSpellStart()
	local caster = self:GetCaster()

	local duration = self:GetSpecialValueFor("duration")

	local particle_smoke = "particles/units/heroes/hero_bounty_hunter/bounty_hunter_windwalk.vpcf"
	local sound_cast = "Hero_BountyHunter.WindWalk"

	-- Smoke particle
	local effect_cast = ParticleManager:CreateParticle(particle_smoke, PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(effect_cast, 0, caster:GetAbsOrigin())
	ParticleManager:ReleaseParticleIndex(effect_cast)

	-- Sound
	caster:EmitSound(sound_cast)
	
	-- Apply buff
	caster:AddNewModifier(caster, self, "modifier_dark_terminator_cloak", {duration = duration})
end

---------------------------------------------------------------------------------------------------

modifier_dark_terminator_cloak = class({})

function modifier_dark_terminator_cloak:IsHidden()
	return false
end

function modifier_dark_terminator_cloak:IsDebuff()
	return false
end

function modifier_dark_terminator_cloak:IsPurgable()
	return false
end

function modifier_dark_terminator_cloak:OnCreated()
  self.fade_time = self:GetAbility():GetSpecialValueFor("fade_time")
  self.move_speed = self:GetAbility():GetSpecialValueFor("bonus_move_speed")

  local particle = ParticleManager:CreateParticle("particles/generic_hero_status/status_invisibility_start.vpcf", PATTACH_ABSORIGIN, self:GetParent())
  ParticleManager:ReleaseParticleIndex(particle)
end

function modifier_dark_terminator_cloak:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_INVISIBILITY_LEVEL,
		MODIFIER_EVENT_ON_ABILITY_EXECUTED,
		MODIFIER_EVENT_ON_ATTACK,
	}
end

function modifier_dark_terminator_cloak:GetModifierMoveSpeedBonus_Percentage()
	return self.move_speed or self:GetAbility():GetSpecialValueFor("bonus_move_speed")
end

function modifier_dark_terminator_cloak:GetModifierInvisibilityLevel()
	return math.min(1, self:GetElapsedTime() / self.fade_time)
end

if IsServer() then
	function modifier_dark_terminator_cloak:OnAbilityExecuted(event)
		local unit = event.unit

		-- Check if unit exists
		if not unit or unit:IsNull() then
			return
		end

		if unit ~= self:GetParent() then
			return
		end

		self:Destroy()
	end

	function modifier_dark_terminator_cloak:OnAttack(event)
		local attacker = event.attacker

		-- Check if attacker exists
		if not attacker or attacker:IsNull() then
			return
		end

		if attacker ~= self:GetParent() then
			return
		end

		self:Destroy()
	end
end

function modifier_dark_terminator_cloak:CheckState()
	local state = {
		--[MODIFIER_STATE_NO_UNIT_COLLISION] = true, -- it's not part of the ability on purpose
		[MODIFIER_STATE_NOT_ON_MINIMAP_FOR_ENEMIES] = true,
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
		[MODIFIER_STATE_LOW_ATTACK_PRIORITY] = true,
	}

	if self:GetElapsedTime() >= self.fade_time then
		state[MODIFIER_STATE_INVISIBLE] = true
	end

	return state
end

function modifier_dark_terminator_cloak:GetPriority()
  return MODIFIER_PRIORITY_ULTRA
end
