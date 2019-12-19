if death_knight_death_pact == nil then
	death_knight_death_pact = class({})
end

LinkLuaModifier("modifier_custom_death_pact", "heroes/death_knight/death_pact.lua", LUA_MODIFIER_MOTION_NONE)

function death_knight_death_pact:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local duration = self:GetSpecialValueFor("duration")

	-- get the target's current health
	local target_health = target:GetHealth()

	-- kill the target
	target:Kill(self, caster)

	-- apply the new modifier which actually provides the stats
	-- then set its stack count to the amount of health the target had
	caster:AddNewModifier(caster, self, "modifier_custom_death_pact", { duration = duration, stacks = target_health })

	-- Sounds
	caster:EmitSound("Hero_Clinkz.DeathPact.Cast")
	target:EmitSound("Hero_Clinkz.DeathPact")

	-- Particle
	local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_clinkz/clinkz_death_pact.vpcf", PATTACH_ABSORIGIN, target)
	ParticleManager:SetParticleControlEnt(particle, 1, caster, PATTACH_ABSORIGIN, "", caster:GetAbsOrigin(), true)
	ParticleManager:ReleaseParticleIndex(particle)
end

--------------------------------------------------------------------------------

if modifier_custom_death_pact == nil then
	modifier_custom_death_pact = class({})
end

function modifier_custom_death_pact:IsHidden()
	return false
end

function modifier_custom_death_pact:IsDebuff()
	return false
end

function modifier_custom_death_pact:IsPurgable()
	return false
end

function modifier_custom_death_pact:OnCreated(event)
	local parent = self:GetParent()
	local ability = self:GetAbility()

	-- this has to be done server-side because valve
	if IsServer() then
		-- get the parent's current health before applying anything
		self.parentHealth = parent:GetHealth()

		-- set the modifier's stack count to the target's health, so that we
		-- have access to it on the client
		self:SetStackCount(event.stacks)
	end

	local healthPct = ability:GetSpecialValueFor( "health_gain_pct" ) * 0.01
	local damagePct = ability:GetSpecialValueFor( "damage_gain_pct" ) * 0.01

	-- retrieve the stack count
	local targetHealth = self:GetStackCount()

	-- make sure the resulting buffs don't exceed the caps
	self.health = targetHealth * healthPct
	self.damage = targetHealth * damagePct

	if healthMax then
		self.health = math.min(healthMax, self.health)
	end

	if damageMax then
		self.damage = math.min(damageMax, self.health)
	end

	if IsServer() then
		-- apply the new health and such
		parent:CalculateStatBonus()

		-- add the added health
		parent:SetHealth(self.parentHealth + self.health)
	end
end

function modifier_custom_death_pact:OnRefresh(event)
	local parent = self:GetParent()
	local ability = self:GetAbility()

	-- this has to be done server-side because valve
	if IsServer() then
		-- get the parent's current health before applying anything
		self.parentHealth = parent:GetHealth()

		-- set the modifier's stack count to the target's health, so that we
		-- have access to it on the client
		self:SetStackCount(event.stacks)
	end

	local healthPct = ability:GetSpecialValueFor( "health_gain_pct" ) * 0.01
	local damagePct = ability:GetSpecialValueFor( "damage_gain_pct" ) * 0.01

	-- retrieve the stack count
	local targetHealth = self:GetStackCount()

	-- make sure the resulting buffs don't exceed the caps
	self.health = targetHealth * healthPct
	self.damage = targetHealth * damagePct

	if healthMax then
		self.health = math.min(healthMax, self.health)
	end

	if damageMax then
		self.damage = math.min(damageMax, self.health)
	end

	if IsServer() then
		-- apply the new health and such
		parent:CalculateStatBonus()

		-- add the added health
		parent:SetHealth(self.parentHealth + self.health)
	end
end

function modifier_custom_death_pact:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_BASEATTACK_BONUSDAMAGE,
		MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
	}

	return funcs
end

function modifier_custom_death_pact:GetModifierBaseAttack_BonusDamage()
	return self.damage
end

function modifier_custom_death_pact:GetModifierExtraHealthBonus()
	return self.health
end

function modifier_custom_death_pact:GetEffectName()
	return "particles/units/heroes/hero_clinkz/clinkz_death_pact_buff.vpcf"
end

function modifier_custom_death_pact:GetEffectAttachType()
	return PATTACH_POINT_FOLLOW
end
