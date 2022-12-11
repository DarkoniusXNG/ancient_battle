pudge_custom_meat_hook = class({})

LinkLuaModifier("modifier_pudge_meat_hook_followthrough_lua", "heroes/pudge/meat_hook.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_pudge_custom_meat_hook", "heroes/pudge/meat_hook.lua", LUA_MODIFIER_MOTION_HORIZONTAL)

function pudge_custom_meat_hook:OnAbilityPhaseStart()
	self:GetCaster():StartGesture( ACT_DOTA_OVERRIDE_ABILITY_1 )
	return true
end

function pudge_custom_meat_hook:OnAbilityPhaseInterrupted()
	self:GetCaster():RemoveGesture( ACT_DOTA_OVERRIDE_ABILITY_1 )
end

function pudge_custom_meat_hook:GetCooldown(level)
  local caster = self:GetCaster()
  local base_cooldown = self.BaseClass.GetCooldown(self, level)

  -- Talent that decreases cooldown
  local talent = caster:FindAbilityByName("special_bonus_unique_pudge_custom_3")
  if talent and talent:GetLevel() > 0 then
    return base_cooldown - math.abs(talent:GetSpecialValueFor("value"))
  end

  return base_cooldown
end

function pudge_custom_meat_hook:OnSpellStart()
	self.bChainAttached = false
	-- Interrupt previous instance ? in case of refresher or wtf mode?
	if self.hVictim then
		self.hVictim:InterruptMotionControllers(true)
	end

	local caster = self:GetCaster()

	self.hook_damage = self:GetSpecialValueFor("damage")
	self.hook_speed = self:GetSpecialValueFor("hook_speed")
	local hook_width = self:GetSpecialValueFor("hook_width")
	local hook_distance = self:GetSpecialValueFor("hook_distance") + caster:GetCastRangeBonus()
	local hook_followthrough_constant = self:GetSpecialValueFor("hook_followthrough_constant")

	-- Talent that increases damage
	local talent_1 = caster:FindAbilityByName("special_bonus_unique_pudge_custom_2")
	if talent_1 and talent_1:GetLevel() > 0 then
		self.hook_damage = self.hook_damage + talent_1:GetSpecialValueFor("value")
	end

	-- Talent that increases speed
	local talent_2 = caster:FindAbilityByName("special_bonus_unique_pudge_custom_4")
	if talent_2 and talent_2:GetLevel() > 0 then
		self.hook_speed = self.hook_speed + talent_2:GetSpecialValueFor("value")
	end

	local hHook = caster:GetTogglableWearable(DOTA_LOADOUT_TYPE_WEAPON)
	if hHook then
		hHook:AddEffects(EF_NODRAW)
	end

	self.vStartPosition = caster:GetOrigin()
	self.vProjectileLocation = self.vStartPosition

	local vDirection = self:GetCursorPosition() - self.vStartPosition
	vDirection.z = 0.0

	vDirection = ( vDirection:Normalized() ) * hook_distance
	self.vTargetPosition = self.vStartPosition + vDirection

	-- self stun duration based on max distance hook and hook speed
	local flFollowthroughDuration = ( hook_distance / self.hook_speed * hook_followthrough_constant )
	caster:AddNewModifier( caster, self, "modifier_pudge_meat_hook_followthrough_lua", { duration = flFollowthroughDuration } )

	self.vHookOffset = Vector( 0, 0, 96 )
	local vHookTarget = self.vTargetPosition + self.vHookOffset
	local vKillswitch = Vector( ( ( hook_distance / self.hook_speed ) * 2 ), 0, 0 )

	self.nChainParticleFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_pudge/pudge_meathook.vpcf", PATTACH_CUSTOMORIGIN, caster )
	ParticleManager:SetParticleAlwaysSimulate( self.nChainParticleFXIndex )
	ParticleManager:SetParticleControlEnt( self.nChainParticleFXIndex, 0, caster, PATTACH_POINT_FOLLOW, "attach_weapon_chain_rt", caster:GetOrigin() + self.vHookOffset, true )
	ParticleManager:SetParticleControl( self.nChainParticleFXIndex, 1, vHookTarget )
	ParticleManager:SetParticleControl( self.nChainParticleFXIndex, 2, Vector( self.hook_speed, hook_distance, hook_width ) )
	ParticleManager:SetParticleControl( self.nChainParticleFXIndex, 3, vKillswitch )
	ParticleManager:SetParticleControl( self.nChainParticleFXIndex, 4, Vector( 1, 0, 0 ) )
	ParticleManager:SetParticleControl( self.nChainParticleFXIndex, 5, Vector( 0, 0, 0 ) )
	ParticleManager:SetParticleControlEnt( self.nChainParticleFXIndex, 7, caster, PATTACH_CUSTOMORIGIN, nil, caster:GetOrigin(), true )

	caster:EmitSound("Hero_Pudge.AttackHookExtend")

	local info = {
		Ability = self,
		vSpawnOrigin = caster:GetOrigin(),
		vVelocity = vDirection:Normalized() * self.hook_speed,
		fDistance = hook_distance,
		fStartRadius = hook_width,
		fEndRadius = hook_width,
		Source = caster,
		iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_BOTH,
		iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_NOT_ANCIENTS + DOTA_UNIT_TARGET_FLAG_INVULNERABLE,
	}

	ProjectileManager:CreateLinearProjectile(info)

	self.bRetracting = false
	self.hVictim = nil
