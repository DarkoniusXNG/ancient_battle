oracle_sacrifice = class({})

LinkLuaModifier( "modifier_oracle_sacrifice", "heroes/oracle/oracle_sacrifice", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_oracle_sacrifice_master", "heroes/oracle/oracle_sacrifice", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_oracle_sacrifice_pull", "heroes/oracle/oracle_sacrifice", LUA_MODIFIER_MOTION_HORIZONTAL )

local tempTable = {}
tempTable.table = {}

function tempTable:GetATEmptyKey()
	local i = 1
	while self.table[i]~=nil do
		i = i+1
	end
	return i
end

function tempTable:AddATValue( value )
	local i = self:GetATEmptyKey()
	self.table[i] = value
	return i
end

function tempTable:RetATValue( key )
	local ret = self.table[key]
	self.table[key] = nil
	return ret
end

function tempTable:GetATValue( key )
	return self.table[key]
end

function tempTable:Print()
	for k,v in pairs(self.table) do
		print(k,v)
	end
end

function oracle_sacrifice:CastFilterResultTarget( hTarget )
	if self:GetCaster() == hTarget then
		return UF_FAIL_CUSTOM
	end

	local nResult = UnitFilter(
		hTarget,
		DOTA_UNIT_TARGET_TEAM_FRIENDLY,
		DOTA_UNIT_TARGET_HERO,
		0,
		self:GetCaster():GetTeamNumber()
	)
	if nResult ~= UF_SUCCESS then
		return nResult
	end

	return UF_SUCCESS
end

function oracle_sacrifice:GetCustomCastErrorTarget( hTarget )
	if self:GetCaster() == hTarget then
		return "#dota_hud_error_cant_cast_on_self"
	end

	return ""
end

function oracle_sacrifice:OnSpellStart()
	-- unit identifier
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	-- load data
	local duration = self:GetSpecialValueFor("leash_duration")

	-- destroy previous cast
	local modifier = caster:FindModifierByNameAndCaster( "modifier_oracle_sacrifice", caster )
	if modifier then
		modifier:Destroy()
	end

	-- add slave modifier
	local master = tempTable:AddATValue( target )
	caster:AddNewModifier(
		caster, -- player source
		self, -- ability source
		"modifier_oracle_sacrifice", -- modifier name
		{
			duration = duration,
			master = master,
		} -- kv
	)
end

---------------------------------------------------------------------------------------------------

modifier_oracle_sacrifice = class({})

function modifier_oracle_sacrifice:IsHidden()
	return false
end

function modifier_oracle_sacrifice:IsDebuff()
	return false
end

function modifier_oracle_sacrifice:IsPurgable()
	return false
end

function modifier_oracle_sacrifice:OnCreated( kv )
	if IsServer() then
		-- references
		local master = tempTable:RetATValue( kv.master )
		self.leash_radius = self:GetAbility():GetSpecialValueFor("leash_radius")
		self.buffer_length = self:GetAbility():GetSpecialValueFor("leash_buffer")
		self.ms_bonus = self:GetAbility():GetSpecialValueFor("ms_bonus")

		-- load data
		local interval = 0.1
		self.normal_ms_limit = 550
		self.dragged = false
		self.buffer_radius = self.leash_radius - self.buffer_length

		-- create master's modifier
		local modifier = tempTable:AddATValue( self )
		self.master = master:AddNewModifier(
			self:GetParent(), -- player source
			self:GetAbility(), -- ability source
			"modifier_oracle_sacrifice_master", -- modifier name
			{
				duration = kv.duration,
				modifier = modifier,
			} -- kv
		)

		-- Start interval
		self:StartIntervalThink( interval )

		-- effects
		self:PlayEffects()
	end
end

function modifier_oracle_sacrifice:OnDestroy( kv )
	if IsServer() then
		if not self.master:IsNull() then
			self.master:Destroy()
		end
	end
end

function modifier_oracle_sacrifice:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_MOVESPEED_LIMIT,
	}
end

function modifier_oracle_sacrifice:GetModifierMoveSpeedBonus_Constant()
	return self.ms_bonus
end

function modifier_oracle_sacrifice:GetModifierMoveSpeed_Limit()
	if IsServer() then
		-- zero is no limit
		return self.limit
	end
end

