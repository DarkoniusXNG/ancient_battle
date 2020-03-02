dark_terminator_blink = class({})

function dark_terminator_blink:OnSpellStart()
	local caster = self:GetCaster()
	local target_loc = self:GetCursorPosition()

	-- Start Sound
	caster:EmitSound("Hero_Antimage.Blink_out")

	-- Start Particle
	local blink_start_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_antimage/antimage_blink_start.vpcf", PATTACH_ABSORIGIN, caster)
	Timers:CreateTimer(1.0, function()
		ParticleManager:DestroyParticle(blink_start_particle, false)
		ParticleManager:ReleaseParticleIndex(blink_start_particle)
	end)

	-- Teleporting caster and preventing getting stuck
	FindClearSpaceForUnit(caster, target_loc, false)

	-- Disjoint disjointable/dodgeable projectiles
	ProjectileManager:ProjectileDodge(caster)

	-- End Particle
	local blink_end_particle = ParticleManager:CreateParticle("particles/items_fx/blink_dagger_end.vpcf", PATTACH_ABSORIGIN, caster)
	ParticleManager:ReleaseParticleIndex(blink_end_particle)

	-- End Sound
	caster:EmitSound("Hero_Antimage.Blink_in")
end