end

function pudge_custom_meat_hook:OnProjectileHit(hTarget, vLocation)
	local caster = self:GetCaster()
	if hTarget == caster then
		return false
	end

	if self.bRetracting == false then
		if hTarget and ( not ( hTarget:IsCreep() or hTarget:IsConsideredHero() ) ) then
			print("Meat Hook Target was invalid")
			return false
		end

		local bTargetPulled = false
		if hTarget then
			hTarget:EmitSound("Hero_Pudge.AttackHookImpact")

			-- Interrupt existing motion controllers (it should also interrupt existing instances of hook)
			if hTarget:IsCurrentlyHorizontalMotionControlled() then
				hTarget:InterruptMotionControllers(false)
			end

			hTarget:AddNewModifier( caster, self, "modifier_pudge_custom_meat_hook", {} )

			if hTarget:GetTeamNumber() ~= caster:GetTeamNumber() then
				local damage = {
						victim = hTarget,
						attacker = caster,
						damage = self.hook_damage,
						damage_type = DAMAGE_TYPE_PURE,
						ability = self
					}

				ApplyDamage( damage )

				if not hTarget:IsMagicImmune() then
					hTarget:Interrupt()
				end

				local nFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_pudge/pudge_meathook_impact.vpcf", PATTACH_CUSTOMORIGIN, hTarget )
				ParticleManager:SetParticleControlEnt( nFXIndex, 0, hTarget, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetOrigin(), true )
				ParticleManager:ReleaseParticleIndex( nFXIndex )
			end

			local vision_radius = self:GetSpecialValueFor("vision_radius")
			local vision_duration = self:GetSpecialValueFor("vision_duration")
			AddFOWViewer( caster:GetTeamNumber(), hTarget:GetOrigin(), vision_radius, vision_duration, false )
			self.hVictim = hTarget
			bTargetPulled = true
		end

		local vHookPos = self.vTargetPosition
		local flPad = caster:GetPaddedCollisionRadius()
		if hTarget then
			vHookPos = hTarget:GetOrigin()
			flPad = flPad + hTarget:GetPaddedCollisionRadius()
		end

		--Missing: Setting target facing angle
		local vVelocity = self.vStartPosition - vHookPos --caster:GetAbsOrigin() - vHookPos
		vVelocity.z = 0.0

		local flDistance = vVelocity:Length2D() - flPad
		vVelocity = vVelocity:Normalized() * self.hook_speed

		-- Invisible projectile going backwards - hook retracting
		local info = {
			Ability = self,
			vSpawnOrigin = vHookPos,
			vVelocity = vVelocity,
			fDistance = flDistance,
			Source = caster,
		}

		ProjectileManager:CreateLinearProjectile( info )
		self.vProjectileLocation = vHookPos

		if hTarget and ( not hTarget:IsInvisible() ) and bTargetPulled then
			ParticleManager:SetParticleControlEnt( self.nChainParticleFXIndex, 1, hTarget, PATTACH_POINT_FOLLOW, "attach_hitloc", hTarget:GetOrigin() + self.vHookOffset, true )
			ParticleManager:SetParticleControl( self.nChainParticleFXIndex, 4, Vector( 0, 0, 0 ) )
			ParticleManager:SetParticleControl( self.nChainParticleFXIndex, 5, Vector( 1, 0, 0 ) )

			hTarget:EmitSound("Hero_Pudge.AttackHookRetract")
		else
			ParticleManager:SetParticleControlEnt( self.nChainParticleFXIndex, 1, caster, PATTACH_POINT_FOLLOW, "attach_weapon_chain_rt", caster:GetOrigin() + self.vHookOffset, true);
		end

		if caster:IsAlive() then
			caster:RemoveGesture( ACT_DOTA_OVERRIDE_ABILITY_1 );
			caster:StartGesture( ACT_DOTA_CHANNEL_ABILITY_1 );
		end

		self.bRetracting = true
	else
		-- Hook is retracting
		-- hit unit is either the already hit unit or a unit near the hit unit while the hook is retracting
		local hHook = caster:GetTogglableWearable( DOTA_LOADOUT_TYPE_WEAPON )
		if hHook then
			hHook:RemoveEffects( EF_NODRAW )
		end

		if self.hVictim then
			local vFinalHookPos = vLocation
			self.hVictim:InterruptMotionControllers( true )
			--self.hVictim:RemoveModifierByName("modifier_pudge_custom_meat_hook")

			local vVictimPosCheck = self.hVictim:GetOrigin() - vFinalHookPos
			local flPad = caster:GetPaddedCollisionRadius() + self.hVictim:GetPaddedCollisionRadius()
			if vVictimPosCheck:Length2D() > flPad then
				FindClearSpaceForUnit( self.hVictim, self.vStartPosition, false )
				--FindClearSpaceForUnit( self.hVictim, caster:GetAbsOrigin(), false )
			end
		end

		self.hVictim = nil
		ParticleManager:DestroyParticle( self.nChainParticleFXIndex, true )
		caster:EmitSound("Hero_Pudge.AttackHookRetractStop")
	end

	return true
