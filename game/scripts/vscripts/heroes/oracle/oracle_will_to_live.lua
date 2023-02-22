oracle_will_to_live = class({})

LinkLuaModifier("modifier_oracle_will_to_live", "heroes/oracle/oracle_will_to_live.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_oracle_will_to_live_delay", "heroes/oracle/oracle_will_to_live.lua", LUA_MODIFIER_MOTION_NONE)

function oracle_will_to_live:CastFilterResultTarget(target)
	local default_result = self.BaseClass.CastFilterResultTarget(self, target)

	if target:IsCustomWardTypeUnit() then
		return UF_FAIL_CUSTOM
	end

	return default_result
end

function oracle_will_to_live:GetCustomCastErrorTarget(target)
	if target:IsCustomWardTypeUnit() then
		return "#dota_hud_error_cant_cast_on_other"
	end
	return ""
end

function oracle_will_to_live:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local duration = self:GetSpecialValueFor("duration")

	-- Buff
	target:AddNewModifier(caster, self, "modifier_oracle_will_to_live", {duration = duration})

	-- Sound
	target:EmitSound("Hero_Dazzle.Shallow_Grave")
end

---------------------------------------------------------------------------------------------------

modifier_oracle_will_to_live = class({})

function modifier_oracle_will_to_live:IsHidden()
	return false
end

function modifier_oracle_will_to_live:IsDebuff()
	return false
end

function modifier_oracle_will_to_live:IsPurgable()
	return false
end

function modifier_oracle_will_to_live:OnCreated()
	local ability = self:GetAbility()
	if ability and not ability:IsNull() then
		self.delay = self:GetAbility():GetSpecialValueFor("damage_delay")
		self.hp_regen_amp = ability:GetSpecialValueFor("heal_amp_pct")
		self.lifesteal_amp = ability:GetSpecialValueFor("heal_amp_pct")
		self.heal_amp = ability:GetSpecialValueFor("heal_amp_pct")
		self.spell_lifesteal_amp = ability:GetSpecialValueFor("heal_amp_pct")
	end
end

modifier_oracle_will_to_live.OnRefresh = modifier_oracle_will_to_live.OnCreated

function modifier_oracle_will_to_live:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_AVOID_DAMAGE,
		MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
		MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET,
		MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE,
		MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE,
	}
end

if IsServer() then
	function modifier_oracle_will_to_live:GetModifierAvoidDamage(event)
		local parent = self:GetParent()
		local ability = self:GetAbility()
		local attacker = event.attacker

		-- Check if attacker exists
		if not attacker or attacker:IsNull() then
			return 0
		end

		-- Check if parent is dead
		if not parent:IsAlive() then
			return 0
		end

		local inflictor = event.inflictor
		local damage = event.original_damage
		local damage_type = event.damage_type
		local damage_flags = event.damage_flags

		-- Check if damage is 0 or negative
		if damage <= 0 then
			return 0
		end

		-- Ignore damage that has the 'hp-removal' flag
		if bit.band(damage_flags, DOTA_DAMAGE_FLAG_HPLOSS) > 0 then
			return 0
		end

		if inflictor and ability then
			if inflictor == ability or inflictor:GetAbilityName() == ability:GetAbilityName() then
				return 0
			end
		end

		local kvs = {}
		kvs.damage = damage
		kvs.source = attacker:GetEntityIndex()
		if ability then
			kvs.inflictor = ability:GetEntityIndex()
		else
			return 0
		end
		kvs.type = damage_type
		kvs.flags = damage_flags -- OnTakeDamage event ignores hp removal flag
		kvs.delay = self.delay
		local max_dmg_instance = damage * self.delay / 100
		local max_duration = damage / max_dmg_instance + 1
		kvs.duration = max_duration

		-- Delayed damage modifier
		parent:AddNewModifier(parent, ability, "modifier_oracle_will_to_live_delay", kvs)

		-- Particle
		local particle_cast = "particles/items_fx/backdoor_protection_tube.vpcf"
		local direction = (parent:GetAbsOrigin()-attacker:GetAbsOrigin()):Normalized()
		local size = 150

		local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, parent )
		ParticleManager:SetParticleControl( effect_cast, 1, Vector( size, 0, 0 ) )
		ParticleManager:SetParticleControlForward( effect_cast, 2, direction )
		ParticleManager:ReleaseParticleIndex( effect_cast )

		-- Block the damage
		return 1
	end
