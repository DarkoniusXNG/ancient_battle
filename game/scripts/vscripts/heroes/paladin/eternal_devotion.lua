if paladin_eternal_devotion == nil then
	paladin_eternal_devotion = class({})
end

LinkLuaModifier("modifier_paladin_eternal_devotion_passive", "heroes/paladin/eternal_devotion.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_custom_devotion_aura_effect", "heroes/paladin/eternal_devotion.lua", LUA_MODIFIER_MOTION_NONE) -- needs tooltip
LinkLuaModifier("modifier_custom_guardian_angel_buff", "heroes/paladin/eternal_devotion.lua", LUA_MODIFIER_MOTION_NONE) -- needs tooltip
LinkLuaModifier("modifier_custom_guardian_angel_summon", "heroes/paladin/eternal_devotion.lua", LUA_MODIFIER_MOTION_NONE)

function paladin_eternal_devotion:IsStealable()
	return false
end

function paladin_eternal_devotion:GetIntrinsicModifierName()
	return "modifier_paladin_eternal_devotion_passive"
end

---------------------------------------------------------------------------------------------------

if modifier_paladin_eternal_devotion_passive == nil then
	modifier_paladin_eternal_devotion_passive = class({})
end

function modifier_paladin_eternal_devotion_passive:IsHidden()
	return true
end

function modifier_paladin_eternal_devotion_passive:IsDebuff()
	return false
end

function modifier_paladin_eternal_devotion_passive:IsPurgable()
	return false
end

function modifier_paladin_eternal_devotion_passive:RemoveOnDeath()
	return false
end

function modifier_paladin_eternal_devotion_passive:IsAura()
	local parent = self:GetParent()
	if parent:PassivesDisabled() then
		return false
	end
	return true
end

function modifier_paladin_eternal_devotion_passive:AllowIllusionDuplicate()
	return true
end

function modifier_paladin_eternal_devotion_passive:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT
end

function modifier_paladin_eternal_devotion_passive:GetModifierAura()
	return "modifier_custom_devotion_aura_effect"
end

function modifier_paladin_eternal_devotion_passive:GetAuraRadius()
	local parent = self:GetParent()
	local ability = self:GetAbility()
	local radius = ability:GetSpecialValueFor("aura_radius")

	-- Check for Global talent
	local talent_1 = parent:FindAbilityByName("special_bonus_unique_paladin_2")
	if talent_1 and talent_1:GetLevel() > 0 then
		radius = FIND_UNITS_EVERYWHERE
	end

	return radius
end

function modifier_paladin_eternal_devotion_passive:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_paladin_eternal_devotion_passive:GetAuraSearchType()
	return bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC)
end

function modifier_paladin_eternal_devotion_passive:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_DEATH,
	}
end

