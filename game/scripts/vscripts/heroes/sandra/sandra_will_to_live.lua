sandra_will_to_live = class({})

LinkLuaModifier( "modifier_sandra_will_to_live", "heroes/sandra/sandra_will_to_live", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_sandra_will_to_live_delay", "heroes/sandra/sandra_will_to_live", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_sandra_will_to_live_threshold", "heroes/sandra/sandra_will_to_live", LUA_MODIFIER_MOTION_NONE )

function sandra_will_to_live:GetIntrinsicModifierName()
	return "modifier_sandra_will_to_live"
end

---------------------------------------------------------------------------------------------------

modifier_sandra_will_to_live = class({})

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

function modifier_sandra_will_to_live:IsHidden()
	return false
end

function modifier_sandra_will_to_live:IsDebuff()
	return false
end

function modifier_sandra_will_to_live:IsPurgable()
	return false
end

function modifier_sandra_will_to_live:OnCreated( kv )
	-- references
	self.delay = self:GetAbility():GetSpecialValueFor( "damage_delay" )
	self.threshold_base = self:GetAbility():GetSpecialValueFor( "threshold_base" )
	self.threshold_stack = self:GetAbility():GetSpecialValueFor( "threshold_stack" )
	self.threshold_stack_creep = self:GetAbility():GetSpecialValueFor( "threshold_stack_creep" )
	self.stack_duration = self:GetAbility():GetSpecialValueFor( "stack_duration" )

	self.bonus_stack = 0

	if IsServer() then
		self:SetStackCount( self.threshold_base )
	end
end

function modifier_sandra_will_to_live:OnRefresh( kv )
	-- references
	self.delay = self:GetAbility():GetSpecialValueFor( "damage_delay" )
	self.threshold_base = self:GetAbility():GetSpecialValueFor( "threshold_base" )
	self.threshold_stack = self:GetAbility():GetSpecialValueFor( "threshold_stack" )
	self.threshold_stack_creep = self:GetAbility():GetSpecialValueFor( "threshold_stack_creep" )
	self.stack_duration = self:GetAbility():GetSpecialValueFor( "stack_duration" )

	if IsServer() then
		self:SetStackCount( self.threshold_base + self.bonus_stack )
	end
end

function modifier_sandra_will_to_live:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_TAKEDAMAGE,
		MODIFIER_PROPERTY_MIN_HEALTH,
	}
end

function modifier_sandra_will_to_live:GetMinHealth()
	if IsServer() then
		self.currentHealth = self:GetParent():GetHealth()
	end
end

function modifier_sandra_will_to_live:OnTakeDamage( params )
	if IsServer() then
		if params.unit~=self:GetParent() or params.inflictor==self:GetAbility() then
			return
		end

		-- cancel if break
		if self:GetParent():PassivesDisabled() and (not self:GetParent():HasScepter()) then
			return
		end

		-- cover up damage
		self:GetParent():SetHealth( self.currentHealth )

		-- add delay damage if bigger than base threshold
		if params.damage > self.threshold_base then
			local attacker = tempTable:AddATValue( params.attacker )
			local modifier = tempTable:AddATValue( self )
			self:GetParent():AddNewModifier(
				self:GetParent(), -- player source
				self:GetAbility(), -- ability source
				"modifier_sandra_will_to_live_delay", -- modifier name
				{
					damage = params.damage,
					source = attacker,
					flags = params.damage_flags,
					modifier = modifier,
				} -- kv
			)
		end

		-- add threshold stack
		if params.attacker:GetTeamNumber()~=self:GetParent():GetTeamNumber() then
			local stack = self.threshold_stack
			if params.attacker:IsCreep() then
				stack = self.threshold_stack_creep
			end
			self:AddStack( stack )
		end

		-- effects
		self:PlayEffects( params.attacker )
	end
end

function modifier_sandra_will_to_live:AddStack( value )
	-- increment stack
	self.bonus_stack = self.bonus_stack + value
	self:SetStackCount( self.threshold_base + self.bonus_stack )

	-- add stack modifier
	local modifier = tempTable:AddATValue( self )
	self:GetParent():AddNewModifier(
		self:GetParent(), -- player source
		self:GetAbility(), -- ability source
		"modifier_sandra_will_to_live_threshold", -- modifier name
		{
			duration = self.stack_duration,
			modifier = modifier,
			stack = value,
		} -- kv
	)
