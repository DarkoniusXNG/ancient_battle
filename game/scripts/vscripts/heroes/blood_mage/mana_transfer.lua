-- Called OnSpellStart
function ManaTransferStart(event)
	local target = event.target
	local caster = event.caster
	local ability = event.ability
	
	if target:GetTeamNumber() ~= caster:GetTeamNumber() then
		if not target:TriggerSpellAbsorb(ability) then
			ability:ApplyDataDrivenModifier(caster, target, "modifier_mana_transfer_enemy", {})
			caster:EmitSound("Hero_Lion.ManaDrain")
		else
			caster:Interrupt()
		end
	else
		ability:ApplyDataDrivenModifier(caster, target, "modifier_mana_transfer_ally", {})
		caster:EmitSound("Hero_Lion.ManaDrain")
	end
end

--[[
	Called when modifier_mana_transfer_enemy is created. Function creates the Mana Drain Particle rope. 
	It is indexed on the caster handle to have access to it later.
]]
function ManaDrainParticle(event)
	local caster = event.caster
	local target = event.target
	local ability = event.ability

	local particleName = "particles/units/heroes/hero_lion/lion_spell_mana_drain.vpcf"
	caster.ManaDrainParticle = ParticleManager:CreateParticle(particleName,PATTACH_POINT_FOLLOW,caster)
	-- PATTACH_ABSORIGIN_FOLLOW
	
	if target:GetTeamNumber() == caster:GetTeamNumber() then
		ParticleManager:SetParticleControlEnt(caster.ManaDrainParticle, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
		ParticleManager:SetParticleControlEnt(caster.ManaDrainParticle, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	else
		ParticleManager:SetParticleControlEnt(caster.ManaDrainParticle, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
		ParticleManager:SetParticleControlEnt(caster.ManaDrainParticle, 1, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
	end
end

-- Called OnIntervalThink inside modifier_mana_transfer_enemy
function ManaDrainManaTransfer(event)
	local caster = event.caster
	local target = event.target
	local ability = event.ability
	local ability_level = ability:GetLevel() - 1
	
	local mana_drain = ability:GetLevelSpecialValueFor("mana_per_second", ability_level)
	local tick_rate = ability:GetLevelSpecialValueFor("tick_rate", ability_level)
	local MP_drain = mana_drain*tick_rate

	-- How much caster gains mana
	local MP_gain = MP_drain
	
	-- If its an illusion then kill it
	if target:IsIllusion() then
		target:Kill(ability, caster)
		ability:OnChannelFinish(false)
		caster:Interrupt()
		ParticleManager:DestroyParticle(caster.ManaDrainParticle,false)
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
			ParticleManager:DestroyParticle(caster.ManaDrainParticle,false)
			target:RemoveModifierByName("modifier_mana_transfer_enemy")
			return
		end
		
		-- Make sure that the caster always faces the target if he is channeling 
		if caster:IsChanneling() then
			caster:SetForwardVector(direction)
		end
	end
	
	local target_mana = target:GetMana()
    local caster_mana = caster:GetMana()
    local caster_max_mana = caster:GetMaxMana()
	
	if caster:IsChanneling() then
		if target_mana >= MP_drain then
			target:ReduceMana(MP_drain)

			-- Mana gained can go over the max mana
			if caster_mana+MP_gain > caster_max_mana then
				ability:ApplyDataDrivenModifier(caster, caster, "modifier_transfer_mana_extra", nil)
			end
			
			caster:GiveMana(MP_gain)
		else
			target:ReduceMana(target_mana)
			caster:GiveMana(target_mana)
		end
	end
end

-- Called when modifiers are destroyed (unit dies or modifier is removed; modifier can be removed in many cases)
-- OnChannelFinish and OnChannelInterrupted
function ManaTransferEnd(event)
	local caster = event.caster
	local target = event.target
	if caster.ManaDrainParticle then
		ParticleManager:DestroyParticle(caster.ManaDrainParticle,false)
	end
	
	caster:Interrupt()
	caster:StopSound("Hero_Lion.ManaDrain")
	
	if target then
		if target:HasModifier("modifier_mana_transfer_enemy") then
			target:RemoveModifierByName("modifier_mana_transfer_enemy")
		end
		
		if target:HasModifier("modifier_mana_transfer_ally") then
			target:RemoveModifierByName("modifier_mana_transfer_ally")
		end
	end
end

function ManaTransferAlly(event)
	local caster = event.caster
	local target = event.target
	local ability = event.ability
	local ability_level = ability:GetLevel() - 1
	
	local mana_transfer = ability:GetLevelSpecialValueFor("mana_per_second", ability_level)
	local tick_rate = ability:GetLevelSpecialValueFor("tick_rate", ability_level)
	local MP_transfer = mana_transfer*tick_rate
	
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
		ParticleManager:DestroyParticle(caster.ManaDrainParticle,false)
		target:RemoveModifierByName("modifier_mana_transfer_ally")
		return
	end
	
	-- Make sure that the caster always faces the target if he is channeling 
	if caster:IsChanneling() then
		caster:SetForwardVector(direction)
	end
	
	local target_mana = target:GetMana()
    local caster_mana = caster:GetMana()
	
	if caster:IsChanneling() then
		if caster_mana >= MP_transfer then
			caster:ReduceMana(MP_transfer)
			target:GiveMana(MP_transfer)
		else
			caster:ReduceMana(caster_mana)
			target:GiveMana(caster_mana)
		end
	end
end