oracle_sacrifice = class({})

LinkLuaModifier( "modifier_oracle_sacrifice", "heroes/oracle/oracle_sacrifice.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_oracle_sacrifice_master", "heroes/oracle/oracle_sacrifice.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_oracle_sacrifice_pull", "heroes/oracle/oracle_sacrifice.lua", LUA_MODIFIER_MOTION_HORIZONTAL )

function oracle_sacrifice:CastFilterResultTarget(target)
	local caster = self:GetCaster()
	local default_result = self.BaseClass.CastFilterResultTarget(self, target)

	if target == caster or target:IsHeroDominatedCustom() then
		return UF_FAIL_CUSTOM
	end

	return default_result
end

function oracle_sacrifice:GetCustomCastErrorTarget(target)
	if self:GetCaster() == target then
		return "#dota_hud_error_cant_cast_on_self"
	end
	if target:IsHeroDominatedCustom() then
		return "Can't Target Dominated Heroes!"
	end
	return ""
end

function oracle_sacrifice:OnSpellStart()
	-- unit identifier
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	-- Strong dispel
	local RemovePositiveBuffs = false
	local RemoveDebuffs = true
	local BuffsCreatedThisFrameOnly = false
	local RemoveStuns = true
	local RemoveExceptions = true
	caster:Purge(RemovePositiveBuffs, RemoveDebuffs, BuffsCreatedThisFrameOnly, RemoveStuns, RemoveExceptions)

	-- load data
	local duration = self:GetSpecialValueFor("leash_duration")

	-- destroy previous cast
	local modifier = caster:FindModifierByNameAndCaster( "modifier_oracle_sacrifice", caster )
	if modifier then
		modifier:Destroy()
	end

	-- add slave modifier
	caster:AddNewModifier(caster, self, "modifier_oracle_sacrifice", {duration = duration, master = target:GetEntityIndex()})
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
	local ability = self:GetAbility()
	if not ability or ability:IsNull() then
		return
	end

	self.ms_bonus = ability:GetSpecialValueFor("ms_bonus")

	if IsServer() then
		-- references
		local slave = self:GetParent()
		local master = EntIndexToHScript(kv.master)
		self.leash_radius = ability:GetSpecialValueFor("leash_radius")
		self.buffer_length = ability:GetSpecialValueFor("leash_buffer")

		-- load data
		local interval = 0.1
		self.normal_ms_limit = 550
		self.dragged = false
		self.buffer_radius = self.leash_radius - self.buffer_length

		-- create master's modifier
		local master_modifier = master:AddNewModifier(slave, ability, "modifier_oracle_sacrifice_master", {duration = kv.duration})
		master_modifier.slave = self

		self.master = master_modifier

		-- Start interval
		self:StartIntervalThink( interval )

		-- Get Resources
		local particle_cast = "particles/units/heroes/hero_puck/puck_dreamcoil_tether.vpcf"

		-- Create Particle
		local effect_cast = ParticleManager:CreateParticle(particle_cast, PATTACH_POINT_FOLLOW, slave)

		local attach
		if master:ScriptLookupAttachment("attach_attack2") ~= 0 then
			attach = "attach_attack2"
		elseif master:ScriptLookupAttachment("attach_attack1") ~= 0 then
			attach = "attach_attack1"
		else
			attach = "attach_hitloc"
		end
		ParticleManager:SetParticleControlEnt(effect_cast, 0, master, PATTACH_POINT_FOLLOW, attach, master:GetOrigin(), true)
		ParticleManager:SetParticleControlEnt(effect_cast, 1, slave, PATTACH_POINT_FOLLOW, "attach_hitloc", slave:GetOrigin(), true)

		-- buff particle
		self:AddParticle(effect_cast, false, false, -1, false, false)
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
				local pull_modifier = self:GetParent():AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_oracle_sacrifice_pull",{})
				pull_modifier.modifier = self
				pull_modifier.master = self.master:GetParent()
				pull_modifier.minimum_radius = self.buffer_radius
				self.dragged = true
			end
		end
	end
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
		MODIFIER_EVENT_ON_HEALTH_GAINED,
	}
end

