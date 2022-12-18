-- Called OnSpellStart
function BerserkStart(event)
	local caster = event.caster
	local ability = event.ability

	local duration = ability:GetLevelSpecialValueFor("duration", ability:GetLevel() - 1)

	if caster:IsRangedAttacker() then
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_item_custom_berserk_ranged", {["duration"] = duration})
	else
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_item_custom_berserk_melee", {["duration"] = duration})
	end
end

-- Called OnAttackLanded
function LifestealOnAttackLanded(keys)
	local target = keys.target
	local ability = keys.ability
	local attacker = keys.attacker
	local damage_on_attack = keys.DamageOnAttack

	-- Check if attacker exists
	if not attacker or attacker:IsNull() then
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

	-- Don't lifesteal from buildings, wards and invulnerable units.
	if target:IsTower() or target:IsBarracks() or target:IsBuilding() or target:IsOther() or target:IsInvulnerable() then
		return
	end

	-- Check if attacker is dead
	if not attacker:IsAlive() then
		return
	end

	-- Check if damage is 0 or negative
	if damage_on_attack <= 0 then
		return
	end

	local lifesteal_melee = ability:GetLevelSpecialValueFor("lifesteal_percent_melee", ability:GetLevel() - 1)
	local lifesteal_ranged = ability:GetLevelSpecialValueFor("lifesteal_percent_ranged", ability:GetLevel() - 1)

	if attacker:IsRealHero() then
		local lifesteal_amount
		if attacker:IsRangedAttacker() then
			lifesteal_amount = damage_on_attack*lifesteal_ranged*0.01
		else
			lifesteal_amount = damage_on_attack*lifesteal_melee*0.01
		end

		if lifesteal_amount > 0 then
			--attacker:Heal(lifesteal_amount, attacker)
			attacker:HealWithParams(lifesteal_amount, ability, true, true, attacker, false)
		end
	end

	-- Particle
	local lifesteal_particle = "particles/generic_gameplay/generic_lifesteal.vpcf"
	local lifesteal_fx = ParticleManager:CreateParticle(lifesteal_particle, PATTACH_ABSORIGIN_FOLLOW, attacker)
	ParticleManager:SetParticleControl(lifesteal_fx, 0, attacker:GetAbsOrigin())
	ParticleManager:ReleaseParticleIndex(lifesteal_fx)
end
