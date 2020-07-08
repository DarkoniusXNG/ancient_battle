LinkLuaModifier("modifier_dark_terminator_terminate_target", "heroes/dark_terminator/terminate.lua", LUA_MODIFIER_MOTION_NONE)

dark_terminator_terminate = class({})

function dark_terminator_terminate:GetCastPoint()
	local delay = self.BaseClass.GetCastPoint(self)
	if IsServer() then
		local talent = self:GetCaster():FindAbilityByName("special_bonus_unique_dark_terminator_terminate")
		if talent then
			if talent:GetLevel() ~= 0 then
				delay = delay - talent:GetSpecialValueFor("value")
			end
		end
	end
	return delay
end

function dark_terminator_terminate:OnAbilityPhaseStart(keys)
    local caster = self:GetCaster()
    caster:EmitSound("Ability.AssassinateLoad")
    -- Store the target(s) in self.storedTarget, apply a modifier that reveals them
    self.storedTarget = {}
	self.storedTarget[1] = self:GetCursorTarget()
	self.storedTarget[1]:AddNewModifier(caster, self, "modifier_dark_terminator_terminate_target", {duration = self:GetCastPoint() + 2})
    return true
end

function dark_terminator_terminate:OnAbilityPhaseInterrupted()
    local caster = self:GetCaster()
	-- Remove the crosshairs from the target(s)
	if self.storedTarget then
		for k,v in pairs(self.storedTarget) do
			if v then
				v:RemoveModifierByName("modifier_dark_terminator_terminate_target")
			end
		end
	end
    self.storedTarget = nil
end

function dark_terminator_terminate:OnSpellStart(keys)
    local caster = self:GetCaster()

	-- Sound
	caster:EmitSound("Ability.Assassinate")

    if not self.storedTarget then -- Should never happen, but to prevent errors we return here
        return
    end

    -- Because we stored the targets in a table, it is easy to fire a projectile at all of them
    for k,v in pairs(self.storedTarget) do
        local projTable = {
            EffectName = "particles/units/heroes/hero_sniper/sniper_assassinate.vpcf",
            Ability = self,
            Target = v,
            Source = caster,
            bDodgeable = true,
            bProvidesVision = true,
            vSpawnOrigin = caster:GetAbsOrigin(),
            iMoveSpeed = self:GetSpecialValueFor("projectile_speed"), --
            iVisionRadius = 100,--
            iVisionTeamNumber = caster:GetTeamNumber(),
            iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1
        }
        ProjectileManager:CreateTrackingProjectile(projTable)
    end
end

function dark_terminator_terminate:OnProjectileHit(target, vLocation)
	local caster = self:GetCaster()

	if not target or target:IsNull() then
		return
	end
	
	-- Remove the crosshair+vision
    target:RemoveModifierByName("modifier_dark_terminator_terminate_target")

	for k,v in pairs(self.storedTarget) do
		if v == target then
			self.storedTarget[k] = nil
		end
	end

	--local sound_target = "Hero_Sniper.AssassinateProjectile"
	--target:EmitSound(sound_target)

	-- If target has Spell Block, don't continue
	if target:TriggerSpellAbsorb(self) then
		return true
	end

    -- Sound
	target:EmitSound("Hero_Sniper.AssassinateDamage")

	-- Mini-stun
	target:Interrupt()

	-- Damage
	local damageTable = {
		victim = target,
		attacker = caster,
		damage = self:GetSpecialValueFor("damage"),
		damage_type = self:GetAbilityDamageType(),
	}
	ApplyDamage(damageTable)

    return true
end

---------------------------------------------------------------------------------------------------

modifier_dark_terminator_terminate_target = class({})

function modifier_dark_terminator_terminate_target:IsHidden()
    return false
end

function modifier_dark_terminator_terminate_target:IsDebuff()
    return true
end

function modifier_dark_terminator_terminate_target:IsPurgable()
    return false
end

function modifier_dark_terminator_terminate_target:GetEffectName()
    return "particles/units/heroes/hero_sniper/sniper_crosshair.vpcf"
end

function modifier_dark_terminator_terminate_target:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW
end

function modifier_dark_terminator_terminate_target:CheckStates()
    local state = {
		[MODIFIER_STATE_INVISIBLE] = false,
		[MODIFIER_STATE_PROVIDES_VISION] = true,
    }
    return state
end

function modifier_dark_terminator_terminate_target:DeclareFunctions()
	local funcs = { 
		MODIFIER_PROPERTY_PROVIDES_FOW_POSITION,
	}
	return funcs
end

function modifier_dark_terminator_terminate_target:GetModifierProvidesFOWVision()
	return 1
end
