LinkLuaModifier("modifier_temporal_jump", "heroes/warp_beast/warp_beast_temporal_jump.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_temporal_jump_charges", "heroes/warp_beast/warp_beast_temporal_jump.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_warp_beast_temporal_radius_talent", "heroes/warp_beast/warp_beast_temporal_jump.lua", LUA_MODIFIER_MOTION_NONE)

warp_beast_temporal_jump = class({})

function warp_beast_temporal_jump:GetAOERadius()
	local caster = self:GetCaster()
	local radius = self:GetSpecialValueFor("radius")

	-- Talent that increases radius
	local talent = caster:FindAbilityByName("special_bonus_unique_warp_beast_jump_radius")
	if talent and talent:GetLevel() > 0 then
		radius = radius + talent:GetSpecialValueFor("value")
	end

	return radius
end

function warp_beast_temporal_jump:GetIntrinsicModifierName()
	return "modifier_temporal_jump_charges"
end

function warp_beast_temporal_jump:OnSpellStart()
	local caster = self:GetCaster()
	local jumpTime = self:GetSpecialValueFor("jump_time")

	local point = caster:GetCursorPosition()
	local jumpHeight = self:GetSpecialValueFor("jump_height")

	local latchModifier = caster:FindModifierByName("modifier_latch")
	if latchModifier and latchModifier.target then
		latchModifier.target:RemoveModifierByNameAndCaster("modifier_latch_target", caster)
		caster:RemoveModifierByName("modifier_latch")
	end

	-- Disable recasting this ability while active
	self:SetActivated(false)

	-- Disable casting Latch ability while active
	local latchAbility = caster:FindAbilityByName("warp_beast_latch")
	latchAbility:SetActivated(false)

	local time = 0
	local interval = 0.03

	local origin = caster:GetAbsOrigin()

	if (point - origin):Length2D() < 0.1 then point = point + RandomVector(1) end

	local forwardVec = (point - origin):Normalized()
	local distance = ((point - origin):Length2D() * interval) / jumpTime

	--Emit sound
	caster:EmitSound("Hero_FacelessVoid.TimeWalk.Aeons")

	local modifier = caster:AddNewModifier(caster, self, "modifier_temporal_jump", {})
	caster:SetModel("models/items/courier/faceless_rex/faceless_rex_flying.vmdl")

	Timers:CreateTimer(time, function()

		time = time + interval

		-- if caster:HasModifier("modifier_knockback") and caster:IsStunned() then
		-- 	-- Re-activates the spell
		-- 	caster:SetModel("models/items/courier/faceless_rex/faceless_rex.vmdl")
		-- 	self:SetActivated(true)
		-- 	latchAbility:SetActivated(true)
		-- 	if modifier then modifier:Destroy() end
		-- 	FindClearSpaceForUnit(caster, point, false)

		-- 	return nil
		-- end

		local percentage = (time / jumpTime) * distance
		local height = ((4 * jumpHeight * distance * percentage) - (4 * jumpHeight * percentage * percentage)) / (distance * distance)

		local horizontalMovement = GetGroundPosition(caster:GetAbsOrigin(), caster) + forwardVec * distance

		caster:SetAbsOrigin(horizontalMovement + Vector(0, 0, height) )

		if time >= jumpTime then
			-- Re-activates the spell
			caster:SetModel("models/items/courier/faceless_rex/faceless_rex.vmdl")
			self:SetActivated(true)
			latchAbility:SetActivated(true)
			if modifier then modifier:Destroy() end
			FindClearSpaceForUnit(caster, point, false)

			if not caster:IsStunned() and not caster:IsDisarmed() then
				self:CreateAttackWave(caster:GetAbsOrigin())
			end

			return nil
		end
		return interval
	end)

	self:SpendAbilityCharge()
end

function warp_beast_temporal_jump:SpendAbilityCharge()
	if self:GetCooldownTimeRemaining() > 0 then
		local caster = self:GetCaster()
		local chargeModifier = caster:FindModifierByName("modifier_temporal_jump_charges")
		local charges = chargeModifier:GetStackCount()
		local maxCharges = self:GetSpecialValueFor("charges")

		if charges >= maxCharges then
			chargeModifier:SetStackCount(maxCharges)
			self:UseResources(false, false, true)
			local newDuration = self:GetCooldownTimeRemaining()
			chargeModifier:SetDuration(newDuration, true)
		end

		chargeModifier:DecrementStackCount()
		charges = charges - 1
		self:EndCooldown()

		if charges < 1 then
			self:StartCooldown(chargeModifier:GetRemainingTime())
		end
	end
end

