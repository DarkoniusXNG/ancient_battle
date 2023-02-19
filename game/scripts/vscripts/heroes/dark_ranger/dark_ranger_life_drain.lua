dark_ranger_life_drain = class({})

LinkLuaModifier("modifier_dark_ranger_life_drain", "heroes/dark_ranger/dark_ranger_life_drain.lua", LUA_MODIFIER_MOTION_NONE)

function dark_ranger_life_drain:CastFilterResultTarget(target)
	local caster = self:GetCaster()
	local default_result = self.BaseClass.CastFilterResultTarget(self, target)

	if target:IsCustomWardTypeUnit() then
		return UF_FAIL_CUSTOM
	end

	if default_result == UF_FAIL_MAGIC_IMMUNE_ENEMY then
		-- Talent that allows piercing spell immunity
		local talent = caster:FindAbilityByName("special_bonus_unique_dark_ranger_5")
		if talent and talent:GetLevel() > 0 then
			return UF_SUCCESS
		end

		return UF_FAIL_MAGIC_IMMUNE_ENEMY
	end

	return default_result
end

function dark_ranger_life_drain:GetCustomCastErrorTarget(target)
	if target:IsCustomWardTypeUnit() then
		return "#dota_hud_error_cant_cast_on_other"
	end
	return ""
end

function dark_ranger_life_drain:OnSpellStart()
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

	-- Check for spell block
	if target:TriggerSpellAbsorb(self) then
		caster:Interrupt()
		return
	end

	-- Talent that allows piercing spell immunity
	local talent = caster:FindAbilityByName("special_bonus_unique_dark_ranger_5")
	local has_talent = talent and talent:GetLevel() > 0

	-- Check for spell immunity (because of lotus); pierces spell immunity with talent
	if target:IsMagicImmune() and not has_talent then
		caster:Interrupt()
		return
	end

	-- Sound on caster
	caster:EmitSound("Hero_Pugna.LifeDrain.Cast")

	local duration = self:GetChannelTime()

	-- Enemy debuff
	local debuff = target:AddNewModifier(caster, self, "modifier_dark_ranger_life_drain", {duration = duration})
	table.insert(self.modifiers, debuff)

	-- Check for shard
	--if caster:HasShardCustom() then
		-- Apply Dark Arrow debuff - TODO
	--end
end

-- Called when modifiers are destroyed (unit dies or modifier is removed; modifier can be removed in many cases)
function dark_ranger_life_drain:OnChannelFinish(bInterrupted)
	if self.modifiers then
		-- Remove all modifiers
		for _, mod in pairs(self.modifiers) do
			if mod and not mod:IsNull() then
				mod:Destroy()
			end
		end
	end
end

function dark_ranger_life_drain:ProcsMagicStick()
	return true
end

---------------------------------------------------------------------------------------------------

modifier_dark_ranger_life_drain = class({})

function modifier_dark_ranger_life_drain:IsHidden() -- needs tooltip
	return false
end

function modifier_dark_ranger_life_drain:IsDebuff()
	return true
end

function modifier_dark_ranger_life_drain:IsPurgable() -- dispellable
	return true
end

function modifier_dark_ranger_life_drain:RemoveOnDeath()
	return true
end

function modifier_dark_ranger_life_drain:OnCreated()
	if not IsServer() then
		return
	end

	local parent = self:GetParent()
	local caster = self:GetCaster()
	local ability = self:GetAbility()

    -- Particle
	local particleName = "particles/units/heroes/hero_pugna/pugna_life_drain.vpcf"
	self.particle = ParticleManager:CreateParticle(particleName, PATTACH_POINT_FOLLOW, caster) --PATTACH_ABSORIGIN_FOLLOW or PATTACH_ABSORIGIN
	ParticleManager:SetParticleControlEnt(self.particle, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(self.particle, 1, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
	--ParticleManager:SetParticleControlEnt(self.particle, 1, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
	--ParticleManager:SetParticleControl(self.particle, 10, Vector(0,0,0))
	--ParticleManager:SetParticleControl(self.particle, 11, Vector(0,0,0))

	-- Sound
	parent:EmitSound("Hero_Pugna.LifeDrain.Target")

	-- Start transfering
	local interval = ability:GetSpecialValueFor("think_interval")
	self:OnIntervalThink()
	self:StartIntervalThink(interval)
end

function modifier_dark_ranger_life_drain:OnIntervalThink()
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

	local dmg_per_second = ability:GetSpecialValueFor("health_drain")
	local interval = ability:GetSpecialValueFor("think_interval")

	-- Check for shard
	if caster:HasShardCustom() then
		dmg_per_second = ability:GetSpecialValueFor("shard_health_drain")
	end

	local dmg_per_interval = dmg_per_second * interval

	-- How much caster heals himself
	local heal_per_interval = dmg_per_interval

	-- Talent that changes damage type and allows piercing spell immunity
	local talent = caster:FindAbilityByName("special_bonus_unique_dark_ranger_5")
	local has_talent = talent and talent:GetLevel() > 0

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
	-- 2) target becomes spell immune (no talent)
	-- 3) target becomes invulnerable
	if distance >= break_distance or (target:IsMagicImmune() and not has_talent) or target:IsInvulnerable() then
		self:StartIntervalThink(-1)
		self:Destroy()
		return
	end

	if caster:IsChanneling() then
		-- Make sure that the caster always faces the target if he is channeling
		caster:SetForwardVector(direction)

		local damage_table = {}
		damage_table.attacker = caster
		damage_table.victim = target
		damage_table.ability = ability
		damage_table.damage = dmg_per_interval
		damage_table.damage_type = DAMAGE_TYPE_MAGICAL
		if has_talent then
			damage_table.damage_type = DAMAGE_TYPE_PURE
		end

		--if caster:GetHealthDeficit() > 0 then
		-- Damage
		ApplyDamage(damage_table)

		-- Heal
		caster:Heal(heal_per_interval, ability)
		--end
	end
end

function modifier_dark_ranger_life_drain:OnDestroy()
	if not IsServer() then
		return
	end

	if self.particle then
		ParticleManager:DestroyParticle(self.particle, false)
		ParticleManager:ReleaseParticleIndex(self.particle)
	end

	local parent = self:GetParent()
	if parent and not parent:IsNull() then
		parent:StopSound("Hero_Pugna.LifeDrain.Target")
	end

	local caster = self:GetCaster()
	local ability = self:GetAbility()

	if caster and not caster:IsNull() and caster:IsAlive() then
		caster:Interrupt()
	elseif ability and not ability:IsNull() then
		ability:OnChannelFinish(true)
	end
end
