if modifier_custom_counter_helix_aura_effect == nil then
	modifier_custom_counter_helix_aura_effect = class({})
end

function modifier_custom_counter_helix_aura_effect:IsHidden()
	return true
end

function modifier_custom_counter_helix_aura_effect:IsPurgable()
	return false
end

function modifier_custom_counter_helix_aura_effect:IsDebuff()
	return false
end

function modifier_custom_counter_helix_aura_effect:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_ATTACK_START,
	}

	return funcs
end

if IsServer() then
	function modifier_custom_counter_helix_aura_effect:OnAttackStart(event)
		local parent = self:GetParent()

		-- Event variables
		local attacker = event.attacker
		local target = event.target

		if not attacker or attacker:IsNull() or not target or target:IsNull() then
			return
		end

		-- Checking if attacked entity is even a unit
		if target.HasModifier == nil or target.IsHero == nil then
			return
		end

		if parent == attacker and target:HasModifier("modifier_custom_counter_helix_aura_applier") and (not target:PassivesDisabled()) then
			local ability = self:GetAbility()
			local chance = ability:GetSpecialValueFor("trigger_chance")

			if ability:PseudoRandom(chance) and ability:IsCooldownReady() then
				-- Particles
				local particle_name_1 = "particles/units/heroes/hero_axe/axe_attack_blur_counterhelix.vpcf"
				local particle_name_2 = "particles/units/heroes/hero_axe/axe_counterhelix.vpcf"

				local particle_index_1 = ParticleManager:CreateParticle(particle_name_1, PATTACH_ABSORIGIN_FOLLOW, target)
				ParticleManager:SetParticleControl(particle_index_1, 0, target:GetAbsOrigin())
				ParticleManager:ReleaseParticleIndex(particle_index_1)

				local particle_index_2 = ParticleManager:CreateParticle(particle_name_2, PATTACH_ABSORIGIN_FOLLOW, target)
				ParticleManager:SetParticleControl(particle_index_2, 0, target:GetAbsOrigin())
				ParticleManager:ReleaseParticleIndex(particle_index_2)

				-- Animation on attacked target
				target:StartGesture(ACT_DOTA_CAST_ABILITY_3)

				-- Literally spinning the target (unused):
				-- target:AddNewModifier(caster, ability, "modifier_custom_counter_helix_proc", {duration = 0.15})

				-- Sound on attacked target
				target:EmitSound("Hero_Axe.CounterHelix")

				-- Targetting constants
				local target_team = ability:GetAbilityTargetTeam() or DOTA_UNIT_TARGET_TEAM_ENEMY
				local target_type = ability:GetAbilityTargetType() or bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
				local target_flags = ability:GetAbilityTargetFlags() or DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES

				-- KV variables
				local radius = ability:GetSpecialValueFor("radius")
				local damage = ability:GetSpecialValueFor("damage")
				
				-- Talent that increases damage:
				local talent = target:FindAbilityByName("special_bonus_unique_axe_counter_helix_damage")
				if talent and talent:GetLevel() > 0 then
					damage = damage + talent:GetSpecialValueFor("value")
				end

				-- Damage table
				local damage_table = {}
				damage_table.attacker = target
				damage_table.damage_type = ability:GetAbilityDamageType() or DAMAGE_TYPE_PHYSICAL
				damage_table.damage_flags = DOTA_DAMAGE_FLAG_BYPASSES_BLOCK
				damage_table.ability = ability
				damage_table.damage = damage

				-- Damage enemies in a radius around the atacked target
				local enemies = FindUnitsInRadius(target:GetTeamNumber(), target:GetAbsOrigin(), nil, radius, target_team, target_type, target_flags, FIND_ANY_ORDER, false)
				for _, enemy in pairs(enemies) do
					if enemy then
						damage_table.victim = enemy
						ApplyDamage(damage_table)
					end
				end

				ability:UseResources(false, false, true)
			end
		end
	end
end