end

function modifier_sandra_will_to_live:RemoveStack( value )
	-- decrement stack
	self.bonus_stack = self.bonus_stack - value
	self:SetStackCount( self.threshold_base + self.bonus_stack )
end

function modifier_sandra_will_to_live:PlayEffects( attacker )
	-- references
	local particle_cast = "particles/items_fx/backdoor_protection_tube.vpcf"

	-- load data
	local direction = (self:GetParent():GetOrigin()-attacker:GetOrigin()):Normalized()
	local size = 150

	-- effect
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
	ParticleManager:SetParticleControl( effect_cast, 1, Vector( size, 0, 0 ) )
	ParticleManager:SetParticleControlForward( effect_cast, 2, direction )
	ParticleManager:ReleaseParticleIndex( effect_cast )
end

---------------------------------------------------------------------------------------------------

modifier_sandra_will_to_live_delay = class({})

function modifier_sandra_will_to_live_delay:IsHidden()
	return true
end

function modifier_sandra_will_to_live_delay:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_sandra_will_to_live_delay:IsPurgable()
	return false
end

function modifier_sandra_will_to_live_delay:OnCreated( kv )
	-- references
	self.delay = self:GetAbility():GetSpecialValueFor( "damage_delay" )
	self.interval = 1

	-- Talent that decreases delay (special_bonus_unique_will_to_live_tick) - TODO

	if IsServer() then
		-- attacker
		self.attacker = tempTable:RetATValue( kv.source )

		-- flags
		self.flags = bit.bor(kv.flags, DOTA_DAMAGE_FLAG_BYPASSES_BLOCK, DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS, DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL, DOTA_DAMAGE_FLAG_REFLECTION)

		-- damage
		self.damage_left = kv.damage
		self.damage_tick = kv.damage * (self.delay/100)

		-- modifier
		self.modifier = tempTable:RetATValue( kv.modifier )

		-- Start interval
		self:StartIntervalThink( self.interval )
	end
end

function modifier_sandra_will_to_live_delay:OnIntervalThink()
	-- damage
	local damage = math.min( self.damage_tick, self.damage_left )

	-- check threshold
	local not_die = false
	local flags = self.flags
	if damage<=self.modifier:GetStackCount() then
		flags = bit.bor(flags, DOTA_DAMAGE_FLAG_NON_LETHAL)

		if damage>=self:GetParent():GetHealth() then
			not_die = true
		end
	end

	-- damage
	local damageTable = {
		victim = self:GetParent(),
		attacker = self.attacker,
		damage = damage,
		damage_type = DAMAGE_TYPE_PURE,
		ability = self:GetAbility(), --Optional.
		damage_flags = flags,
	}
	ApplyDamage(damageTable)

	-- effects
	self:PlayEffects( false )
	if not_die then
		self:PlayEffects( true )
	end

	-- diminish
	self.damage_left = self.damage_left - self.damage_tick
	if self.damage_left<=0 then
		self:Destroy()
	end
end

function modifier_sandra_will_to_live_delay:PlayEffects( bSurvive )
	local particle_cast
	local sound_cast = "DOTA_Item.Maim"
	local parent = self:GetParent()

	local effect_cast
	if bSurvive then
		particle_cast = "particles/units/heroes/hero_dazzle/dazzle_shallow_grave_glyph_flare.vpcf"
		effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_CENTER_FOLLOW, parent )
	else
		particle_cast = "particles/items2_fx/soul_ring_blood.vpcf"
		effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, parent )
	end

	ParticleManager:ReleaseParticleIndex(effect_cast)

	parent:EmitSound(sound_cast)
end

---------------------------------------------------------------------------------------------------

modifier_sandra_will_to_live_threshold = class({})

function modifier_sandra_will_to_live_threshold:IsHidden()
	return true
end

function modifier_sandra_will_to_live_threshold:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_sandra_will_to_live_threshold:IsPurgable()
	return false
end

function modifier_sandra_will_to_live_threshold:OnCreated( kv )
	if IsServer() then
		-- references
		self.modifier = tempTable:RetATValue( kv.modifier )
		self.stack = kv.stack
	end
end

function modifier_sandra_will_to_live_threshold:OnDestroy( kv )
	if IsServer() then
		-- references
		self.modifier:RemoveStack( self.stack )
	end
end