if IsServer() then
	function modifier_oracle_sacrifice_master:GetMinHealth()
		self.currentHealth = self:GetParent():GetHealth()
	end

	function modifier_oracle_sacrifice_master:OnTakeDamage(event)
		local parent = self:GetParent()
		local attacker = event.attacker
		local damaged_unit = event.unit

		-- Check if attacker exists
		if not attacker or attacker:IsNull() then
			return
		end

		-- Check if damaged entity exists
		if not damaged_unit or damaged_unit:IsNull() then
			return
		end

		-- Check if damaged_unit has this modifier
		if damaged_unit ~= parent then
			return
		end

		-- Negate damage - I don't like this but whatever
		parent:SetHealth( self.currentHealth )

		local flags = bit.bor(event.damage_flags, DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL, DOTA_DAMAGE_FLAG_REFLECTION)
		local slave = self.slave:GetParent() or self:GetCaster()

		-- Check if slave exists
		if not slave or slave:IsNull() then
			return
		end

		-- Damage the slave
		local damageTable = {
			victim = slave,
			attacker = attacker,
			damage = event.damage,
			damage_type = event.damage_type,
			ability = self:GetAbility(), -- event.inflictor
			damage_flags = flags,
		}
		ApplyDamage(damageTable)

		local particle_cast = "particles/units/heroes/hero_juggernaut/juggernaut_omni_slash_rope.vpcf"
		local sound_cast = "DOTA_Item.BladeMail.Damage"

		-- Particle
		local effect_cast = ParticleManager:CreateParticle(particle_cast, PATTACH_ABSORIGIN_FOLLOW, parent)
		local attach
		if parent:ScriptLookupAttachment("attach_attack2") ~= 0 then
			attach = "attach_attack2"
		elseif parent:ScriptLookupAttachment("attach_attack1") ~= 0 then
			attach = "attach_attack1"
		else
			attach = "attach_hitloc"
		end
		ParticleManager:SetParticleControlEnt(effect_cast, 2, parent, PATTACH_POINT_FOLLOW, attach, parent:GetOrigin(), true)
		ParticleManager:SetParticleControlEnt(effect_cast, 3, slave, PATTACH_POINT_FOLLOW, "attach_hitloc", slave:GetOrigin(), true)
		ParticleManager:ReleaseParticleIndex(effect_cast)

		-- Sound
		EmitSoundOnClient(sound_cast, slave:GetPlayerOwner())
	end

	function modifier_oracle_sacrifice_master:OnAbilityExecuted(event)
		local parent = self:GetParent()
		local casting_unit = event.unit
		local target = event.target

		-- Check if caster of the executed ability exists
		if not casting_unit or casting_unit:IsNull() then
			return
		end

		-- Check if target of the executed ability exists
		if not target or target:IsNull() then
			return
		end

		-- Check if target has this modifier
		if target ~= parent then
			return
		end

		-- Check if caster of the executed ability is an ally of the target
		if casting_unit:GetTeamNumber() == parent:GetTeamNumber() then
			return
		end

		local slave = self.slave:GetParent() or self:GetCaster()

		-- Check if slave exists
		if not slave or slave:IsNull() then
			return
		end

		-- Redirect to the slave (this method doesn't work for every unit target ability and item)
		casting_unit:SetCursorCastTarget(slave)

		local particle1 = "particles/units/heroes/hero_juggernaut/juggernaut_omni_slash_rope.vpcf"
		local particle2 = "particles/items4_fx/combo_breaker_spell_burst.vpcf"
		local sound_cast = "Item.LotusOrb.Target"

		-- First particle
		local effect1 = ParticleManager:CreateParticle(particle1, PATTACH_ABSORIGIN_FOLLOW, parent)
		local attach
		if parent:ScriptLookupAttachment("attach_attack2") ~= 0 then
			attach = "attach_attack2"
		elseif parent:ScriptLookupAttachment("attach_attack1") ~= 0 then
			attach = "attach_attack1"
		else
			attach = "attach_hitloc"
		end
		ParticleManager:SetParticleControlEnt(effect1, 2, parent, PATTACH_POINT_FOLLOW, attach, parent:GetOrigin(), true)
		ParticleManager:SetParticleControlEnt(effect1, 3, slave, PATTACH_POINT_FOLLOW, "attach_hitloc", slave:GetOrigin(), true)
		ParticleManager:ReleaseParticleIndex(effect1)

		local direction = (slave:GetOrigin() - parent:GetOrigin()):Normalized() * 100

		-- Second particle
		local effect2 = ParticleManager:CreateParticle(particle2, PATTACH_WORLDORIGIN, parent)
		ParticleManager:SetParticleControl(effect2, 0, parent:GetOrigin() + Vector( 0, 0, 90 ) - direction*1)
		ParticleManager:SetParticleControl(effect2, 1, parent:GetOrigin() + Vector( 0, 0, 90 ) + direction*0)
		ParticleManager:ReleaseParticleIndex(effect2)

		-- Sound
		parent:EmitSound(sound_cast)
	end

	function modifier_oracle_sacrifice_master:OnHealthGained(event)
		local unit = event.unit
		local gained_hp = event.gain or 0

		-- Check if unit exists
		if not unit or unit:IsNull() then
			return
		end

		-- Check if unit has this modifier
		if unit ~= self:GetParent() then
			return
		end

		-- Check if gained hp is > 0
		if gained_hp <= 0 then
			return
		end

		local slave = self.slave:GetParent() or self:GetCaster()

		-- Check if slave exists
		if not slave or slave:IsNull() then
			return
		end

		-- Share the heal with the slave
		slave:Heal(gained_hp, self:GetAbility())
	end
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
