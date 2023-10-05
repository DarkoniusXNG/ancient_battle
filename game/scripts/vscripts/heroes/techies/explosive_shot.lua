techies_custom_explosive_shot = class({})

LinkLuaModifier("modifier_techies_explosive_shot_passive", "heroes/techies/explosive_shot.lua", LUA_MODIFIER_MOTION_NONE)

-- Techies as a hero is hardcoded and it auto-levels the ability in minefield sign slot so this is not needed
-- function techies_custom_explosive_shot:Spawn()
  -- if IsServer() and self:GetLevel() < 1 then
    -- self:SetLevel(1)
  -- end
-- end

function techies_custom_explosive_shot:GetIntrinsicModifierName()
	return "modifier_techies_explosive_shot_passive"
end

function techies_custom_explosive_shot:IsStealable()
	return false
end

function techies_custom_explosive_shot:ShouldUseResources()
	return false
end

---------------------------------------------------------------------------------------------------

modifier_techies_explosive_shot_passive = modifier_techies_explosive_shot_passive or class({})

function modifier_techies_explosive_shot_passive:IsHidden()
	return true
end

function modifier_techies_explosive_shot_passive:IsPurgable()
	return false
end

function modifier_techies_explosive_shot_passive:IsDebuff()
	return false
end

function modifier_techies_explosive_shot_passive:RemoveOnDeath()
	return false
end

function modifier_techies_explosive_shot_passive:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end

function modifier_techies_explosive_shot_passive:GetModifierPreAttack_BonusDamage()
	if not self:GetParent():PassivesDisabled() then
		return self:GetAbility():GetSpecialValueFor("bonus_damage")
	end
end

if IsServer() then
	function modifier_techies_explosive_shot_passive:OnAttackLanded(event)
		local parent = self:GetParent()
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

		-- To prevent crashes:
		if not target or target:IsNull() then
			return
		end

		-- Check for existence of GetUnitName method to determine if target is a unit or an item
		-- items don't have that method -> nil; if the target is an item, don't continue
		if target.GetUnitName == nil then
			return
		end

		-- Doesn't work on illusions or when affected by Break
		if parent:IsIllusion() or parent:PassivesDisabled() then
			return
		end

		local ability = self:GetAbility()
		if not ability or ability:IsNull() then
			return
		end

		local attack_damage = event.original_damage -- Damage before reductions

		-- Check if damage is somehow 0 or negative
		if attack_damage <= 0 then
			return
		end

		local function TableContains(t, element)
			if t == nil then return false end
			for _, v in pairs(t) do
				if v == element then
					return true
				end
			end
			return false
		end

		local team = parent:GetTeamNumber()
		local point = target:GetAbsOrigin()
		local full_radius = ability:GetSpecialValueFor("full_damage_radius")
		local half_radius = ability:GetSpecialValueFor("half_damage_radius")
		local quarter_radius = ability:GetSpecialValueFor("quarter_damage_radius")
		local target_team = DOTA_UNIT_TARGET_TEAM_ENEMY
		local target_type = bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BUILDING)
		local target_flags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES

		local enemies_full = FindUnitsInRadius(team, point, nil, full_radius, target_team, target_type, target_flags, FIND_ANY_ORDER, false)
		local enemies_half = FindUnitsInRadius(team, point, nil, half_radius, target_team, target_type, target_flags, FIND_ANY_ORDER, false)
		local enemies_quarter = FindUnitsInRadius(team, point, nil, quarter_radius, target_team, target_type, target_flags, FIND_ANY_ORDER, false)

		if #enemies_quarter <= 1 then
			return
		end

		local full_dmg = attack_damage
		local half_dmg = attack_damage / 2
		local quarter_dmg = attack_damage / 4

		-- Damage table
		local damage_table = {}
		damage_table.attacker = parent
		damage_table.damage_type = DAMAGE_TYPE_PHYSICAL
		damage_table.ability = ability
		damage_table.damage_flags = bit.bor(DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL)

		-- Splash
		for _, enemy in pairs(enemies_quarter) do
			if enemy and not enemy:IsNull() and not enemy:IsCustomWardTypeUnit() and enemy ~= target then
				-- Victim
				damage_table.victim = enemy

				-- Calculate damage
				local actual_dmg = quarter_dmg
				-- Increase the damage if enemy is closer to the center
				if TableContains(enemies_full, enemy) then
					actual_dmg = full_dmg
				elseif TableContains(enemies_half, enemy) then
					actual_dmg = half_dmg
				end

				damage_table.damage = actual_dmg

				-- Apply damage
				ApplyDamage(damage_table)
			end
		end

		local part = ParticleManager:CreateParticle("particles/econ/items/clockwerk/clockwerk_paraflare/clockwerk_para_rocket_flare_explosion.vpcf", PATTACH_CUSTOMORIGIN, parent)
		ParticleManager:SetParticleControl(part, 3, point)
		ParticleManager:ReleaseParticleIndex(part)
	end
end
