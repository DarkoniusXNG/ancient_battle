if death_knight_resurrection == nil then
	death_knight_resurrection = class({})
end

LinkLuaModifier("modifier_custom_resurrected", "heroes/death_knight/resurrection.lua", LUA_MODIFIER_MOTION_NONE)

function death_knight_resurrection:GetCooldown(level)
	local caster = self:GetCaster()
	local base_cooldown = self.BaseClass.GetCooldown(self, level)

	-- Talent that decreases cooldown
	local talent = caster:FindAbilityByName("special_bonus_unique_death_knight_6")
	if talent and talent:GetLevel() > 0 then
	  return base_cooldown - math.abs(talent:GetSpecialValueFor("value"))
	end

	return base_cooldown
end

function death_knight_resurrection:OnSpellStart()
	local caster = self:GetCaster()
	-- KV variables
	local duration = self:GetSpecialValueFor("duration")
	local radius = self:GetSpecialValueFor("radius")
	local resurrections_limit = self:GetSpecialValueFor("resurrections_limit")

	-- Sound
	caster:EmitSound("Hero_Abaddon.AphoticShield.Cast")
	
	-- Particle
	--"EffectName"        "particles/units/heroes/hero_skeletonking/wraith_king_reincarnate_explode.vpcf"
	--"EffectAttachType"  "follow_origin"
	--"Target"            "CASTER"
	local caster_team = caster:GetTeamNumber()
	local playerID = caster:GetPlayerOwnerID()

	if radius == 0 then
		radius = FIND_UNITS_EVERYWHERE
	end

	local center = caster:GetAbsOrigin() or Vector(0,0,0)

	local units = FindUnitsInRadius(caster_team, center, nil, radius, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_BASIC, bit.bor(DOTA_UNIT_TARGET_FLAG_DEAD, DOTA_UNIT_TARGET_FLAG_NOT_ANCIENTS), FIND_ANY_ORDER, false)
	local number_of_resurrections = 0

	for _, unit in pairs(units) do
		if unit and not unit:IsNull() then
			if not unit:IsAlive() and number_of_resurrections < resurrections_limit then
				local unit_name = unit:GetUnitName()
				if not unit:IsLaneCreepCustom() then
					--print("Resurrecting non-lane creep.")
					unit:SetTeam(caster_team)
					unit:SetOwner(caster)
					unit:SetControllableByPlayer(playerID, true)
					unit:RespawnUnit()
					unit:AddNewModifier(caster, self, "modifier_custom_resurrected", {})
					unit:AddNewModifier(caster, self, "modifier_kill", {duration = duration})
					unit:AddNewModifier(caster, nil, "modifier_phased", {duration = 0.03}) -- unit will insta unstuck after this built-in modifier expires.
					self:FireParticleOnceForUnit(unit)
				else
					--print("Resurrecting Lane Creep.")
					local resurected = CreateUnitByName(unit_name, unit:GetAbsOrigin(), true, caster, caster, caster_team)
					resurected:SetOwner(caster)
					resurected:SetControllableByPlayer(playerID, true)
					resurected:AddNewModifier(caster, self, "modifier_custom_resurrected", {})
					resurected:AddNewModifier(caster, self, "modifier_kill", {duration = duration})
					resurected:AddNewModifier(caster, nil, "modifier_phased", {duration = 0.03}) -- unit will insta unstuck after this built-in modifier expires.
					self:FireParticleOnceForUnit(resurected)
				end
				
				number_of_resurrections = number_of_resurrections + 1
			end
		end
	end
end

function death_knight_resurrection:FireParticleOnceForUnit(unit)
	if not unit or unit:IsNull() then
		return
	end

	local particle_name = "particles/units/heroes/hero_skeletonking/wraith_king_reincarnate.vpcf"
	local delay = 1
	local particle_death_fx = ParticleManager:CreateParticle(particle_name, PATTACH_CUSTOMORIGIN, unit)
	ParticleManager:SetParticleAlwaysSimulate(particle_death_fx)
	ParticleManager:SetParticleControl(particle_death_fx, 0, unit:GetAbsOrigin())
	ParticleManager:SetParticleControl(particle_death_fx, 1, Vector(delay, 0, 0))
	ParticleManager:SetParticleControl(particle_death_fx, 11, Vector(200, 0, 0))
	ParticleManager:ReleaseParticleIndex(particle_death_fx)
end

---------------------------------------------------------------------------------------------------

if modifier_custom_resurrected == nil then
	modifier_custom_resurrected = class({})
end

function modifier_custom_resurrected:IsHidden()
	return false
end

function modifier_custom_resurrected:IsDebuff()
	return false
end

function modifier_custom_resurrected:IsPurgable()
	return false
end

function modifier_custom_resurrected:GetStatusEffectName()
	return "particles/status_fx/status_effect_abaddon_borrowed_time.vpcf"
end

function modifier_custom_resurrected:StatusEffectPriority()
	return 15
end

function modifier_custom_resurrected:CheckState()
	local state = {
		[MODIFIER_STATE_MAGIC_IMMUNE] = true, -- To prevent Purge instant kill
		[MODIFIER_STATE_DOMINATED] = true,
	}

	return state
end