if IsServer() then
	function modifier_paladin_eternal_devotion_passive:OnDeath(event)
		local parent = self:GetParent()
		local killer = event.attacker
		local dead = event.unit

		-- Don't continue if the killer doesn't exist
		if not killer or killer:IsNull() then
			return
		end

		-- Don't continue if the dead isn't the parent
		if dead ~= parent then
			return
		end

		-- Doesn't work on illusions
		if parent:IsIllusion() then
			return
		end

		-- Don't continue if the ability doesn't exist
		local ability = self:GetAbility()
		if not ability or ability:IsNull() then
			return
		end

		-- Sound
		parent:EmitSound("Hero_Omniknight.GuardianAngel.Cast")

		local ability_level = ability:GetLevel() - 1
		local buff_duration = ability:GetLevelSpecialValueFor("buff_duration", ability_level)
		local radius = ability:GetLevelSpecialValueFor("buff_radius", ability_level)

		local talent_1 = parent:FindAbilityByName("special_bonus_unique_paladin_2")
		local talent_2 = parent:FindAbilityByName("special_bonus_unique_paladin_5")
		local team = parent:GetTeamNumber()
		local death_loc = parent:GetAbsOrigin()

		-- Check for the Global talent
		if talent_1 and talent_1:GetLevel() > 0 then
			radius = FIND_UNITS_EVERYWHERE
		end

		-- Check for Wrath of God talent
		local wrath_of_god = false
		if talent_2 and talent_2:GetLevel() > 0 then
			wrath_of_god = true
		end

		local target_type = bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BUILDING)
		local target_flags = DOTA_UNIT_TARGET_FLAG_NONE

		-- Apply Guardian Angel buff to allies
		local allies = FindUnitsInRadius(team, death_loc, nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, target_type, target_flags, FIND_ANY_ORDER, false)
		for _, ally in pairs(allies) do
			if ally and not ally:IsNull() then
				ally:AddNewModifier(parent, ability, "modifier_custom_guardian_angel_buff", {duration = buff_duration})
			end
		end

		-- Calculate Angel damage
		local multiplier = ability:GetLevelSpecialValueFor("angel_revenge_damage_multiplier", ability_level)
		local killer_dmg
		if killer.GetAverageTrueAttackDamage and not killer:IsTower() and not killer:IsFountain() then
			killer_dmg = killer:GetAverageTrueAttackDamage(parent)
		else
			killer_dmg = parent:GetAverageTrueAttackDamage(parent)
		end
		local angel_dmg = killer_dmg * multiplier
		
		-- Calculate Angel duration
		local min_duration = ability:GetLevelSpecialValueFor("angel_min_duration", ability_level)
		local respawn_time = parent:GetTimeUntilRespawn()
		local angel_duration = math.max(min_duration, respawn_time)

		-- Create an Angel at the death location
		local main_angel = CreateUnitByName("npc_dota_summoned_guardian_angel", death_loc, true, parent, parent:GetOwner(), team)
		FindClearSpaceForUnit(main_angel, death_loc, false)
		main_angel:SetControllableByPlayer(playerID, false)
		main_angel:SetOwner(parent)
		main_angel:SetBaseDamageMin(angel_dmg)
		main_angel:SetBaseDamageMax(angel_dmg)

		main_angel:AddNewModifier(parent, ability, "modifier_kill", {duration = angel_duration})
		
		-- Apply angel buff
		main_angel:AddNewModifier(parent, ability, "modifier_custom_guardian_angel_summon", {duration = angel_duration})

		-- Wrath of God - Summoning uncontrollable angels to attack enemies
		if wrath_of_god then
			target_type = bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
			target_flags = bit.bor(DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS, DOTA_UNIT_TARGET_FLAG_NOT_ATTACK_IMMUNE)
			local enemies = FindUnitsInRadius(team, death_loc, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, target_type, target_flags, FIND_ANY_ORDER, false)

			for _, enemy in pairs(enemies) do
				if enemy and not enemy:IsNull() and enemy ~= killer then
					local position = enemy:GetAbsOrigin()

					-- Create an angel at the enemy position (maybe async will lag less)
					CreateUnitByNameAsync("npc_dota_summoned_guardian_angel", position, true, parent, parent:GetOwner(), team,
					function (angel)
						FindClearSpaceForUnit(angel, position, false)
						--angel:SetControllableByPlayer(playerID, false) -- uncontrollable on purpose
						angel:SetOwner(parent)
						angel:SetBaseDamageMin(angel_dmg)
						angel:SetBaseDamageMax(angel_dmg)

						angel:AddNewModifier(parent, ability, "modifier_kill", {duration = buff_duration})

						-- Apply angel buff
						angel:AddNewModifier(parent, ability, "modifier_custom_guardian_angel_summon", {duration = buff_duration})

						-- Order the angel to attack the enemy
						angel:SetForceAttackTarget(enemy)

						return angel
					end)
				end
			end
		end
	end
end

---------------------------------------------------------------------------------------------------

if modifier_custom_devotion_aura_effect == nil then
	modifier_custom_devotion_aura_effect = class({})
end

function modifier_custom_devotion_aura_effect:IsHidden()
	return false
end

function modifier_custom_devotion_aura_effect:IsDebuff()
	return false
end

function modifier_custom_devotion_aura_effect:IsPurgable()
	return false
end

