oracle_undeniable_torture = class({})

LinkLuaModifier( "modifier_oracle_undeniable_torture", "heroes/oracle/oracle_undeniable_torture", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_oracle_undeniable_torture_debuff", "heroes/oracle/oracle_undeniable_torture", LUA_MODIFIER_MOTION_NONE )

---------------------------------------------------------------------------------------------------

function oracle_undeniable_torture:GetIntrinsicModifierName()
	return "modifier_oracle_undeniable_torture"
end

function oracle_undeniable_torture:GetAOERadius()
	return self:GetSpecialValueFor( "radius" )
end

function oracle_undeniable_torture:OnSpellStart()
	local caster = self:GetCaster()
	local team = caster:GetTeamNumber()
	local point = self:GetCursorPosition()
	local radius = self:GetSpecialValueFor("radius")
	local target_team = DOTA_UNIT_TARGET_TEAM_ENEMY
	local target_type = bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
	local target_flags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES

	local enemies = FindUnitsInRadius(team, point, nil, radius, target_team, target_type, target_flags, FIND_ANY_ORDER, false)

	self.modifiers = {}
	
	local max_duration = self:GetSpecialValueFor("max_channel")
	for _, enemy in pairs(enemies) do
		if enemy and not enemy:IsNull() then
			local modifier = enemy:AddNewModifier(caster, self, "modifier_oracle_undeniable_torture_debuff", {duration = max_duration})
			table.insert(self.modifiers, modifier)
		end
	end

	local particle_cast = "particles/units/heroes/hero_bloodseeker/bloodseeker_bloodritual_explode.vpcf"
	local sound_cast = "hero_bloodseeker.bloodRite.silence"

	-- Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, caster )
	ParticleManager:SetParticleControl( effect_cast, 0, point )
	ParticleManager:SetParticleControl( effect_cast, 1, Vector(radius, radius, 1) )
	ParticleManager:ReleaseParticleIndex( effect_cast )

	-- Create Sound
	EmitSoundOnLocationWithCaster( point, sound_cast, caster )
end

function oracle_undeniable_torture:GetChannelTime()
	return self:GetSpecialValueFor("max_channel")
end

function oracle_undeniable_torture:OnChannelFinish( bInterrupted )
	for _, modifier in pairs(self.modifiers) do
		if modifier and not modifier:IsNull() then
			modifier:Destroy()
		end
	end
end

---------------------------------------------------------------------------------------------------

modifier_oracle_undeniable_torture = class({})

function modifier_oracle_undeniable_torture:IsHidden()
	return true
end

function modifier_oracle_undeniable_torture:IsDebuff()
	return false
end

function modifier_oracle_undeniable_torture:IsPurgable()
	return false
end

function modifier_oracle_undeniable_torture:OnCreated()
	self.lifesteal = self:GetAbility():GetSpecialValueFor( "lifesteal" )
end

function modifier_oracle_undeniable_torture:OnRefresh()
	self.lifesteal = self:GetAbility():GetSpecialValueFor( "lifesteal" )
end

function modifier_oracle_undeniable_torture:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_AVOID_DAMAGE,
	}
end