end

function modifier_oracle_will_to_live:GetModifierHPRegenAmplify_Percentage()
  return self.hp_regen_amp or self:GetAbility():GetSpecialValueFor("heal_amp_pct")
end

function modifier_oracle_will_to_live:GetModifierHealAmplify_PercentageTarget()
  return self.heal_amp or self:GetAbility():GetSpecialValueFor("heal_amp_pct")
end

function modifier_oracle_will_to_live:GetModifierLifestealRegenAmplify_Percentage()
  return self.lifesteal_amp or self:GetAbility():GetSpecialValueFor("heal_amp_pct")
end

function modifier_oracle_will_to_live:GetModifierSpellLifestealRegenAmplify_Percentage()
  return self.spell_lifesteal_amp or self:GetAbility():GetSpecialValueFor("heal_amp_pct")
end

function modifier_oracle_will_to_live:GetEffectName()
	return "particles/units/heroes/hero_dazzle/dazzle_shallow_grave.vpcf"
end

function modifier_oracle_will_to_live:GetEffectNameAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

---------------------------------------------------------------------------------------------------

modifier_oracle_will_to_live_delay = class({})

function modifier_oracle_will_to_live_delay:IsHidden()
	return true
end

function modifier_oracle_will_to_live_delay:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_oracle_will_to_live_delay:IsPurgable()
	return false
end

function modifier_oracle_will_to_live_delay:OnCreated(kv)
	if IsServer() then
		local interval = 1

		self.attacker = EntIndexToHScript(kv.source)
		self.inflictor = EntIndexToHScript(kv.inflictor)
		self.type = kv.type
		self.flags = kv.flags
		self.damage_left = kv.damage
		self.damage_tick = kv.damage * kv.delay / 100

		-- Start interval
		self:StartIntervalThink(interval)
	end
end

if IsServer() then
	function modifier_oracle_will_to_live_delay:OnIntervalThink()
		local parent = self:GetParent()
		local damage = math.min(self.damage_tick, self.damage_left)

		-- Check if parent exists
		if not parent or parent:IsNull() or not parent:IsAlive() then
			self:StartIntervalThink(-1)
			self:Destroy()
			return
		end

		-- Check if attacker exists
		if not self.attacker or self.attacker:IsNull() then
			self:StartIntervalThink(-1)
			self:Destroy()
			return
		end

		-- Particles
		local particle_1 = ParticleManager:CreateParticle("particles/items2_fx/soul_ring_blood.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
		ParticleManager:ReleaseParticleIndex(particle_1)
		-- Check if damage is non-lethal
		if damage <= parent:GetHealth() or bit.band(self.flags, DOTA_DAMAGE_FLAG_NON_LETHAL) > 0 then
			local particle_2 = ParticleManager:CreateParticle("particles/units/heroes/hero_dazzle/dazzle_shallow_grave_glyph_flare.vpcf", PATTACH_CENTER_FOLLOW, parent)
			ParticleManager:ReleaseParticleIndex(particle_2)
		end

		-- Sound
		parent:EmitSound("DOTA_Item.Maim")

		-- Apply damage (the damage info is the same as original damage info except damage value and inflictor/ability)
		local damage_table = {
			victim = parent,
			attacker = self.attacker,
			damage = damage,
			damage_type = self.type,
			ability = self.inflictor,
			damage_flags = self.flags,
		}

		ApplyDamage(damage_table)

		-- Remaining damage
		self.damage_left = self.damage_left - self.damage_tick
		if self.damage_left <= 0 then
			self:Destroy()
		end
	end
end
