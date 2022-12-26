bakedanuki_tomfoolery_blink = class({})
bakedanuki_tomfoolery_summon = class({})
bakedanuki_tomfoolery_end = class({})

LinkLuaModifier( "modifier_bakedanuki_tomfoolery", "heroes/bakedanuki/modifier_bakedanuki_tomfoolery", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_bakedanuki_tomfoolery_hidden", "heroes/bakedanuki/modifier_bakedanuki_tomfoolery_hidden", LUA_MODIFIER_MOTION_NONE )

-- Shared data between 3 abilities
if tomfoolery==nil then
	tomfoolery = {}
	tomfoolery.onTrick = false
end

local init = function( ability )
	local caster = ability:GetCaster()

	-- Create tomfoolery variable
	local copy = {}
	for k,v in pairs(tomfoolery) do
		copy[k] = v
	end
	ability.tomfoolery = copy

	-- share the tomfoolery variable to the linked ability
	local ability_other = caster:FindAbilityByName( "bakedanuki_tomfoolery_blink" )
	if ability_other == ability then
		ability_other = caster:FindAbilityByName( "bakedanuki_tomfoolery_summon" )
	end
	ability_other.tomfoolery = copy

	-- initialize end ability
	local ability_end = caster:FindAbilityByName( "bakedanuki_tomfoolery_end" )
	ability_end:SetLevel( 1 )
	ability_end:SetActivated( false )
	ability_end.tomfoolery = copy

	ability.tomfoolery.ability1 = ability
	ability.tomfoolery.ability2 = ability_other
	ability.tomfoolery.endAblility = ability_end
end

---------------------------------------------------------------------------------------------------
-- Blink Ability
function bakedanuki_tomfoolery_blink:OnSpellStart()
	self.tomfoolery:OnSpellStart( self, true )

	-- shared cooldown
	--self:GetCaster():FindAbilityByName( self:GetSharedCooldownName() ):UseResources( false, false, true )
end

function bakedanuki_tomfoolery_blink:StopTrick()
	self.tomfoolery:StopTrick( self )
end

function bakedanuki_tomfoolery_blink:OnUpgrade()
	if self:GetLevel()==1 then
		if not self.tomfoolery then
			init( self )
		end
	end
end

function bakedanuki_tomfoolery_blink:GetCastAnimation()
	return ACT_DOTA_CAST_ABILITY_2
end

---------------------------------------------------------------------------------------------------
-- Summon Ability
function bakedanuki_tomfoolery_summon:OnSpellStart()
	self.tomfoolery:OnSpellStart( self, false )

	-- shared cooldown
	--self:GetCaster():FindAbilityByName( self:GetSharedCooldownName() ):UseResources( false, false, true )
end

function bakedanuki_tomfoolery_summon:StopTrick()
	self.tomfoolery:StopTrick( self )
end

function bakedanuki_tomfoolery_summon:OnUpgrade()
	if self:GetLevel()==1 then
		if not self.tomfoolery then
			init( self )
		end
	end
end

function bakedanuki_tomfoolery_summon:GetCastAnimation()
	return ACT_DOTA_CAST_ABILITY_2
end

---------------------------------------------------------------------------------------------------
-- End Ability
function bakedanuki_tomfoolery_end:OnSpellStart()
	self.tomfoolery:StopTrick( self )
end

---------------------------------------------------------------------------------------------------

function tomfoolery:OnSpellStart( this, bBlink )
	-- destroy previous cast
	if self.onTrick then
		self:StopTrick( this )
	end

	-- Unit identifier
	local caster = this:GetCaster()
	local point = this:GetCursorPosition()
	local origin = caster:GetOrigin()

	-- load data
	local max_range = this:GetSpecialValueFor("illusion_range")
	local illusion_outgoing = this:GetSpecialValueFor("illusion_outgoing")
	local illusion_incoming = this:GetSpecialValueFor("illusion_incoming") - 100
	local illusion_duration = this:GetSpecialValueFor("illusion_duration")
	local hidden_time = 0.1

	-- dodge projectile, dispel, and hidden for 0.1 sec
	caster:Purge( false, true, false, false, false )
	ProjectileManager:ProjectileDodge( caster )
	caster:AddNewModifier(
		caster,
		self,
		"modifier_bakedanuki_tomfoolery_hidden",
		{ duration = hidden_time }
	)

	-- determine positions
	local direction = (point - origin)
	if direction:Length2D() > max_range then
		direction = direction:Normalized() * max_range
	end
	local loc1 = origin
	local loc2 = origin + direction
	if bBlink then
		local temp = loc1
		loc1 = loc2
		loc2 = temp
	end

	-- set real hero position, add fooling modifier
	FindClearSpaceForUnit( caster, loc1, true )
	local modifier = caster:AddNewModifier(
		caster,
		this,
		"modifier_bakedanuki_tomfoolery",
		{ duration = illusion_duration }
	)

	-- Create illusion at position
	local illusion_table = {}
	illusion_table.outgoing_damage = illusion_outgoing
	illusion_table.incoming_damage = illusion_incoming
	illusion_table.bounty_base = 0
	illusion_table.bounty_growth = 0
	illusion_table.outgoing_damage_structure = illusion_outgoing
	illusion_table.outgoing_damage_roshan = illusion_outgoing
	illusion_table.duration = illusion_duration

	local illusions = CreateIllusions(caster, caster, illusion_table, 1, 108, false, true)
	for _, illu in pairs(illusions) do
		if illu then
			--illu:AddNewModifier(caster, self, "modifier_custom_strong_illusion", {})
			illu:AddNewModifier(caster, self, "modifier_bakedanuki_tomfoolery_hidden", {duration = hidden_time})
			FindClearSpaceForUnit(illu, loc2, true)
			self.illusion = illu
		end
	end

	-- Set shared data
	self.onTrick = true
	self.modifier = modifier
	self.currentHealth = caster:GetHealth()

	-- Set end active
	self.endAblility:SetActivated( true )

	-- Play effects
	self:PlayEffects( this, loc1, loc2 )
end

function tomfoolery:StopTrick( this )
	if not self.onTrick then
		return
	end

	self.onTrick = false
	self.modifier:Destroy()
	if self.illusion and not self.illusion:IsNull() and self.illusion:IsAlive() then
		self.illusion:ForceKill( false )
	end
	self.endAblility:SetActivated( false )

	this:GetCaster():SetHealth( self.currentHealth )
	this:GetCaster():Purge( false, true, false, true, true )

	-- Play effects
	self:StopEffects( this )
end

function tomfoolery:PlayEffects( this, loc1, loc2 )
	local sound_cast = "Hero_DarkWillow.Ley.Cast"
	local particle_cast = "particles/units/heroes/hero_dark_willow/dark_willow_leyconduit_marker.vpcf"

	local effect_cast1 = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, nil )
	ParticleManager:SetParticleControl( effect_cast1, 0, loc1 )
	ParticleManager:ReleaseParticleIndex( effect_cast1 )

	local effect_cast2 = ParticleManager:CreateParticle( particle_cast, PATTACH_WORLDORIGIN, nil )
	ParticleManager:SetParticleControl( effect_cast2, 0, loc2 )
	ParticleManager:ReleaseParticleIndex( effect_cast2 )

	EmitSoundOnLocationWithCaster( loc1, sound_cast, this:GetCaster() )
	EmitSoundOnLocationWithCaster( loc2, sound_cast, this:GetCaster() )
end

function tomfoolery:StopEffects(this)
	local caster = this:GetCaster()
	local sound_cast = "General.Illusion.Destroy"
	local particle_cast = "particles/generic_gameplay/illusion_killed.vpcf"

	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN, caster )
	ParticleManager:ReleaseParticleIndex( effect_cast )

	caster:EmitSound(sound_cast)
end