function modifier_oracle_sacrifice:OnIntervalThink()
	if IsServer() then
		-- if dragged, just pass
		if not self.dragged then
			-- get info
			local vectorToMaster = self.master:GetParent():GetOrigin() - self:GetParent():GetOrigin()

			-- calculate facing angle
			local angleToMaster = VectorToAngles(vectorToMaster).y
			local slaveFacingAngle = self:GetParent():GetAnglesAsVector().y
			local angleDifference = math.abs(slaveFacingAngle - angleToMaster)
			if angleDifference > 180 then
				angleDifference = math.abs(angleDifference - 360)
			end

			-- calculate distance
			local distanceToMaster = vectorToMaster:Length2D()

			-- check if it is within boundaries
			if distanceToMaster < self.buffer_radius then
				-- within limit
				self.limit = self.normal_ms_limit
			elseif distanceToMaster < self.leash_radius + 0.1*self.buffer_length then
				-- about to be slowed. true limit is maximum + 0.1 * buffer length
				if angleDifference > 90 then
					self.limit = (1-(distanceToMaster-self.buffer_radius)/self.buffer_length) * self.normal_ms_limit
					if self.limit < 1 then
						self.limit = 0.01
					end
				else
					self.limit = self.normal_ms_limit
				end
			else
				-- outside, dragged
				local modifier = tempTable:AddATValue( self )
				self:GetParent():AddNewModifier(
					self:GetParent(), -- player source
					self:GetAbility(), -- ability source
					"modifier_oracle_sacrifice_pull", -- modifier name
					{ modifier = modifier } -- kv
				)
				self.dragged = true
			end
		end
	end
end

function modifier_oracle_sacrifice:PlayEffects()
	-- Get Resources
	local particle_cast = "particles/units/heroes/hero_puck/puck_dreamcoil_tether.vpcf"

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_POINT_FOLLOW, self:GetParent() )

	local attach
	if self.master:GetParent():ScriptLookupAttachment( "attach_attack2" )~=0 then
		attach = "attach_attack2"
	elseif self.master:GetParent():ScriptLookupAttachment( "attach_attack1" )~=0 then
		attach = "attach_attack1"
	else
		attach = "attach_hitloc"
	end
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		0,
		self.master:GetParent(),
		PATTACH_POINT_FOLLOW,
		attach,
		self.master:GetParent():GetOrigin(), -- unknown
		true -- unknown, true
	)
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		1,
		self:GetParent(),
		PATTACH_POINT_FOLLOW,
		"attach_hitloc",
		self:GetParent():GetOrigin(), -- unknown
		true -- unknown, true
	)

	-- buff particle
	self:AddParticle(
		effect_cast,
		false,
		false,
		-1,
		false,
		false
	)
end

---------------------------------------------------------------------------------------------------

modifier_oracle_sacrifice_master = class({})

function modifier_oracle_sacrifice_master:IsHidden()
	return false
end

function modifier_oracle_sacrifice_master:IsDebuff()
	return false
end

function modifier_oracle_sacrifice_master:IsPurgable()
	return false
end

function modifier_oracle_sacrifice_master:OnCreated( kv )
	if IsServer() then
		self.slave = tempTable:RetATValue( kv.modifier )
		--self:PlayEffects()
	end
end

function modifier_oracle_sacrifice_master:OnDestroy( kv )
	if IsServer() then
		if not self.slave:IsNull() then
			self.slave:Destroy()
		end
	end
end

function modifier_oracle_sacrifice_master:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MIN_HEALTH,
		MODIFIER_EVENT_ON_TAKEDAMAGE,
		MODIFIER_EVENT_ON_ABILITY_EXECUTED,
	}
end

if IsServer() then
	function modifier_oracle_sacrifice_master:GetMinHealth()
		self.currentHealth = self:GetParent():GetHealth()
	end

	function modifier_oracle_sacrifice_master:OnTakeDamage( params )
		if params.unit~=self:GetParent() then
			return
		end

		-- cover up damage
		self:GetParent():SetHealth( self.currentHealth )

		local flags = bit.bor(params.damage_flags, DOTA_DAMAGE_FLAG_BYPASSES_BLOCK, DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS, DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL, DOTA_DAMAGE_FLAG_REFLECTION)

		-- damage slave
		local damageTable = {
			victim = self.slave:GetParent(),
			attacker = params.attacker,
			damage = params.damage,
			damage_type = DAMAGE_TYPE_PURE,
			ability = self:GetAbility(),
			damage_flags = flags,
		}
		ApplyDamage(damageTable)

		-- effects
		self:PlayEffects1()
	end

	function modifier_oracle_sacrifice_master:OnAbilityExecuted( params )
		if (not params.target) or params.target~=self:GetParent() or params.unit:GetTeamNumber()==self:GetParent():GetTeamNumber() then
			return
		end

		-- redirect
		params.unit:SetCursorCastTarget( self.slave:GetParent() )

		-- effects
		self:PlayEffects1()
		self:PlayEffects2()
	end
end