if IsServer() then
	function modifier_oracle_undeniable_torture:GetModifierAvoidDamage(event)
		local parent = self:GetParent()
		local ability = self:GetAbility()
		local attacker = event.attacker

		-- Don't trigger for self damage or for damage from enemies
		if attacker == self:GetParent() or attacker:GetTeamNumber() ~= parent:GetTeamNumber() then
			return 0
		end

		-- Check if attacker or parent is dead
		if not parent:IsAlive() or not attacker:IsAlive() then
			return 0
		end

		local inflictor = event.inflictor
		local damage = event.original_damage
		local damage_flags = event.damage_flags
		
		-- Check if damage is 0 or negative
		if damage <= 0 then
			return 0
		end
		
		-- Don't continue if the damage has 'no spell lifesteal' flag
		if bit.band(damage_flags, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL) > 0 then
			return 0
		end

		-- Heal allies
		local amount = math.min(parent:GetHealth(), damage)
		--attacker:Heal(amount, ability)
		if inflictor or event.damage_category == DOTA_DAMAGE_CATEGORY_SPELL then
			-- Spell Lifesteal
			attacker:HealWithParams(amount, ability, false, true, attacker, true)

			-- Particle
			local particle = ParticleManager:CreateParticle("particles/items3_fx/octarine_core_lifesteal.vpcf", PATTACH_ABSORIGIN_FOLLOW, attacker)
			ParticleManager:SetParticleControl(particle, 0, attacker:GetAbsOrigin())
			ParticleManager:ReleaseParticleIndex(particle)
		else
			-- Normal Lifesteal
			attacker:HealWithParams(amount, ability, true, true, attacker, false)

			-- Particle
			local particle = ParticleManager:CreateParticle("particles/generic_gameplay/generic_lifesteal.vpcf", PATTACH_ABSORIGIN_FOLLOW, attacker)
			ParticleManager:SetParticleControl(particle, 0, attacker:GetAbsOrigin())
			ParticleManager:ReleaseParticleIndex(particle)
		end

		-- Deal damage with 'non-lethal' flag (LOGIC-WISE this should be after the blocking damage instance, but programming doesn't allow code after 'return')
		local damage_table = {
			victim = parent,
			attacker = attacker,
			damage = damage,
			damage_type = event.damage_type,
			ability = inflictor,
			damage_flags = bit.bor(DOTA_DAMAGE_FLAG_NON_LETHAL, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL, DOTA_DAMAGE_FLAG_REFLECTION),
		}

		ApplyDamage(damage_table)

		-- Block the previous damage instance
		return 1
	end
end

function modifier_oracle_undeniable_torture:CheckState()
	return {
		[MODIFIER_STATE_SPECIALLY_DENIABLE] = true,
	}
end

---------------------------------------------------------------------------------------------------

modifier_oracle_undeniable_torture_debuff = class({})

function modifier_oracle_undeniable_torture_debuff:IsHidden() -- needs tooltip
	return false
end

function modifier_oracle_undeniable_torture_debuff:IsDebuff()
	return true
end

function modifier_oracle_undeniable_torture_debuff:IsPurgable()
	return false
end

function modifier_oracle_undeniable_torture_debuff:OnCreated()
	self:OnRefresh()

	--self.lifeshare_exception = "sandra_sacrifice"
end

function modifier_oracle_undeniable_torture_debuff:OnRefresh()
	self.lifeshare = self:GetAbility():GetSpecialValueFor( "lifeshare" )
end

function modifier_oracle_undeniable_torture_debuff:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_TAKEDAMAGE,
	}
end

if IsServer() then
	function modifier_oracle_undeniable_torture_debuff:OnTakeDamage(event)
		local parent = self:GetParent()
		local caster = self:GetCaster()
		local attacker = event.attacker
		local damaged_unit = event.unit

		-- Check if attacker exists
		if not attacker or attacker:IsNull() then
			return
		end

		-- Check if damaged entity exists
		if not damaged_unit or damaged_unit:IsNull() then
			return
		end
		
		-- Check if damage entity is the caster
		if damaged_unit ~= caster then
			return
		end

		-- Ignore damage that has the no-reflect flag
		if bit.band(event.damage_flags, DOTA_DAMAGE_FLAG_REFLECTION) > 0 then
			-- if not event.inflictor or event.inflictor:GetAbilityName() ~= self.lifeshare_exception then
				-- return
			-- end
			return
		end

		-- Set source of shared/reflected damage (caster is default)
		local source = caster
		if attacker:GetTeamNumber() == caster:GetTeamNumber() then
			source = attacker
		end

		-- Particle
		local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_warlock/warlock_fatal_bonds_hit.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, caster)
		ParticleManager:SetParticleControlEnt(particle, 0, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
		ParticleManager:SetParticleControlEnt(particle, 1, source, PATTACH_POINT_FOLLOW, "attach_hitloc", source:GetAbsOrigin(), true)
		ParticleManager:ReleaseParticleIndex(particle)

		-- Sound
		parent:EmitSound("Hero_Warlock.FatalBondsDamage")

		-- Share/reflect percent of the damage to the parent
		local damage = event.original_damage * self.lifeshare / 100
		local damage_table = {
			victim = parent,
			attacker = source,
			damage = damage,
			damage_type = event.damage_type,
			ability = self:GetAbility(), --event.inflictor,
			damage_flags = bit.bor(event.damage_flags, DOTA_DAMAGE_FLAG_REFLECTION),
		}

		ApplyDamage(damage_table)
	end
end

function modifier_oracle_undeniable_torture_debuff:GetEffectName()
	return "particles/units/heroes/hero_warlock/warlock_fatal_bonds_icon.vpcf"
end

function modifier_oracle_undeniable_torture_debuff:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end
