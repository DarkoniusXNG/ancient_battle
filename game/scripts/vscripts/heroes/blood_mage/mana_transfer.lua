blood_mage_mana_transfer = class({})

LinkLuaModifier("modifier_mana_transfer_enemy", "heroes/blood_mage/mana_transfer.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_mana_transfer_ally", "heroes/blood_mage/mana_transfer.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_transfer_mana_extra", "heroes/blood_mage/mana_transfer.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_mana_transfer_leash_debuff", "heroes/blood_mage/mana_transfer.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_mana_transfer_shard_bkb", "heroes/blood_mage/mana_transfer.lua", LUA_MODIFIER_MOTION_NONE)

function blood_mage_mana_transfer:CastFilterResultTarget(target)
	local caster = self:GetCaster()
	local default_result = self.BaseClass.CastFilterResultTarget(self, target)

	if target == caster or target:IsCustomWardTypeUnit() or target:GetMaxMana() < 1 then
		return UF_FAIL_CUSTOM
    elseif target:IsCourier() then
		return UF_FAIL_COURIER
	end

	return default_result
end

function blood_mage_mana_transfer:GetCustomCastErrorTarget(target)
	local caster = self:GetCaster()
	if target == caster then
		return "#dota_hud_error_cant_cast_on_self"
	end
	if target:IsCustomWardTypeUnit() then
		return "#dota_hud_error_cant_cast_on_other"
	end
	if target:GetMaxMana() < 1 then
		return "#dota_hud_error_only_cast_mana_units"
	end
	return ""
end

function blood_mage_mana_transfer:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	if not caster or not target then
		return
	end

	if not self.modifiers then
		self.modifiers = {}
	else
		-- Remove previous instances
		for _, mod in pairs(self.modifiers) do
			if mod and not mod:IsNull() then
				mod:Destroy()
			end
		end
		self.modifiers = {}
	end

	local duration = self:GetChannelTime()

	-- Talent that applies leash
	local talent = caster:FindAbilityByName("special_bonus_unique_blood_mage_3")
	local has_talent = talent and talent:GetLevel() > 0

	-- Check for shard
	if caster:HasShardCustom() then
		local shard_bkb = caster:AddNewModifier(caster, self, "modifier_mana_transfer_shard_bkb", {duration = duration})
		table.insert(self.modifiers, shard_bkb)
	end

	-- Checking if target is an enemy
	if target:GetTeamNumber() ~= caster:GetTeamNumber() then
		-- Check for spell block and spell immunity (latter because of lotus)
		if not target:TriggerSpellAbsorb(self) and not target:IsMagicImmune() then
			-- Enemy debuff
			local debuff = target:AddNewModifier(caster, self, "modifier_mana_transfer_enemy", {duration = duration})
			table.insert(self.modifiers, debuff)
			-- Sound
			caster:EmitSound("Hero_Lion.ManaDrain")
			-- Leash debuff
			if has_talent then
				local leash = target:AddNewModifier(caster, self, "modifier_mana_transfer_leash_debuff", {duration = duration})
				table.insert(self.modifiers, leash)
			end
		else
			caster:Interrupt()
		end
	else
		-- Ally buff
		local buff = target:AddNewModifier(caster, self, "modifier_mana_transfer_ally", {duration = duration})
		table.insert(self.modifiers, buff)
		-- Sound
		caster:EmitSound("Hero_Lion.ManaDrain")
	end
end

-- Called when modifiers are destroyed (unit dies or modifier is removed; modifier can be removed in many cases)
function blood_mage_mana_transfer:OnChannelFinish(bInterrupted)
	local caster = self:GetCaster()

	caster:StopSound("Hero_Lion.ManaDrain")

	if self.modifiers then
		-- Remove all modifiers
		for _, mod in pairs(self.modifiers) do
			if mod and not mod:IsNull() then
				mod:Destroy()
			end
		end
	end
end

function blood_mage_mana_transfer:ProcsMagicStick()
	return true
end

