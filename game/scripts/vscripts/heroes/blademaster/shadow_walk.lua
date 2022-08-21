blademaster_shadow_walk = class({})

LinkLuaModifier("modifier_custom_wind_walk_buff", "heroes/blademaster/shadow_walk.lua", LUA_MODIFIER_MOTION_NONE)

function blademaster_shadow_walk:OnSpellStart()
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
	caster:AddNewModifier(caster, self, "modifier_custom_wind_walk_buff", {duration = duration})
	--modifier_invisible
end

---------------------------------------------------------------------------------------------------

modifier_custom_wind_walk_buff = class({})

function modifier_custom_wind_walk_buff:IsHidden()
	return false
end

function modifier_custom_wind_walk_buff:IsDebuff()
	return false
end

function modifier_custom_wind_walk_buff:IsPurgable()
	return true
end

function modifier_custom_wind_walk_buff:OnCreated()
	self.fade_time = self:GetAbility():GetSpecialValueFor("fade_time")
	self.move_speed = self:GetAbility():GetSpecialValueFor("bonus_move_speed")

	local particle = ParticleManager:CreateParticle("particles/generic_hero_status/status_invisibility_start.vpcf", PATTACH_ABSORIGIN, self:GetParent())
	ParticleManager:ReleaseParticleIndex(particle)
end

function modifier_custom_wind_walk_buff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_INVISIBILITY_LEVEL,
		MODIFIER_EVENT_ON_ABILITY_EXECUTED,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end

function modifier_custom_wind_walk_buff:GetModifierMoveSpeedBonus_Percentage()
	return self.move_speed or self:GetAbility():GetSpecialValueFor("bonus_move_speed")
end

function modifier_custom_wind_walk_buff:GetModifierInvisibilityLevel()
	return math.min(1, self:GetElapsedTime() / self.fade_time)
end

if IsServer() then
	function modifier_custom_wind_walk_buff:OnAbilityExecuted(event)
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

	function modifier_custom_wind_walk_buff:OnAttackLanded(event)
		local parent = self:GetParent()
		local ability = self:GetAbility()
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

		-- Check for existence of GetUnitName method to determine if target is a unit or an item
		-- items don't have that method -> nil; if the target is an item, don't damage, remove invis
		if target.GetUnitName == nil then
			self:Destroy()
			return
		end
		
		-- Don't damage buildings and wards, remove invis
		if target:IsTower() or target:IsBarracks() or target:IsBuilding() or target:IsOther() then
			self:Destroy()
			return
		end
		
		if not ability or ability:IsNull() then
			self:Destroy()
			return
		end

		local damage = ability:GetSpecialValueFor("bonus_damage")

		local damage_table = {}
		damage_table.attacker = parent
		damage_table.damage_type = DAMAGE_TYPE_PHYSICAL
		damage_table.damage_flags = bit.bor(DOTA_DAMAGE_FLAG_BYPASSES_BLOCK, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL)
		damage_table.ability = ability
		damage_table.victim = target
		damage_table.damage = damage

		ApplyDamage(damage_table)

		local particle = ParticleManager:CreateParticle("particles/msg_fx/msg_crit.vpcf", PATTACH_OVERHEAD_FOLLOW, target)
		ParticleManager:SetParticleControl(particle, 1, Vector(9, damage, 4))
		ParticleManager:SetParticleControl(particle, 2, Vector(1, 4, 0))
		ParticleManager:SetParticleControl(particle, 3, Vector(255, 0, 0))

		self:Destroy()
	end
end

function modifier_custom_wind_walk_buff:CheckState()
	local state = {
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
	}

	if self:GetElapsedTime() >= self.fade_time then
		state[MODIFIER_STATE_INVISIBLE] = true
	end

	return state
end

--function modifier_custom_wind_walk_buff:GetPriority()
  --return MODIFIER_PRIORITY_ULTRA
--end
