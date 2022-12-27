-- Called OnSpellStart
function ManaTransferStart(event)
	local target = event.target
	local caster = event.caster
	local ability = event.ability

	-- Talent that applies leash
	local has_talent = false
	local talent = caster:FindAbilityByName("special_bonus_unique_blood_mage_3")
	if talent and talent:GetLevel() > 0 then
		LinkLuaModifier("modifier_mana_transfer_leash_debuff", "heroes/blood_mage/mana_transfer.lua", LUA_MODIFIER_MOTION_NONE)
		has_talent = true
	end

	-- Checking if target is an enemy
	if target:GetTeamNumber() ~= caster:GetTeamNumber() then
		-- Check for spell block and spell immunity (latter because of lotus)
		if not target:TriggerSpellAbsorb(ability) and not target:IsMagicImmune() then
			ability:ApplyDataDrivenModifier(caster, target, "modifier_mana_transfer_enemy", {})
			caster:EmitSound("Hero_Lion.ManaDrain")
			if has_talent then
				target:AddNewModifier(caster, ability, "modifier_mana_transfer_leash_debuff", {})
			end
		else
			caster:Interrupt()
		end
	else
		ability:ApplyDataDrivenModifier(caster, target, "modifier_mana_transfer_ally", {})
		caster:EmitSound("Hero_Lion.ManaDrain")
	end

	local target_mana = target:GetMaxMana()
	-- Don't go on cooldown if targeted unit doesn't have mana
	if target_mana == 0 then
		ability:EndCooldown()
		local pID = caster:GetPlayerOwnerID()
		SendErrorMessage(pID, "Target Doesn't Have Mana!")
	end
end

--[[
	Called when modifier_mana_transfer_enemy is created. Function creates the Mana Drain Particle rope.
	It is indexed on the caster handle to have access to it later.
]]
function ManaDrainParticle(event)
	local caster = event.caster
	local target = event.target

	local particleName = "particles/units/heroes/hero_lion/lion_spell_mana_drain.vpcf"
	caster.ManaDrainParticle = ParticleManager:CreateParticle(particleName, PATTACH_POINT_FOLLOW, caster)
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

	-- If its an illusion then kill it
	if target:IsIllusion() then
		target:Kill(ability, caster)
		--ability:OnChannelFinish(false)
		caster:Interrupt()
		return
	else
		-- Location variables
		local caster_location = caster:GetAbsOrigin()
		local target_location = target:GetAbsOrigin()

		-- Distance variables
		local distance = (target_location - caster_location):Length2D()
		local break_distance = ability:GetLevelSpecialValueFor("break_distance", ability_level)
		local direction = (target_location - caster_location):Normalized()

		-- If one of these then stop the channel:
		-- 1) leash is broken
		-- 2) target becomes spell immune
		-- 3) target becomes invulnerable
		-- 4) target doesn't have a mana pool
		if distance >= break_distance or target:IsMagicImmune() or target:IsInvulnerable() or target:GetMana() < 1 then
			--ability:OnChannelFinish(false)
			caster:Interrupt()
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
		local mana_transfer
		if target_mana >= MP_drain then
			mana_transfer = MP_drain
		else
			mana_transfer = target_mana
		end

		target:ReduceMana(mana_transfer)

		-- Mana gained can go over the max mana
		if caster_mana + mana_transfer > caster_max_mana then
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_transfer_mana_extra", {})
		end

		caster:GiveMana(mana_transfer)
	end
end

-- Called when modifiers are destroyed (unit dies or modifier is removed; modifier can be removed in many cases)
-- OnChannelFinish and OnChannelInterrupted
function ManaTransferEnd(event)
	local caster = event.caster
	local target = event.target
	if caster.ManaDrainParticle then
		ParticleManager:DestroyParticle(caster.ManaDrainParticle, false)
		ParticleManager:ReleaseParticleIndex(caster.ManaDrainParticle)
	end

	--caster:Interrupt()
	caster:StopSound("Hero_Lion.ManaDrain")

	if target then
		local mana_drain_debuff = target:FindModifierByNameAndCaster("modifier_mana_transfer_enemy", caster)
		if mana_drain_debuff then
			mana_drain_debuff:Destroy()
		end

		local leash_debuff = target:FindModifierByNameAndCaster("modifier_mana_transfer_leash_debuff", caster)
		if leash_debuff then
			leash_debuff:Destroy()
		end

		local mana_transfer_buff = target:FindModifierByNameAndCaster("modifier_mana_transfer_ally", caster)
		if mana_transfer_buff then
			mana_transfer_buff:Destroy()
		end
	end
end

function ManaTransferAlly(event)
	local caster = event.caster
	local target = event.target
	local ability = event.ability
	local ability_level = ability:GetLevel() - 1

	local mana_donation = ability:GetLevelSpecialValueFor("mana_per_second", ability_level)
	local tick_rate = ability:GetLevelSpecialValueFor("tick_rate", ability_level)
	local MP_transfer = mana_donation*tick_rate

	-- Location variables
	local caster_location = caster:GetAbsOrigin()
	local target_location = target:GetAbsOrigin()

	-- Distance variables
	local distance = (target_location - caster_location):Length2D()
	local break_distance = ability:GetLevelSpecialValueFor("break_distance", ability_level)
	local direction = (target_location - caster_location):Normalized()

	-- If the leash is broken or target doesn't have a mana pool
	if distance >= break_distance or target:GetMana() < 1 then
		--ability:OnChannelFinish(false)
		caster:Interrupt()
		return
	end

	-- Make sure that the caster always faces the target if he is channeling
	if caster:IsChanneling() then
		caster:SetForwardVector(direction)
	end

	local target_mana = target:GetMana()
    local caster_mana = caster:GetMana()

	if caster:IsChanneling() then
		local mana_transfer
		if caster_mana >= MP_transfer then
			mana_transfer = MP_transfer
		else
			mana_transfer = caster_mana
		end

		caster:ReduceMana(mana_transfer)

		-- Mana given can go over the max mana
		if target_mana + mana_transfer > target:GetMaxMana() then
			ability:ApplyDataDrivenModifier(caster, target, "modifier_transfer_mana_extra", {})
		end

		target:GiveMana(mana_transfer)
	end
end

---------------------------------------------------------------------------------------------------

modifier_mana_transfer_leash_debuff = class({})

function modifier_mana_transfer_leash_debuff:IsHidden()
	return true
end

function modifier_mana_transfer_leash_debuff:IsDebuff()
	return true
end

function modifier_mana_transfer_leash_debuff:IsPurgable()
	return false
end

function modifier_mana_transfer_leash_debuff:RemoveOnDeath()
	return true
end

function modifier_mana_transfer_leash_debuff:CheckState()
	return {
		[MODIFIER_STATE_TETHERED] = true,
	}
end