function blood_mage_mana_transfer:IsStealable()
	return true
end

---------------------------------------------------------------------------------------------------

modifier_mana_transfer_enemy = class({})

function modifier_mana_transfer_enemy:IsHidden()
	return true
end

function modifier_mana_transfer_enemy:IsDebuff()
	return true
end

function modifier_mana_transfer_enemy:IsPurgable()
	return false
end

function modifier_mana_transfer_enemy:RemoveOnDeath()
	return true
end

function modifier_mana_transfer_enemy:OnCreated()
	if not IsServer() then
		return
	end

	local parent = self:GetParent()
	local caster = self:GetCaster()
	local ability = self:GetAbility()

    -- Particle
	local particleName = "particles/units/heroes/hero_lion/lion_spell_mana_drain.vpcf"
	self.particle = ParticleManager:CreateParticle(particleName, PATTACH_POINT_FOLLOW, caster)
	ParticleManager:SetParticleControlEnt(self.particle, 0, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(self.particle, 1, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)

	-- Start transfering
	local interval = ability:GetSpecialValueFor("think_interval")
	self:OnIntervalThink()
	self:StartIntervalThink(interval)
end

function modifier_mana_transfer_enemy:OnIntervalThink()
	if not IsServer() then
		return
	end

	local target = self:GetParent()
	local caster = self:GetCaster()
	local ability = self:GetAbility()

	if not target or target:IsNull() or not target:IsAlive() or not caster or caster:IsNull() or not caster:IsAlive() or not ability or ability:IsNull() then
		self:StartIntervalThink(-1)
		self:Destroy()
		return
	end

	local mana_per_second = ability:GetSpecialValueFor("mana_per_second")
	local interval = ability:GetSpecialValueFor("think_interval")
	local mana_per_interval = mana_per_second * interval

	-- If its an illusion then kill it
	if target:IsIllusion() and not target:IsStrongIllusionCustom() then
		target:Kill(ability, caster)
		self:StartIntervalThink(-1)
		self:Destroy()
		return
	end

	-- Location variables
	local caster_location = caster:GetAbsOrigin()
	local target_location = target:GetAbsOrigin()

	-- Distance variables
	local distance = (target_location - caster_location):Length2D()
	local break_distance = ability:GetSpecialValueFor("break_distance") + caster:GetCastRangeBonus()
	local direction = (target_location - caster_location):Normalized()

	-- If one of these happens then stop the channel:
	-- 1) target goes out of range
	-- 2) target becomes spell immune
	-- 3) target becomes invulnerable
	-- 4) target lost all mana
	if distance >= break_distance or target:IsMagicImmune() or target:IsInvulnerable() or target:GetMana() < 1 then
		self:StartIntervalThink(-1)
		self:Destroy()
		return
	end

	-- Make sure that the caster always faces the target if he is channeling
	if caster:IsChanneling() then
		caster:SetForwardVector(direction)
	end

	-- Mana variables
	local target_mana = target:GetMana()
    local caster_mana = caster:GetMana()

	if caster:IsChanneling() then
		local mana_transfer
		if target_mana >= mana_per_interval then
			mana_transfer = mana_per_interval
		else
			mana_transfer = target_mana
		end

		target:ReduceMana(mana_transfer)

		-- Mana gained can go over the max mana
		if caster_mana + mana_transfer > caster:GetMaxMana() then
			local extra_mana_duration = ability:GetSpecialValueFor("extra_mana_duration")
			local modifier = caster:FindModifierByName("modifier_transfer_mana_extra")
			if modifier then
				modifier:SetDuration(extra_mana_duration, true)
				modifier:SetStackCount(modifier:GetStackCount() + mana_transfer)
			else
				modifier = caster:AddNewModifier(caster, ability, "modifier_transfer_mana_extra", {duration = extra_mana_duration})
				if modifier then
					modifier:SetStackCount(mana_transfer)
				end
			end
			caster:CalculateStatBonus(true)
		end

		caster:GiveMana(mana_transfer)

		-- Damage enemies if caster has shard
		if caster:HasShardCustom() then
			local damage_table = {}
			damage_table.attacker = caster
			damage_table.damage_type = DAMAGE_TYPE_MAGICAL
			damage_table.ability = ability
			damage_table.victim = target
			damage_table.damage = 2*mana_transfer

			ApplyDamage(damage_table)
		end
	end