end

function pudge_custom_meat_hook:OnProjectileThink( vLocation )
	self.vProjectileLocation = vLocation
end

function pudge_custom_meat_hook:OnOwnerDied()
	local caster = self:GetCaster()
	caster:RemoveGesture( ACT_DOTA_OVERRIDE_ABILITY_1 )
	caster:RemoveGesture( ACT_DOTA_CHANNEL_ABILITY_1 )
end

---------------------------------------------------------------------------------------------------

modifier_pudge_custom_meat_hook = class({})

function modifier_pudge_custom_meat_hook:IsDebuff()
	return true
end

function modifier_pudge_custom_meat_hook:IsStunDebuff()
	return true
end

function modifier_pudge_custom_meat_hook:RemoveOnDeath()
	return false
end

function modifier_pudge_custom_meat_hook:GetPriority()
  return DOTA_MOTION_CONTROLLER_PRIORITY_HIGHEST
end

function modifier_pudge_custom_meat_hook:OnCreated(event)
	if IsServer() then
		if self:ApplyHorizontalMotionController() == false then
			self:Destroy()
		end
	end
end

function modifier_pudge_custom_meat_hook:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
	}
end

function modifier_pudge_custom_meat_hook:GetOverrideAnimation()
	return ACT_DOTA_FLAIL
end

function modifier_pudge_custom_meat_hook:CheckState()
	local caster = self:GetCaster()
	local parent = self:GetParent()
	local state = {
		[MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true
	}

	-- Stun only enemies that are not spell immune
	if caster:GetTeamNumber() ~= parent:GetTeamNumber() and (not parent:IsMagicImmune()) then
		state[MODIFIER_STATE_STUNNED] = true
	end

	return state
end

if IsServer() then
	function modifier_pudge_custom_meat_hook:UpdateHorizontalMotion( me, dt )
		local caster = self:GetCaster()
		local ability = self:GetAbility()
		if ability.hVictim then
			ability.hVictim:SetOrigin( ability.vProjectileLocation )
			local vToCaster = ability.vStartPosition - caster:GetOrigin()
			local flDist = vToCaster:Length2D()
			if ability.bChainAttached == false and flDist > 128.0 then
				ability.bChainAttached = true
				ParticleManager:SetParticleControlEnt( ability.nChainParticleFXIndex, 0, caster, PATTACH_CUSTOMORIGIN, "attach_hitloc", caster:GetOrigin(), true )
				ParticleManager:SetParticleControl( ability.nChainParticleFXIndex, 0, ability.vStartPosition + ability.vHookOffset )
			end
		end
	end

	function modifier_pudge_custom_meat_hook:OnHorizontalMotionInterrupted()
		--if self:GetAbility().hVictim then
			ParticleManager:SetParticleControlEnt( self:GetAbility().nChainParticleFXIndex, 1, self:GetCaster(), PATTACH_POINT_FOLLOW, "attach_weapon_chain_rt", self:GetCaster():GetAbsOrigin() + self:GetAbility().vHookOffset, true )
			self:Destroy()
		--end
	end

	function modifier_pudge_custom_meat_hook:OnDestroy()
		local parent = self:GetParent()
		if parent and not parent:IsNull() then
			parent:RemoveHorizontalMotionController(self)
			--local parent_origin = parent:GetAbsOrigin()
			--FindClearSpaceForUnit(parent, parent_origin, false)
			--ResolveNPCPositions(parent_origin, 128)
		end
	end
end

---------------------------------------------------------------------------------------------------

modifier_pudge_meat_hook_followthrough_lua = class({})

function modifier_pudge_meat_hook_followthrough_lua:IsHidden()
	return true
end

function modifier_pudge_meat_hook_followthrough_lua:CheckState()
	return {
		[MODIFIER_STATE_STUNNED] = true,
	}
end
