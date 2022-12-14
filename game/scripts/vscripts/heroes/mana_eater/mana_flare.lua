if mana_eater_mana_flare == nil then
	mana_eater_mana_flare = class({})
end

LinkLuaModifier("modifier_mana_eater_mana_flare_buff_aura", "heroes/mana_eater/mana_flare.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_mana_eater_mana_flare_aura_effect", "heroes/mana_eater/mana_flare.lua", LUA_MODIFIER_MOTION_NONE)

function mana_eater_mana_flare:OnSpellStart()
	local caster = self:GetCaster()

	if not caster:HasModifier("modifier_mana_eater_mana_flare_buff_aura") then
		-- Apply the buff
		local buff_duration = self:GetSpecialValueFor("duration")
		caster:AddNewModifier(caster, self, "modifier_mana_eater_mana_flare_buff_aura", {duration = buff_duration})
		-- Sound start
		caster:EmitSound("Hero_Juggernaut.HealingWard.Loop")
	else
		-- Remove the buff
		caster:RemoveModifierByName("modifier_mana_eater_mana_flare_buff_aura")
		-- Sound stop
		caster:StopSound("Hero_Juggernaut.HealingWard.Loop")
		-- Go on cooldown
		--local cooldown = self:GetSpecialValueFor("cooldown") * caster:GetCooldownReduction()
		--self:StartCooldown(cooldown)
	end
end

function mana_eater_mana_flare:ProcsMagicStick()
	return true
end

---------------------------------------------------------------------------------------------------

function ManaFlareDamage(event)
	local caster = event.caster
	local unit = event.unit
	local ability = event.ability
	local mana = event.mana

	if not unit or unit:IsNull() then
		return
	end
	-- Basic particles
	--local particle_name = "particles/units/heroes/hero_pugna/pugna_ward_attack.vpcf"
	--local particle = ParticleManager:CreateParticle(particle_name, PATTACH_ABSORIGIN_FOLLOW, caster)
	--ParticleManager:SetParticleControl(particle, 1, unit:GetAbsOrigin())
	--ParticleManager:ReleaseParticleIndex(particle)

	-- Additional particles
	local caster_loc = caster:GetAbsOrigin()
	local unit_loc = unit:GetAbsOrigin()
	if mana < 100 then
		local light = "particles/econ/items/pugna/pugna_ward_ti5/pugna_ward_attack_light_ti_5.vpcf"
		local light_particle = ParticleManager:CreateParticle(light, PATTACH_ABSORIGIN, unit)
		ParticleManager:SetParticleControlEnt(light_particle, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster_loc, true)
		ParticleManager:SetParticleControlEnt(light_particle, 1, unit, PATTACH_POINT_FOLLOW, "attach_hitloc", unit_loc, true)
		--ParticleManager:SetParticleControl(light_particle, 1, unit:GetAbsOrigin())
		ParticleManager:ReleaseParticleIndex(light_particle)
	elseif mana < 200 then
		local medium = "particles/econ/items/pugna/pugna_ward_ti5/pugna_ward_attack_medium_ti_5.vpcf"
		local medium_particle = ParticleManager:CreateParticle(medium, PATTACH_ABSORIGIN, unit)
		ParticleManager:SetParticleControlEnt(medium_particle, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster_loc, true)
		ParticleManager:SetParticleControlEnt(medium_particle, 1, unit, PATTACH_POINT_FOLLOW, "attach_hitloc", unit_loc, true)
		--ParticleManager:SetParticleControl(medium_particle, 1, unit:GetAbsOrigin())
		ParticleManager:ReleaseParticleIndex(medium_particle)
	else
		local heavy = "particles/econ/items/pugna/pugna_ward_ti5/pugna_ward_attack_heavy_ti_5.vpcf"
		local heavy_particle = ParticleManager:CreateParticle(heavy, PATTACH_ABSORIGIN, unit)
		ParticleManager:SetParticleControlEnt(heavy_particle, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster_loc, true)
		ParticleManager:SetParticleControlEnt(heavy_particle, 1, unit, PATTACH_POINT_FOLLOW, "attach_hitloc", unit_loc, true)
		--ParticleManager:SetParticleControl(heavy_particle, 1, unit:GetAbsOrigin())
		ParticleManager:ReleaseParticleIndex(heavy_particle)
	end

	-- Sounds
	unit:EmitSound("Hero_Pugna.NetherWard.Target")
	caster:EmitSound("Hero_Pugna.NetherWard.Attack")

	-- Calculating and applying damage to the main target
	local damage_per_used_mana = ability:GetLevelSpecialValueFor("damage_per_used_mana", ability:GetLevel() - 1)
	local damage_type = ability:GetAbilityDamageType()
	local mana_flare_damage = mana*damage_per_used_mana
	local dealt_damage = ApplyDamage({victim = unit, attacker = caster, ability = ability, damage = mana_flare_damage, damage_type = damage_type})

	-- Splash
	local radius = ability:GetSpecialValueFor("splash_radius")
	local target_team = ability:GetAbilityTargetTeam()
	local enemies = FindUnitsInRadius(
		caster:GetTeamNumber(),
		unit_loc,
		nil,
		radius,
		target_team,
		bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
		DOTA_UNIT_TARGET_FLAG_NONE,
		FIND_ANY_ORDER,
		false
	)
	for _, enemy in pairs(enemies) do
		if enemy and enemy ~= unit and not enemy:IsNull() then
			ApplyDamage({victim = enemy, attacker = caster, ability = ability, damage = dealt_damage, damage_type = damage_type})
		end
	end
