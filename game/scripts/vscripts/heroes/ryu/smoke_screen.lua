if stealth_assassin_smoke_screen == nil then
	stealth_assassin_smoke_screen = class({})
end

LinkLuaModifier("modifier_stealth_assassin_smoke_screen_thinker", "heroes/ryu/smoke_screen.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_stealth_assassin_smoke_screen_debuff", "heroes/ryu/smoke_screen.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_stealth_assassin_smoke_screen_mini_stun", "heroes/ryu/smoke_screen.lua", LUA_MODIFIER_MOTION_NONE)

function stealth_assassin_smoke_screen:IsStealable()
	return true
end

function stealth_assassin_smoke_screen:IsHiddenWhenStolen()
	return false
end

function stealth_assassin_smoke_screen:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end


function stealth_assassin_smoke_screen:OnSpellStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()

	if not point then
		return
	end

	-- KVs
	local duration = self:GetSpecialValueFor("duration")
	local radius = self:GetSpecialValueFor("radius")

	-- Sound
	EmitSoundOnLocationWithCaster(point, "Hero_Riki.Smoke_Screen", caster)

	-- Derived variables
	local kv = {
		duration = duration,
		center_x = tostring(point.x),
		center_y = tostring(point.y),
	}
	local team = caster:GetTeamNumber()

	-- Thinker
	CreateModifierThinker(caster, self, "modifier_stealth_assassin_smoke_screen_thinker", kv, point, team, false)

	-- Shard mini-stun and destroying trees
	if caster:HasShardCustom() then
		-- Destroy trees
		GridNav:DestroyTreesAroundPoint(point, radius, true)

		local mini_stun_duration = self:GetSpecialValueFor("shard_mini_stun_duration")
		local enemies = FindUnitsInRadius(
			team,
			point,
			nil,
			radius,
			DOTA_UNIT_TARGET_TEAM_ENEMY,
			bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
			DOTA_UNIT_TARGET_FLAG_NONE,
			FIND_ANY_ORDER,
			false
		)

		for _, unit in pairs(enemies) do
			if unit and not unit:IsNull() and not unit:IsCustomWardTypeUnit() then
				-- Status Resistance fix
				local actual_duration = unit:GetValueChangedByStatusResistance(mini_stun_duration)
				-- Apply mini-stun
				unit:AddNewModifier(unit, self, "modifier_stealth_assassin_smoke_screen_mini_stun", {duration = actual_duration})
			end
		end
	end
end

function stealth_assassin_smoke_screen:ProcsMagicStick()
	return true
end

---------------------------------------------------------------------------------------------------

modifier_stealth_assassin_smoke_screen_thinker = class({})

function modifier_stealth_assassin_smoke_screen_thinker:IsHidden()
  return true
end

function modifier_stealth_assassin_smoke_screen_thinker:IsPurgable()
  return false
end

function modifier_stealth_assassin_smoke_screen_thinker:IsAura()
  return true
end

function modifier_stealth_assassin_smoke_screen_thinker:GetModifierAura()
  return "modifier_stealth_assassin_smoke_screen_debuff"
end

function modifier_stealth_assassin_smoke_screen_thinker:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_stealth_assassin_smoke_screen_thinker:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_stealth_assassin_smoke_screen_thinker:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_BUILDING)
end

function modifier_stealth_assassin_smoke_screen_thinker:GetAuraSearchFlags()
  return DOTA_UNIT_TARGET_FLAG_NONE
end

function modifier_stealth_assassin_smoke_screen_thinker:GetAuraDuration()
  return 0.01
end

function modifier_stealth_assassin_smoke_screen_thinker:OnCreated(kv)
	if not IsServer() then
		return
	end

	local parent = self:GetParent() -- thinker
	local radius = 375
	local ability = self:GetAbility()
	if ability and not ability:IsNull() then
		radius = ability:GetSpecialValueFor("radius")
	end

	local center = GetGroundPosition(Vector(tonumber(kv.center_x), tonumber(kv.center_y), 0), parent)

	-- Particle
	local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_riki/riki_smokebomb.vpcf", PATTACH_WORLDORIGIN, parent)
	ParticleManager:SetParticleControl(particle, 0, center)
	ParticleManager:SetParticleControl(particle, 1, Vector(radius, radius, radius))
	--self:AddParticle(particle, false, false, -1, false, false)
	self.particle = particle
end

function modifier_stealth_assassin_smoke_screen_thinker:OnDestroy()
	if not IsServer() then
		return
	end
	if self.particle then
		ParticleManager:DestroyParticle(self.particle, false)
		ParticleManager:ReleaseParticleIndex(self.particle)
	end
	local parent = self:GetParent()
	if parent and not parent:IsNull() then
		parent:ForceKill(false)
	end