end

function modifier_mana_transfer_enemy:OnDestroy()
	if not IsServer() then
		return
	end

	if self.particle then
		ParticleManager:DestroyParticle(self.particle, false)
		ParticleManager:ReleaseParticleIndex(self.particle)
	end

	local caster = self:GetCaster()
	local ability = self:GetAbility()

	if caster and not caster:IsNull() and caster:IsAlive() then
		caster:Interrupt()
	elseif ability and not ability:IsNull() then
		ability:OnChannelFinish(true)
	end
end

---------------------------------------------------------------------------------------------------

modifier_mana_transfer_ally = class({})

function modifier_mana_transfer_ally:IsHidden()
	return true
end

function modifier_mana_transfer_ally:IsDebuff()
	return false
end

function modifier_mana_transfer_ally:IsPurgable()
	return false
end

function modifier_mana_transfer_ally:RemoveOnDeath()
	return true
end

function modifier_mana_transfer_ally:OnCreated()
	if not IsServer() then
		return
	end

	local parent = self:GetParent()
	local caster = self:GetCaster()
	local ability = self:GetAbility()

    -- Particle
	local particleName = "particles/units/heroes/hero_lion/lion_spell_mana_drain.vpcf"
	self.particle = ParticleManager:CreateParticle(particleName, PATTACH_POINT_FOLLOW, caster)
	ParticleManager:SetParticleControlEnt(self.particle, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(self.particle, 1, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)

	-- Start transfering
	local interval = ability:GetSpecialValueFor("think_interval")
	self:OnIntervalThink()
	self:StartIntervalThink(interval)
end

function modifier_mana_transfer_ally:OnIntervalThink()
	if not IsServer() then
		return
	end

	local target = self:GetParent()
	local caster = self:GetCaster()
	local ability = self:GetAbility()

	if not target or target:IsNull() or not target:IsAlive() or not caster or caster:IsNull() or not caster:IsAlive() or not ability or ability:IsNull() then
		self:StartIntervalThink(-1)
		self:Destroy()
		return
	end

	local mana_per_second = ability:GetSpecialValueFor("mana_per_second")
	local interval = ability:GetSpecialValueFor("think_interval")
	local mana_per_interval = mana_per_second * interval

	-- Location variables
	local caster_location = caster:GetAbsOrigin()
	local target_location = target:GetAbsOrigin()

	-- Distance variables
	local distance = (target_location - caster_location):Length2D()
	local break_distance = ability:GetSpecialValueFor("break_distance") + caster:GetCastRangeBonus()
	local direction = (target_location - caster_location):Normalized()

	-- If one of these happens then stop the channel:
	-- 1) target goes out of range
	-- 2) caster lost all mana
	if distance >= break_distance or caster:GetMana() < 1 then
		self:StartIntervalThink(-1)
		self:Destroy()
		return
	end

	-- Make sure that the caster always faces the target if he is channeling
	if caster:IsChanneling() then
		caster:SetForwardVector(direction)
	end

	local target_mana = target:GetMana()
    local caster_mana = caster:GetMana()

	if caster:IsChanneling() then
		local mana_transfer
		if caster_mana >= mana_per_interval then
			mana_transfer = mana_per_interval
		else
			mana_transfer = caster_mana
		end

		caster:ReduceMana(mana_transfer)

		-- Mana given can go over the max mana
		if target_mana + mana_transfer > target:GetMaxMana() then
			local extra_mana_duration = ability:GetSpecialValueFor("extra_mana_duration")
			local modifier = target:FindModifierByName("modifier_transfer_mana_extra")
			if modifier then
				modifier:SetDuration(extra_mana_duration, true)
				modifier:SetStackCount(modifier:GetStackCount() + mana_transfer)
			else
				modifier = target:AddNewModifier(caster, ability, "modifier_transfer_mana_extra", {duration = extra_mana_duration})
				if modifier then
					modifier:SetStackCount(mana_transfer)
				end
			end
			if target:IsRealHero() then
				target:CalculateStatBonus(true)
			else
				target:CalculateGenericBonuses()
			end
		end

		target:GiveMana(mana_transfer)

		-- Heal allies if caster has shard
		if caster:HasShardCustom() then
			target:Heal(mana_transfer, ability)
		end
	end
