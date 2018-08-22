if paladin_storm_hammer == nil then
	paladin_storm_hammer = class({})
end

LinkLuaModifier("modifier_paladin_storm_hammer", "heroes/paladin/modifiers/modifier_paladin_storm_hammer.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_custom_paladin_talent", "heroes/paladin/modifiers/modifier_custom_paladin_talent", LUA_MODIFIER_MOTION_NONE)

function paladin_storm_hammer:GetAOERadius()
	return self:GetSpecialValueFor("bolt_aoe")
end

function paladin_storm_hammer:GetCooldown(nLevel)
	local caster = self:GetCaster()
	local cooldown = self.BaseClass.GetCooldown(self, nLevel)
	
	if IsServer() then
		local talent = caster:FindAbilityByName("special_bonus_unique_sven")
		if talent then
			if talent:GetLevel() ~= 0 then
				cooldown = cooldown - 5.0
			end
		end
	else
		if caster:HasModifier("modifier_custom_paladin_talent") then
			cooldown = cooldown - 5.0
		end
	end
	
	return cooldown
end

function paladin_storm_hammer:OnSpellStart()
	local vision_radius = self:GetSpecialValueFor("vision_radius")
	local bolt_speed = self:GetSpecialValueFor("bolt_speed")

	local info = {
			EffectName = "particles/units/heroes/hero_sven/sven_spell_storm_bolt.vpcf",
			Ability = self,
			iMoveSpeed = bolt_speed,
			Source = self:GetCaster(),
			Target = self:GetCursorTarget(),
			bDodgeable = true,
			bProvidesVision = true,
			iVisionTeamNumber = self:GetCaster():GetTeamNumber(),
			iVisionRadius = vision_radius,
			iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_2, 
		}

	ProjectileManager:CreateTrackingProjectile(info)
	EmitSoundOn("Hero_Sven.StormBolt", self:GetCaster())
end

function paladin_storm_hammer:OnProjectileHit(hTarget, vLocation)
	if hTarget ~= nil and (not hTarget:IsInvulnerable()) and (not hTarget:TriggerSpellAbsorb(self)) then
		EmitSoundOn("Hero_Sven.StormBoltImpact", hTarget)
		local bolt_aoe = self:GetSpecialValueFor("bolt_aoe")
		local bolt_damage = self:GetSpecialValueFor("bolt_damage")
		local bolt_stun_duration = self:GetSpecialValueFor("bolt_stun_duration")

		local enemies = FindUnitsInRadius(self:GetCaster():GetTeamNumber(), hTarget:GetOrigin(), hTarget, bolt_aoe, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 0, 0, false)
		if #enemies > 0 then
			for _,enemy in pairs(enemies) do
				if enemy ~= nil and (not enemy:IsMagicImmune()) and (not enemy:IsInvulnerable()) then

					local damage_table = {
						victim = enemy,
						attacker = self:GetCaster(),
						damage = bolt_damage,
						damage_type = DAMAGE_TYPE_MAGICAL,
					}

					ApplyDamage(damage_table)
					enemy:AddNewModifier(self:GetCaster(), self, "modifier_paladin_storm_hammer", {duration = bolt_stun_duration})
				end
			end
		end
	end

	return true
end