function warp_beast_temporal_jump:CreateAttackWave(origin)
	local caster = self:GetCaster()
	local radius = self:GetSpecialValueFor("radius")
	local wave_speed = self:GetSpecialValueFor("wave_speed")

	-- Talent that increases the radius
	local talent1 = caster:FindAbilityByName("special_bonus_unique_warp_beast_jump_radius")
	if talent1 and talent1:GetLevel() > 0 then
		radius = radius + talent1:GetSpecialValueFor("value")
	end

	local hits = {}

	local currentRadius = 0
	local interval = 0.05
	local radiusGrowth = wave_speed * interval

	EmitSoundOnLocationWithCaster(origin, "Hero_FacelessVoid.TimeDilation.Cast.ti7", caster)

	-- Create wave particle
	-- CP1: Radius
	-- CP2: Wave speed
	local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_warp_beast/warp_beast_temporal_jump_land_wave.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(particle, 0, GetGroundPosition(caster:GetAbsOrigin(), caster))
	ParticleManager:SetParticleControl(particle, 1, Vector(radius, 0, 0))
	ParticleManager:SetParticleControl(particle, 2, Vector(wave_speed, 0, 0))

	Timers:CreateTimer(interval, function()
		currentRadius = currentRadius + radiusGrowth
		local units = FindUnitsInRadius(caster:GetTeamNumber(), origin, nil, currentRadius, DOTA_UNIT_TARGET_TEAM_ENEMY, bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)

		for _, unit in pairs(units) do
			if unit and not unit:IsNull() and not hits[unit:entindex()] then
				caster:PerformAttack(unit, true, true, true, true, false, false, true)
				table.insert(hits, unit:entindex(), unit)
			end
		end

		if currentRadius >= radius then
			return nil
		end

		return interval
	end)
end

---------------------------------------------------------------------------------------------------

modifier_temporal_jump = class({})

function modifier_temporal_jump:CheckState()
	return {
		[MODIFIER_STATE_ROOTED] = true,
		[MODIFIER_STATE_DISARMED] = true,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
		[MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true
	}
end

function modifier_temporal_jump:GetEffectName()
	return "particles/units/heroes/hero_warp_beast/warp_beast_temporal_jump.vpcf"
end

---------------------------------------------------------------------------------------------------

modifier_temporal_jump_charges = class({})

function modifier_temporal_jump_charges:OnCreated()
	if not IsServer() then return end

	self.interval = 1

	local charges = self:GetAbility():GetSpecialValueFor("charges")
	self:SetStackCount(charges)
	self:SetDuration(0.1, true)

	self:StartIntervalThink(self.interval)
end

function modifier_temporal_jump_charges:IsPermanent()
	return true
end

function modifier_temporal_jump_charges:DestroyOnExpire()
	return false
end

function modifier_temporal_jump_charges:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ABILITY_EXECUTED,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end

if IsServer() then
	function modifier_temporal_jump_charges:OnAbilityExecuted(event)
		local caster = self:GetCaster()
		if event.unit == caster and caster:IsRealHero() then
			local used_ability = event.ability
			local used_ability_name = used_ability:GetAbilityName()

			if used_ability_name == "item_refresher" or used_ability_name == "item_refresher_shard" then
				local charges = self:GetAbility():GetSpecialValueFor("charges")
				self:SetStackCount(charges)
				self:SetDuration(-1, true)
			end
		end
	end

	function modifier_temporal_jump_charges:OnIntervalThink()
		local maxCharges = self:GetAbility():GetSpecialValueFor("charges")
		local duration = self:GetRemainingTime()
		local interval = self.interval

		if duration < interval and self:GetStackCount() < maxCharges then
			Timers:CreateTimer(duration, function()

				local ability = self:GetAbility()
				local newCharges = self:GetStackCount() + 1
				self:SetStackCount(newCharges)
				if newCharges < maxCharges then
					ability:UseResources(false, false, true)
					local newDuration = ability:GetCooldownTimeRemaining()
					ability:EndCooldown()
					self:SetDuration(newDuration, true)
				end

				return
			end)
		end
	end

	function modifier_temporal_jump_charges:OnAttackLanded(event)
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

		if parent:IsIllusion() then
			return
		end

		-- Check if attacked entity exists
		if not target or target:IsNull() then
			return
		end

		-- Check if attacked entity is an item, rune or something weird
		if target.GetUnitName == nil then
			return
		end

		-- Don't affect non-hero units
		if not target:IsHero() then
			return
		end

		-- Proc only on instant attacks
		if not event.no_attack_cooldown then
			return
		end

		local hero_damage = ability:GetSpecialValueFor("bonus_hero_damage")
		-- Talent that increases hero damage
		local talent2 = parent:FindAbilityByName("special_bonus_unique_warp_beast_jump_hero_damage")
		if talent2 and talent2:GetLevel() > 0 then
			hero_damage = hero_damage + talent2:GetSpecialValueFor("value")
		end

		local damage_table = {}
		damage_table.attacker = parent
		damage_table.damage_type = ability:GetAbilityDamageType()
		damage_table.damage_flags = DOTA_DAMAGE_FLAG_BYPASSES_BLOCK
		damage_table.ability = ability
		damage_table.damage = hero_damage
		damage_table.victim = target

		ApplyDamage(damage_table)
	end
end
