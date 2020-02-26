-- Aghanim Scepter Upgrade.
function VolcanoKnockback(event)
	local caster = event.caster
	local targets = event.target_entities
	local ability = event.ability
	local volcano = event.target

	local radius = ability:GetLevelSpecialValueFor("radius", ability:GetLevel() - 1)

	local volcano_center_location = volcano:GetAbsOrigin()

	for _,unit in pairs(targets) do
		local unit_location = unit:GetAbsOrigin()
		-- Set the knockback origin in front of the unit
		local knockback_origin = unit_location + (unit_location - volcano_center_location):Normalized() * 100
		local knockbackModifierTable =
		{
			should_stun = 0,
			knockback_duration = 0.5,
			duration = 0.5,
			knockback_distance = radius/2,
			knockback_height = 50,
			center_x = knockback_origin.x,
			center_y = knockback_origin.y,
			center_z = knockback_origin.z
		}
		unit:RemoveModifierByName("modifier_knockback")
		unit:AddNewModifier(caster, nil, "modifier_knockback", knockbackModifierTable)
	end			
end

-- Apply damage and stun enemies OnIntervalThink
function VolcanoWave(event)
	local caster = event.caster
	local targets = event.target_entities
	local ability = event.ability

	local ability_level = ability:GetLevel() - 1
	local wave_damage = ability:GetLevelSpecialValueFor("wave_damage", ability_level)
	local stun_duration = ability:GetLevelSpecialValueFor("stun_duration", ability_level)

	local damage_table = {}
	damage_table.attacker = caster
	damage_table.damage_type = ability:GetAbilityDamageType()
	damage_table.damage_flags = DOTA_DAMAGE_FLAG_BYPASSES_BLOCK
	damage_table.ability = ability

	for _,unit in pairs(targets) do
		ability:ApplyDataDrivenModifier(caster, unit, "modifier_volcano_stun", {duration = stun_duration})
		
		damage_table.victim = unit
		damage_table.damage = wave_damage
		ApplyDamage(damage_table)
	end

	if caster:HasScepter() then
		VolcanoKnockback(event)
	end
end

function VolcanoAoEIndicator(event)
	local caster = event.caster
	local ability = event.ability
	local volcano = event.target

	local ability_level = ability:GetLevel() - 1
	local radius = ability:GetLevelSpecialValueFor("radius", ability_level)
	local volcano_duration = ability:GetLevelSpecialValueFor("volcano_duration", ability_level)

	-- Ring particle
    local particleHandler = ParticleManager:CreateParticle("particles/units/heroes/hero_monkey_king/monkey_king_furarmy_ring.vpcf", PATTACH_ABSORIGIN, caster)
    ParticleManager:SetParticleControl(particleHandler, 0, volcano:GetOrigin())
    ParticleManager:SetParticleControl(particleHandler, 1, Vector(radius,0,0))

	-- Destroy particle when volcano ends
	Timers:CreateTimer(volcano_duration, function()
        ParticleManager:DestroyParticle(particleHandler, false)
		ParticleManager:ReleaseParticleIndex(particleHandler)
	end)
end
