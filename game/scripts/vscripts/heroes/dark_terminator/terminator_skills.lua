LinkLuaModifier("modifier_dark_terminator_headshot_passive", "heroes/dark_terminator/terminator_skills.lua", LUA_MODIFIER_MOTION_NONE)

dark_terminator_terminator_skills = class({})

function dark_terminator_terminator_skills:GetIntrinsicModifierName()
	return "modifier_dark_terminator_headshot_passive"
end

---------------------------------------------------------------------------------------------------

modifier_dark_terminator_headshot_passive = class({})

function modifier_dark_terminator_headshot_passive:IsHidden()
	return true
end

function modifier_dark_terminator_headshot_passive:IsDebuff()
	return false
end

function modifier_dark_terminator_headshot_passive:IsPurgable()
	return false
end

function modifier_dark_terminator_headshot_passive:RemoveOnDeath()
	return false
end

function modifier_dark_terminator_headshot_passive:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_EVASION_CONSTANT,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}

	return funcs
end

function modifier_dark_terminator_headshot_passive:GetModifierEvasion_Constant()
	if self:GetParent():PassivesDisabled() then
		return 0
	end

	return self:GetAbility():GetSpecialValueFor("evasion_chance")
end

function modifier_dark_terminator_headshot_passive:OnAttackLanded(event)
    local parent = self:GetParent()
	local ability = self:GetAbility()
	local target = event.target

	if parent ~= event.attacker then
		return
	end

    -- No proc while broken
	if parent:PassivesDisabled() then
		return
	end

	-- To prevent crashes:
	if not target then
		return
	end

	if target:IsNull() then
		return
	end

	if not IsServer() then
		return
	end

	-- Check for existence of GetUnitName method to determine if target is a unit or an item
    -- items don't have that method -> nil; if the target is an item, don't continue
    if target.GetUnitName == nil then
		return
    end

	-- Don't affect buildings and wards
	if target:IsTower() or target:IsBarracks() or target:IsBuilding() or target:IsOther() then
		return
	end

	local chance = ability:GetSpecialValueFor("damage_proc_chance")
	
	-- Talent that increases proc chance:
	local talent = parent:FindAbilityByName("special_bonus_unique_dark_terminator_proc_chance")
	if talent then
		if talent:GetLevel() ~= 0 then
			chance = chance + talent:GetSpecialValueFor("value")
		end
	end

	if ability:PseudoRandom(chance) then

		local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_sniper/sniper_headshot_slow.vpcf", PATTACH_OVERHEAD_FOLLOW, target)
		ParticleManager:SetParticleControl(particle, 0, target:GetAbsOrigin())
		Timers:CreateTimer(1.0, function()
			ParticleManager:DestroyParticle(particle, false)
			ParticleManager:ReleaseParticleIndex(particle)
		end)

		target:EmitSound("Hero_Tinker.Heat-Seeking_Missile.Impact")

		local damage_table = {}
		damage_table.attacker = parent
		damage_table.damage_type = DAMAGE_TYPE_PHYSICAL
		damage_table.damage_flags = bit.bor(DOTA_DAMAGE_FLAG_IGNORES_PHYSICAL_ARMOR, DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL)
		damage_table.ability = ability
		damage_table.victim = target

		-- Calculate bonus damage
		local damage_percent = ability:GetSpecialValueFor("damage_percent")/100

		damage_table.damage = damage_percent * event.original_damage

		ApplyDamage(damage_table)
	end
end
