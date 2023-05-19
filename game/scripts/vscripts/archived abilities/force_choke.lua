-- Called on Spell Start
function ChokeStart (event)
	local target = event.target
	local caster = event.caster
	local ability = event.ability
		
	-- Checking if target has spell block, if target has spell block, there is no need to execute the spell
	if not target:TriggerSpellAbsorb( ability ) then
		--print("Target doesn't have Spell Block.")
		ability:ApplyDataDrivenModifier(caster, target, "modifier_force_choked", {})
		target:Interrupt()
		-- Emitting Sounds
		caster:EmitSound("Hero_Rubick.Telekinesis.Cast")
		target:EmitSound("Hero_Rubick.Telekinesis.Target")
	else
		--print("Target have Spell Block")
	end
end

-- Called when modifier_force_choked is created
function ChokeMain (keys)
	local target = keys.target
	local caster = keys.caster
	local ability = keys.ability
	local duration = ability:GetLevelSpecialValueFor("duration", ability:GetLevel() - 1 )
	if IsServer() then
		-- Position variables
		local target_origin = target:GetAbsOrigin()
		local target_x = target_origin.x
		local target_y = target_origin.y
		local ground_position = GetGroundPosition(target_origin, target)
		local ground_z = ground_position.z
		
		-- Creating a telekinesis particle
        local particle = ParticleManager:CreateParticle( "particles/units/heroes/hero_rubick/rubick_telekinesis.vpcf", PATTACH_CUSTOMORIGIN, nil );
        ParticleManager:SetParticleControlEnt( particle, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target_origin, true );
        ParticleManager:SetParticleControlEnt( particle, 1, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true );
        ParticleManager:SetParticleControl(particle, 2, Vector(duration,0,0))
		
		-- Storing a particle ID into a handle to destroy it later
		caster.particleID = particle
		
		-- Lifting the target
        local new_z = ground_z + 200
		local new_position = Vector(target_x, target_y, new_z)
		target:SetAbsOrigin(new_position)
    end
end

-- Called when modifier_force_choked is destroyed
function ChokeEnd (keys)
	local target = keys.target
	local caster = keys.caster
	local caster_team = caster:GetTeamNumber() -- GetTeam()
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	
	-- Ability Specials
	local radius = ability:GetLevelSpecialValueFor("radius", ability_level)
	local damage = ability:GetLevelSpecialValueFor("damage", ability_level)
	
	-- Position variables
	local target_origin = target:GetAbsOrigin()
	local target_x = target_origin.x
	local target_y = target_origin.y
	local ground_position = GetGroundPosition(target_origin, target)
	local ground_z = ground_position.z
	
	-- Landing
	local old_position = Vector(target_x, target_y, ground_z)
	target:SetAbsOrigin(old_position)
	
	-- Emit Sound on Landing
	EmitSoundOnLocationWithCaster(target:GetAbsOrigin(), "Hero_Rubick.Telekinesis.Target.Land", target)
	
	-- Damage enemies in a radius around the primary target upon landing
	local enemies = FindUnitsInRadius(caster_team, old_position, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, 0, 0, false)
	for k, enemy in pairs(enemies) do
		if enemy == target or enemy:IsMagicImmune() then
			--print("Enemy is immune to magic or the primary target.")
		else
			ApplyDamage({victim = enemy, attacker = caster, ability = ability, damage = damage, damage_type = DAMAGE_TYPE_MAGICAL})
		end
	end
	
	-- Particle Destroy
	ParticleManager:DestroyParticle(caster.particleID, true)
	
	-- Stopping Sounds
	StopSoundOn("Hero_Rubick.Telekinesis.Cast", caster)
	StopSoundOn("Hero_Rubick.Telekinesis.Target", target)
end