end

function modifier_mana_transfer_ally:OnDestroy()
	if not IsServer() then
		return
	end

	if self.particle then
		ParticleManager:DestroyParticle(self.particle, false)
		ParticleManager:ReleaseParticleIndex(self.particle)
	end

	local caster = self:GetCaster()
	local ability = self:GetAbility()

	if caster and not caster:IsNull() and caster:IsAlive() then
		caster:Interrupt()
	elseif ability and not ability:IsNull() then
		ability:OnChannelFinish(true)
	end
end

---------------------------------------------------------------------------------------------------

modifier_mana_transfer_leash_debuff = class({})

function modifier_mana_transfer_leash_debuff:IsHidden()
	return true
end

function modifier_mana_transfer_leash_debuff:IsDebuff()
	return true
end

function modifier_mana_transfer_leash_debuff:IsPurgable()
	return false
end

function modifier_mana_transfer_leash_debuff:RemoveOnDeath()
	return true
end

function modifier_mana_transfer_leash_debuff:CheckState()
	return {
		[MODIFIER_STATE_TETHERED] = true,
	}
end

---------------------------------------------------------------------------------------------------

modifier_transfer_mana_extra = class({})

function modifier_transfer_mana_extra:IsHidden()
  return true
end

function modifier_transfer_mana_extra:IsDebuff()
  return false
end

function modifier_transfer_mana_extra:IsPurgable()
  return false
end

function modifier_transfer_mana_extra:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_EXTRA_MANA_BONUS,
    MODIFIER_EVENT_ON_SPENT_MANA,
  }
end

function modifier_transfer_mana_extra:GetModifierExtraManaBonus()
  return self:GetStackCount()
end

function modifier_transfer_mana_extra:OnSpentMana(event)
  if IsServer() then
    if event.unit == self:GetParent() then
      local amount = event.cost
      if amount > self:GetStackCount() then
        self:Destroy()
      else
        self:SetStackCount(self:GetStackCount() - amount)
      end
    end
  end
end

---------------------------------------------------------------------------------------------------

modifier_mana_transfer_shard_bkb = class({})

function modifier_mana_transfer_shard_bkb:IsHidden()
	return false
end

function modifier_mana_transfer_shard_bkb:IsDebuff()
	return false
end

function modifier_mana_transfer_shard_bkb:IsPurgable()
	return false
end

function modifier_mana_transfer_shard_bkb:RemoveOnDeath()
	return true
end

function modifier_mana_transfer_shard_bkb:OnCreated()
  -- Basic dispel
  local RemovePositiveBuffs = false
  local RemoveDebuffs = true
  local BuffsCreatedThisFrameOnly = false
  local RemoveStuns = false
  local RemoveExceptions = false
  self:GetParent():Purge(RemovePositiveBuffs, RemoveDebuffs, BuffsCreatedThisFrameOnly, RemoveStuns, RemoveExceptions)
end

function modifier_mana_transfer_shard_bkb:CheckState()
  return {
    [MODIFIER_STATE_MAGIC_IMMUNE] = true,
  }
end

function modifier_mana_transfer_shard_bkb:GetEffectName()
  return "particles/items_fx/black_king_bar_avatar.vpcf"
end

function modifier_mana_transfer_shard_bkb:GetStatusEffectName()
  return "particles/status_fx/status_effect_avatar.vpcf"
end
