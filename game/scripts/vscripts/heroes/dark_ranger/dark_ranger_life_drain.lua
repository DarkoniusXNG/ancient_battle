-- Called OnSpellStart
function LifeDrainStart(event)
	local target = event.target
	local caster = event.caster
	local ability = event.ability
	
	-- Checking if target has spell block, if target has spell block, there is no need to execute the spell
	if not target:TriggerSpellAbsorb(ability) then
		ability:ApplyDataDrivenModifier(caster, target, "modifier_dark_ranger_life_drain", {})
		caster:EmitSound("Hero_Pugna.LifeDrain.Target")
	else
		caster:Interrupt()
	end
end

--[[
	Called when modifier_dark_ranger_life_drain is created. Function creates the Life Drain Particle rope. 
	It is indexed on the caster handle to have access to it later.
]]
function LifeDrainParticle(event)
	local caster = event.caster
	local target = event.target
	local ability = event.ability

	local particleName = "particles/units/heroes/hero_pugna/pugna_life_drain.vpcf"
	caster.LifeDrainParticle = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControlEnt(caster.LifeDrainParticle, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	
	-- Set the particle control color as green
	ParticleManager:SetParticleControl(caster.LifeDrainParticle, 10, Vector(0,0,0))
	ParticleManager:SetParticleControl(caster.LifeDrainParticle, 11, Vector(0,0,0))
end

-- Called OnIntervalThink inside modifier_dark_ranger_life_drain
function LifeDrainHealthTransfer(event)
	local caster = event.caster
	local target = event.target
	local ability = event.ability
	local ability_level = ability:GetLevel() - 1
	
	local health_drain = ability:GetLevelSpecialValueFor("health_drain", ability_level)
	local tick_rate = ability:GetLevelSpecialValueFor("tick_rate", ability_level)
	local HP_drain = health_drain * tick_rate

	-- How much caster heals himself
	local HP_gain = HP_drain
	
	-- If its an illusion then kill it
	if target:IsIllusion() then
		target:Kill(ability, caster)
		ability:OnChannelFinish(false)
		caster:Interrupt()
		ParticleManager:DestroyParticle(caster.LifeDrainParticle,false)
		return
	else
		-- Location variables
		local caster_location = caster:GetAbsOrigin()
		local target_location = target:GetAbsOrigin()

		-- Distance variables
		local distance = (target_location - caster_location):Length2D()
		local break_distance = ability:GetLevelSpecialValueFor("break_distance", ability_level)
		local direction = (target_location - caster_location):Normalized()

		-- If the leash is broken or target is spell immune or invulnerable then stop the channel
		if distance >= break_distance or target:IsMagicImmune() or target:IsInvulnerable() then
			ability:OnChannelFinish(false)
			caster:Interrupt()
			ParticleManager:DestroyParticle(caster.LifeDrainParticle,false)
			target:RemoveModifierByName("modifier_dark_ranger_life_drain")
			return
		end
		
		-- Make sure that the caster always faces the target if he is channeling 
		if caster:IsChanneling() then
			caster:SetForwardVector(direction)
		end
	end
	
	if caster:GetHealthDeficit() > 0 and caster:IsChanneling() then
		-- Health Transfer from the Enemy to the caster
		ApplyDamage({victim = target, attacker = caster, damage = HP_drain, damage_type = DAMAGE_TYPE_MAGICAL})
		caster:Heal(HP_gain, caster)
	end
	
end

-- Called when modifier_dark_ranger_life_drain is destroyed (unit dies or modifier is removed; modifier can be removed in many cases)
-- OnChannelFinish and OnChannelInterrupted
function LifeDrainEnd(event)
	local caster = event.caster
	local target = event.target
	if caster.LifeDrainParticle then
		ParticleManager:DestroyParticle(caster.LifeDrainParticle,false)
	end
	
	caster:Interrupt()
	caster:StopSound("Hero_Pugna.LifeDrain.Target")
	
	if target then
		if target:HasModifier("modifier_dark_ranger_life_drain") then
			target:RemoveModifierByName("modifier_dark_ranger_life_drain")
		end
	end
end