end

---------------------------------------------------------------------------------------------------

modifier_mana_eater_mana_flare_buff_aura = class({})

function modifier_mana_eater_mana_flare_buff_aura:IsHidden()
  return true
end

function modifier_mana_eater_mana_flare_buff_aura:IsDebuff()
  return false
end

function modifier_mana_eater_mana_flare_buff_aura:IsPurgable()
  return false
end

function modifier_mana_eater_mana_flare_buff_aura:OnCreated()
	self.armor = self:GetAbility():GetSpecialValueFor("bonus_armor")
end

function modifier_mana_eater_mana_flare_buff_aura:OnDestroy()
	local caster = self:GetCaster()
	if caster and not caster:IsNull() then
		-- Sound stop
		caster:StopSound("Hero_Juggernaut.HealingWard.Loop")
		local ability = self:GetAbility()
		if ability and not ability:IsNull() then
			-- Start cooldown
			local cooldown = ability:GetSpecialValueFor("cooldown") * caster:GetCooldownReduction()
			ability:StartCooldown(cooldown)
		end
	end
end

function modifier_mana_eater_mana_flare_buff_aura:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
  }
end

function modifier_mana_eater_mana_flare_buff_aura:GetModifierPhysicalArmorBonus()
  return self.armor or self:GetAbility():GetSpecialValueFor("bonus_armor")
end

function modifier_mana_eater_mana_flare_buff_aura:CheckState()
  return {
    [MODIFIER_STATE_ROOTED] = true,
  }
end

function modifier_mana_eater_mana_flare_buff_aura:GetEffectName()
	return "particles/econ/items/puck/puck_alliance_set/puck_dreamcoil_aproset.vpcf"
end

function modifier_mana_eater_mana_flare_buff_aura:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW 
end

function modifier_mana_eater_mana_flare_buff_aura:IsAura()
	return true
end

function modifier_mana_eater_mana_flare_buff_aura:GetModifierAura()
	return "modifier_mana_eater_mana_flare_aura_effect"
end

function modifier_mana_eater_mana_flare_buff_aura:GetAuraRadius()
	return self:GetAbility():GetSpecialValueFor("aura_radius")
end

function modifier_mana_eater_mana_flare_buff_aura:GetAuraSearchTeam()
	return self:GetAbility():GetAbilityTargetTeam()
end

function modifier_mana_eater_mana_flare_buff_aura:GetAuraSearchType()
	return bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC)
end

---------------------------------------------------------------------------------------------------

modifier_mana_eater_mana_flare_aura_effect = class({})

function modifier_mana_eater_mana_flare_aura_effect:IsHidden()
  return false -- needs tooltip
end

function modifier_mana_eater_mana_flare_aura_effect:IsDebuff()
  return true
end

function modifier_mana_eater_mana_flare_aura_effect:IsPurgable()
  return false
end

function modifier_mana_eater_mana_flare_aura_effect:OnCreated()
	
end

function modifier_mana_eater_mana_flare_aura_effect:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_SPENT_MANA,
  }
end

if IsServer() then
	function modifier_mana_eater_mana_flare_aura_effect:OnSpentMana(event)
		local parent = self:GetParent()
		local caster = self:GetCaster()
		local ability = self:GetAbility()

		-- Check if unit that spent mana has this modifier
		if event.unit ~= parent then
			return
		end

		local cast_ability = event.ability

		-- If there isn't a cast ability, then do nothing
		if not cast_ability then
			return
		end
		
		local mana_cost = cast_ability:GetManaCost(cast_ability:GetLevel() - 1)
		
		-- Check if its mana cost is zero, we don't know actual mana spent, lets presume it's the same
		if mana_cost <= 0 then
			return
		end

		local t = {}
		t.caster = caster
		t.unit = parent
		t.ability = ability
		t.mana = mana_cost
		ManaFlareDamage(t)
	end
end
