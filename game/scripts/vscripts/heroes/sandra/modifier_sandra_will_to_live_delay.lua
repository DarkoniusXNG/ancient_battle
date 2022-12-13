modifier_sandra_will_to_live_delay = class({})

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
		self.flags = kv.flags
		self.flags = self:FlagAdd( self.flags, DOTA_DAMAGE_FLAG_BYPASSES_BLOCK )
		self.flags = self:FlagAdd( self.flags, DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS )
		self.flags = self:FlagAdd( self.flags, DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION )
		self.flags = self:FlagAdd( self.flags, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL )
		self.flags = self:FlagAdd( self.flags, DOTA_DAMAGE_FLAG_REFLECTION )

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
		flags = self:FlagAdd( flags, DOTA_DAMAGE_FLAG_NON_LETHAL )

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

--------------------------------------------------------------------------------
-- Helper: Flag operations
function modifier_sandra_will_to_live_delay:FlagExist(a,b)--Bitwise Exist
	local p,c,d=1,0,b
	while a>0 and b>0 do
		local ra,rb=a%2,b%2
		if ra+rb>1 then c=c+p end
		a,b,p=(a-ra)/2,(b-rb)/2,p*2
	end
	return c==d
end

function modifier_sandra_will_to_live_delay:FlagAdd(a,b)--Bitwise and
	if self:FlagExist(a,b) then
		return a
	else
		return a+b
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