function modifier_custom_devotion_aura_effect:OnCreated(event)
	local ability = self:GetAbility()

	local armor = 2
	if ability and not ability:IsNull() then
		armor = ability:GetSpecialValueFor("aura_bonus_armor")
	end

	self.armor = armor
end

function modifier_custom_devotion_aura_effect:OnRefresh(event)
	self:OnCreated(event)
end

function modifier_custom_devotion_aura_effect:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
	}
end

function modifier_custom_devotion_aura_effect:GetModifierPhysicalArmorBonus()
	return self.armor or self:GetAbility():GetSpecialValueFor("aura_bonus_armor")
end

function modifier_custom_devotion_aura_effect:GetEffectName()
	return "particles/custom/aura_devotion.vpcf"
end

function modifier_custom_devotion_aura_effect:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

---------------------------------------------------------------------------------------------------

if modifier_custom_guardian_angel_buff == nil then
	modifier_custom_guardian_angel_buff = class({})
end

function modifier_custom_guardian_angel_buff:IsHidden()
	return false
end

function modifier_custom_guardian_angel_buff:IsDebuff()
	return false
end

function modifier_custom_guardian_angel_buff:IsPurgable()
	return true
end

function modifier_custom_guardian_angel_buff:OnCreated(event)
	local ability = self:GetAbility()

	local hp_regen = 25
	if ability and not ability:IsNull() then
		hp_regen = ability:GetSpecialValueFor("buff_health_regen")
	end

	self.hp_regen = hp_regen
end

function modifier_custom_guardian_angel_buff:OnRefresh(event)
	self:OnCreated(event)
end

function modifier_custom_guardian_angel_buff:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
	}
end

function modifier_custom_guardian_angel_buff:GetAbsoluteNoDamagePhysical()
	return 1
end

function modifier_custom_guardian_angel_buff:GetModifierConstantHealthRegen()
	return self.hp_regen or self:GetAbility():GetSpecialValueFor("buff_health_regen")
end

function modifier_custom_guardian_angel_buff:GetEffectName()
	return "particles/units/heroes/hero_omniknight/omniknight_guardian_angel_ally.vpcf"
end

function modifier_custom_guardian_angel_buff:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_custom_guardian_angel_buff:GetStatusEffectName()
	return "particles/status_fx/status_effect_guardian_angel.vpcf"
end

function modifier_custom_guardian_angel_buff:StatusEffectPriority()
	return 10
end

---------------------------------------------------------------------------------------------------

if modifier_custom_guardian_angel_summon == nil then
	modifier_custom_guardian_angel_summon = class({})
end

function modifier_custom_guardian_angel_summon:IsHidden()
	return true
end

function modifier_custom_guardian_angel_summon:IsDebuff()
	return false
end

function modifier_custom_guardian_angel_summon:IsPurgable()
	return false
end

function modifier_custom_guardian_angel_summon:OnCreated(event)
	local parent = self:GetParent()
	local particle_name = "particles/frostivus_herofx/holdout_guardian_angel_wings.vpcf"
	local sound_name = "Hero_Omniknight.GuardianAngel"
	
	if IsServer() then
		-- Sound
		parent:EmitSound(sound_name)
		
		-- Particle
		--local particle1 = ParticleManager:CreateParticle(particle_name_1, PATTACH_ABSORIGIN_FOLLOW, parent)
		--ParticleManager:SetParticleControlEnt(particle1, 5, parent, PATTACH_ROOTBONE_FOLLOW, "attach_hitloc", parent:GetOrigin(), true)
	end
end

function modifier_custom_guardian_angel_summon:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
	}
end

function modifier_custom_guardian_angel_summon:GetAbsoluteNoDamagePhysical()
	return 1
end

function modifier_custom_guardian_angel_summon:GetEffectName()
	return "particles/units/heroes/hero_omniknight/omniknight_guardian_angel_omni.vpcf"
end

function modifier_custom_guardian_angel_summon:GetStatusEffectName()
	return "particles/status_fx/status_effect_ghost.vpcf"
end

function modifier_custom_guardian_angel_summon:StatusEffectPriority()
	return MODIFIER_PRIORITY_SUPER_ULTRA
end
