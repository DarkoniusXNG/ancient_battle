-- "OnSpellStart"
-- {
	-- "FireSound"
	-- {
		-- "EffectName"	"Hero_Antimage.Blink_out"
		-- "Target"		"CASTER"
	-- }
	
	-- "RunScript"
	-- {
		-- "ScriptFile"	"heroes/ryu/blink_strike.lua"
		-- "Function"		"Blink"
		-- "Target"		"POINT"
	-- }
-- }

-- Called OnSpellStart
-- Blinks the target to the target point
function Blink(keys)
	local point = keys.target_points[1]
	local caster = keys.caster

	-- Start Particle
	local blink_start_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_antimage/antimage_blink_start.vpcf", PATTACH_ABSORIGIN, caster)
	Timers:CreateTimer(1.0, function()
		ParticleManager:DestroyParticle(blink_start_particle, false)
		ParticleManager:ReleaseParticleIndex(blink_start_particle)
	end)

	-- Teleporting caster and preventing getting stuck
	FindClearSpaceForUnit(caster, point, false)

	-- Disjoint disjointable/dodgeable projectiles
	ProjectileManager:ProjectileDodge(caster)

	-- End Particle
	local blink_end_particle = ParticleManager:CreateParticle("particles/items_fx/blink_dagger_end.vpcf", PATTACH_ABSORIGIN, caster)
	ParticleManager:ReleaseParticleIndex(blink_end_particle)

	-- Sound
	caster:EmitSound("Hero_Antimage.Blink_in")
end
