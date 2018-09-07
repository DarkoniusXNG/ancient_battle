if paladin_storm_hammer == nil then
	paladin_storm_hammer = class({})
end

LinkLuaModifier("modifier_paladin_storm_hammer", "heroes/paladin/modifier_paladin_storm_hammer.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_paladin_storm_hammer_talent", "heroes/paladin/modifier_paladin_storm_hammer_talent.lua", LUA_MODIFIER_MOTION_NONE)

function paladin_storm_hammer:GetAOERadius()
	return self:GetSpecialValueFor("bolt_aoe")
end

function paladin_storm_hammer:GetCooldown(nLevel)
	local caster = self:GetCaster()
	local cooldown = self.BaseClass.GetCooldown(self, nLevel)
	
	if IsServer() then
		-- Talent that reduces cooldown
		local talent = caster:FindAbilityByName("special_bonus_unique_sven")
		if talent then
			if talent:GetLevel() ~= 0 then
				local reduction = talent:GetSpecialValueFor("value")
				cooldown = cooldown - reduction
			end
		end
	else
		if caster:HasModifier("modifier_paladin_storm_hammer_talent") then
			cooldown = cooldown - caster.storm_hammer_talent_value
		end
	end
	
	return cooldown
end

function paladin_storm_hammer:OnSpellStart()
	local vision_radius = self:GetSpecialValueFor("vision_radius")
	local bolt_speed = self:GetSpecialValueFor("bolt_speed")
	local caster = self:GetCaster()

	local info = {
			EffectName = "particles/units/heroes/hero_sven/sven_spell_storm_bolt.vpcf",
			Ability = self,
			iMoveSpeed = bolt_speed,
			Source = caster,
			Target = self:GetCursorTarget(),
			bDodgeable = true,
			bProvidesVision = true,
			iVisionTeamNumber = caster:GetTeamNumber(),
			iVisionRadius = vision_radius,
			iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_2, 
		}

	ProjectileManager:CreateTrackingProjectile(info)
	
	-- Sound on caster
	EmitSoundOn("Hero_Sven.StormBolt", caster)
end

function paladin_storm_hammer:OnProjectileHit(target, location)
	if target then 
		if (not target:IsInvulnerable()) and (not target:TriggerSpellAbsorb(self)) then
			-- Sound on target
			EmitSoundOn("Hero_Sven.StormBoltImpact", target)
			
			-- Kv variables
			local bolt_aoe = self:GetSpecialValueFor("bolt_aoe")
			local bolt_damage = self:GetSpecialValueFor("bolt_damage")
			local bolt_stun_duration = self:GetSpecialValueFor("bolt_stun_duration")
			
			local caster = self:GetCaster()
			
			-- Targetting constants
			local target_team = self:GetAbilityTargetTeam() or DOTA_UNIT_TARGET_TEAM_ENEMY
			local target_type = self:GetAbilityTargetType() or bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
			local target_flags = self:GetAbilityTargetFlags() or DOTA_UNIT_TARGET_FLAG_NONE

			local enemies = FindUnitsInRadius(caster:GetTeamNumber(), target:GetOrigin(), target, bolt_aoe, target_team, target_type, target_flags, FIND_ANY_ORDER, false)
			for _,enemy in pairs(enemies) do
				if enemy then 
					if (not enemy:IsMagicImmune()) and (not enemy:IsInvulnerable()) then

						local damage_table = {}
						damage_table.victim = enemy
						damage_table.attacker = caster
						damage_table.damage = bolt_damage
						damage_table.damage_type = self:GetAbilityDamageType()
						damage_table.ability = self

						ApplyDamage(damage_table)
					
						enemy:AddNewModifier(caster, self, "modifier_paladin_storm_hammer", {duration = bolt_stun_duration})
					end
				end
			end
		end
	end

	return true
end

function paladin_storm_hammer:ProcsMagicStick()
	return true
end
