sandra_ironical_healing = class({})
LinkLuaModifier( "modifier_sandra_ironical_healing", "heroes/sandra/modifier_sandra_ironical_healing", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------
-- Ability Start
function sandra_ironical_healing:OnSpellStart()
	-- unit identifier
	local caster = self:GetCaster()

	-- load data
	local base_damage = self:GetSpecialValueFor("base_damage")
	local damage_pct = self:GetSpecialValueFor("damage_pct")
	local duration = self:GetSpecialValueFor("duration")

	-- Talent that decreases duration (special_bonus_unique_ironical_healing_duration) TODO

	-- calculate damage
	local total_damage = base_damage + (damage_pct/100)*caster:GetMaxHealth()

	-- self damage
	damageTable = {
		victim = caster,
		attacker = caster,
		damage = total_damage,
		damage_type = DAMAGE_TYPE_PURE,
		ability = self, --Optional.
		damage_flags = DOTA_DAMAGE_FLAG_NON_LETHAL,
	}
	ApplyDamage(damageTable)

	-- health regen
	local modifier = caster:AddNewModifier(
		caster, -- player source
		self, -- ability source
		"modifier_sandra_ironical_healing", -- modifier name
		{
			duration = duration,
			damage = total_damage
		} -- kv
	)

	-- Effects
	self:PlayEffects()
end

function sandra_ironical_healing:PlayEffects()
	local particle_cast = "particles/units/heroes/hero_phantom_assassin/phantom_assassin_crit_impact.vpcf"
	local sound_cast = "Hero_PhantomAssassin.CoupDeGrace"

	local caster = self:GetCaster()

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, caster )
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		0,
		caster,
		PATTACH_POINT_FOLLOW,
		"attach_hitloc",
		caster:GetOrigin(), -- unknown
		true -- unknown, true
	)
	ParticleManager:SetParticleControl( effect_cast, 1, caster:GetOrigin() )
	ParticleManager:SetParticleControlForward( effect_cast, 1, -caster:GetForwardVector() )
	ParticleManager:ReleaseParticleIndex( effect_cast )

	-- Create Sound
	caster:EmitSound(sound_cast)
end
