dark_terminator_confuse = class({})

function dark_terminator_confuse:OnSpellStart()
	local caster = self:GetCaster()

	local incoming_damage = self:GetSpecialValueFor("incoming_damage")
	local outgoing_damage = self:GetSpecialValueFor("outgoing_damage")
	local number_of_illusions = self:GetSpecialValueFor("illusion_count")
	local duration = self:GetSpecialValueFor("illusion_duration")

	-- Talent that increases illusion damage:
	local talent_1 = caster:FindAbilityByName("special_bonus_unique_dark_terminator_confuse_illusion_damage")
	if talent_1 then
		if talent_1:GetLevel() ~= 0 then
			outgoing_damage = outgoing_damage + talent_1:GetSpecialValueFor("value")
		end
	end

	-- Talent that increases number of illusions:
	local talent_2 = caster:FindAbilityByName("special_bonus_unique_dark_terminator_confuse_extra_illusion")
	if talent_2 then
		if talent_2:GetLevel() ~= 0 then
			number_of_illusions = number_of_illusions + talent_2:GetSpecialValueFor("value")
		end
	end

	-- Sound
	caster:EmitSound("DOTA_Item.Manta.Activate")

	-- Particle
	local particle = ParticleManager:CreateParticle("particles/items2_fx/manta_phase.vpcf", PATTACH_ABSORIGIN, caster)
	Timers:CreateTimer(1.0, function()
		ParticleManager:DestroyParticle(particle, false)
		ParticleManager:ReleaseParticleIndex(particle)
	end)

	illusion_table = {}
	illusion_table.outgoing_damage = outgoing_damage
	illusion_table.incoming_damage = incoming_damage
	illusion_table.bounty_base = 0
	illusion_table.bounty_growth = 0
	illusion_table.outgoing_damage_structure = outgoing_damage
	illusion_table.duration = duration

	local padding = 108

	local illusions = CreateIllusions(caster, caster, illusion_table, number_of_illusions, padding, true, true)
end