end

---------------------------------------------------------------------------------------------------

modifier_stealth_assassin_smoke_screen_debuff = class({})

function modifier_stealth_assassin_smoke_screen_debuff:IsHidden()
  return false
end

function modifier_stealth_assassin_smoke_screen_debuff:IsDebuff()
  return true
end

function modifier_stealth_assassin_smoke_screen_debuff:IsPurgable()
  return true
end

function modifier_stealth_assassin_smoke_screen_debuff:OnCreated()
	local parent = self:GetParent()
	if IsServer() and parent:IsMagicImmune() then
		self:Destroy()
	end
	local ability = self:GetAbility()
	if ability and not ability:IsNull() then
		self.blind_pct = ability:GetSpecialValueFor("miss_rate")
		local move_speed_slow = ability:GetSpecialValueFor("move_speed_slow")
		local turn_rate_slow = 0
		self.vision_reduction = 0
		self.disarm_buildings = false

		local caster = ability:GetCaster() -- modifier:GetCaster() in this case will probably return a thinker and not a real caster of the spell
		if not caster:IsNull() and caster:HasShardCustom() then
			turn_rate_slow = ability:GetSpecialValueFor("shard_turn_rate_slow")
			self.vision_reduction = ability:GetSpecialValueFor("shard_vision_reduction")
			self.disarm_buildings = true
		end

		if IsServer() then
			-- Slows should be affected by status resistance
			self.move_speed_slow = parent:GetValueChangedByStatusResistance(move_speed_slow)
			self.turn_rate_slow = parent:GetValueChangedByStatusResistance(turn_rate_slow)
		else
			self.move_speed_slow = move_speed_slow
			self.turn_rate_slow = turn_rate_slow
		end
	end
end

modifier_stealth_assassin_smoke_screen_debuff.OnRefresh = modifier_stealth_assassin_smoke_screen_debuff.OnCreated

function modifier_stealth_assassin_smoke_screen_debuff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MISS_PERCENTAGE, -- blind
		MODIFIER_PROPERTY_TURN_RATE_PERCENTAGE,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_BONUS_VISION_PERCENTAGE,
	}
end

function modifier_stealth_assassin_smoke_screen_debuff:GetModifierMiss_Percentage()
	return self.blind_pct
end

function modifier_stealth_assassin_smoke_screen_debuff:GetModifierTurnRate_Percentage()
	return 0 - math.abs(self.turn_rate_slow)
end

function modifier_stealth_assassin_smoke_screen_debuff:GetModifierMoveSpeedBonus_Percentage()
	return 0 - math.abs(self.move_speed_slow)
end

function modifier_stealth_assassin_smoke_screen_debuff:GetBonusVisionPercentage()
	return 0 - math.abs(self.vision_reduction)
end

function modifier_stealth_assassin_smoke_screen_debuff:CheckState()
	local default = {
		[MODIFIER_STATE_SILENCED] = true,
	}
	local buildings = {
		[MODIFIER_STATE_DISARMED] = true,
	}
	if self:GetParent():IsBuilding() and self.disarm_buildings then
		return buildings
	end

	return default
end

function modifier_stealth_assassin_smoke_screen_debuff:GetEffectName()
	return "particles/generic_gameplay/generic_silenced.vpcf"
end

function modifier_stealth_assassin_smoke_screen_debuff:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end

---------------------------------------------------------------------------------------------------

modifier_stealth_assassin_smoke_screen_mini_stun = class({})

function modifier_stealth_assassin_smoke_screen_mini_stun:IsHidden() -- doesn't need tooltip
	return true
end

function modifier_stealth_assassin_smoke_screen_mini_stun:IsDebuff()
	return true
end

function modifier_stealth_assassin_smoke_screen_mini_stun:IsStunDebuff()
	return true
end

function modifier_stealth_assassin_smoke_screen_mini_stun:IsPurgable()
	return true
end

function modifier_stealth_assassin_smoke_screen_mini_stun:GetEffectName()
	return "particles/generic_gameplay/generic_stunned.vpcf"
end

function modifier_stealth_assassin_smoke_screen_mini_stun:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end

function modifier_stealth_assassin_smoke_screen_mini_stun:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
	}
end

function modifier_stealth_assassin_smoke_screen_mini_stun:GetOverrideAnimation()
	return ACT_DOTA_DISABLED
end

function modifier_stealth_assassin_smoke_screen_mini_stun:CheckState()
	return {
		[MODIFIER_STATE_STUNNED] = true,
	}
end