function modifier_oracle_sacrifice_master:PlayEffects()
	local particle_cast = 

	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		0,
		self:GetParent(),
		PATTACH_POINT_FOLLOW,
		"attach_hitloc",
		self:GetParent():GetOrigin(), -- unknown
		true -- unknown, true
	)
	ParticleManager:SetParticleControl( effect_cast, 2, Vector(0,255,0) )
	self:AddParticle(
		effect_cast,
		false,
		false,
		-1,
		false,
		false
	)
end

function modifier_oracle_sacrifice_master:PlayEffects1()
	-- Get Resources
	local particle_cast = "particles/units/heroes/hero_juggernaut/juggernaut_omni_slash_rope.vpcf"
	local sound_cast = "DOTA_Item.BladeMail.Damage"

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		2,
		self:GetParent(),
		PATTACH_POINT_FOLLOW,
		"attach_attack2",
		self:GetParent():GetOrigin(), -- unknown
		true -- unknown, true
	)
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		3,
		self.slave:GetParent(),
		PATTACH_POINT_FOLLOW,
		"attach_hitloc",
		self.slave:GetParent():GetOrigin(), -- unknown
		true -- unknown, true
	)
	ParticleManager:ReleaseParticleIndex( effect_cast )

	-- sound
	EmitSoundOnClient( sound_cast, self.slave:GetParent():GetPlayerOwner() )
end

function modifier_oracle_sacrifice_master:PlayEffects2()
	local parent = self:GetParent()
	local particle_cast = "particles/items4_fx/combo_breaker_spell_burst.vpcf"
	local sound_cast = "Item.LotusOrb.Target"

	-- Get data
	local effect_constant = 100
	local direction = (self.slave:GetParent():GetOrigin()-parent:GetOrigin()):Normalized() * effect_constant

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle(particle_cast, PATTACH_WORLDORIGIN, parent)
	ParticleManager:SetParticleControl( effect_cast, 0, parent:GetOrigin() + Vector( 0, 0, 90 ) - direction*1 )
	ParticleManager:SetParticleControl( effect_cast, 1, parent:GetOrigin() + Vector( 0, 0, 90 ) + direction*0 )
	ParticleManager:ReleaseParticleIndex( effect_cast )

	parent:EmitSound(sound_cast)
end

---------------------------------------------------------------------------------------------------

modifier_oracle_sacrifice_pull = class({})

function modifier_oracle_sacrifice_pull:IsHidden()
	return false
end

function modifier_oracle_sacrifice_pull:IsDebuff()
	return true
end

function modifier_oracle_sacrifice_pull:IsPurgable()
	return false
end

function modifier_oracle_sacrifice_pull:SetPriority()
	return DOTA_MOTION_CONTROLLER_PRIORITY_HIGH
end

function modifier_oracle_sacrifice_pull:OnCreated( kv )
	if IsServer() then
		-- get reference
		self.modifier = tempTable:RetATValue( kv.modifier )
		self.master = self.modifier.master:GetParent()
		self.minimum_radius = self.modifier.buffer_radius

		-- try apply
		if self:ApplyHorizontalMotionController() == false then
			self:Destroy()
		end
	end
end

function modifier_oracle_sacrifice_pull:OnDestroy( kv )
	if IsServer() then
		self.modifier.dragged = false

		self:GetParent():RemoveHorizontalMotionController(self)
	end
end

function modifier_oracle_sacrifice_pull:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
	}
end

function modifier_oracle_sacrifice_pull:GetOverrideAnimation()
	return ACT_DOTA_FLAIL
end

function modifier_oracle_sacrifice_pull:CheckState()
	return {
		[MODIFIER_STATE_COMMAND_RESTRICTED] = true,
	}
end

function modifier_oracle_sacrifice_pull:UpdateHorizontalMotion( me, dt )
	if IsServer() then
		-- get pull direction
		local masterVec = self.master:GetOrigin() - self:GetParent():GetOrigin()
		local direction = masterVec:Normalized()
		local distance = masterVec:Length2D()

		-- pull acceleration and speed
		local accel = 0.1*(distance - self.minimum_radius)/10 + 0.9
		local speed = self.master:GetIdealSpeed()

		-- set next pos
		local nextPos = self:GetParent():GetOrigin() + direction*speed*accel*dt
		self:GetParent():SetOrigin( nextPos )

		-- set facing
		-- this interrupts, therefore unused.
		-- self:GetParent():SetForwardVector(-direction)

		-- if reached minimum, destroy
		if distance < self.minimum_radius then
			self:Destroy()
		end
	end
end

function modifier_oracle_sacrifice_pull:OnHorizontalMotionInterrupted()
	if IsServer() then
		self:Destroy()
	end
end

function modifier_oracle_sacrifice_pull:GetEffectName()
	return "particles/generic_gameplay/generic_stunned.vpcf"
end

function modifier_oracle_sacrifice_pull:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end
