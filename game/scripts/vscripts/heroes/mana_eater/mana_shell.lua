if mana_eater_mana_shell == nil then
	mana_eater_mana_shell = class({})
end

LinkLuaModifier("modifier_mana_shell_passive", "heroes/mana_eater/mana_shell.lua", LUA_MODIFIER_MOTION_NONE)

function mana_eater_mana_shell:GetIntrinsicModifierName()
	return "modifier_mana_shell_passive"
end

function mana_eater_mana_shell:IsStealable()
	return false
end

function mana_eater_mana_shell:ShouldUseResources()
	return false
end

---------------------------------------------------------------------------------------------------

if modifier_mana_shell_passive == nil then
	modifier_mana_shell_passive = class({})
end

function modifier_mana_shell_passive:IsHidden()
	return true
end

function modifier_mana_shell_passive:IsPurgable()
	return false
end

function modifier_mana_shell_passive:IsDebuff()
	return false
end

function modifier_mana_shell_passive:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT
end

function modifier_mana_shell_passive:AllowIllusionDuplicate()
	return false -- this does nothing apparently
end

function modifier_mana_shell_passive:OnCreated()
	local ability = self:GetAbility()
	self.mana_gain = ability:GetSpecialValueFor("mana_percentage")
end

modifier_mana_shell_passive.OnRefresh = modifier_mana_shell_passive.OnCreated

function modifier_mana_shell_passive:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_TAKEDAMAGE,
	}

	return funcs
end

function modifier_mana_shell_passive:OnTakeDamage(event)
	local parent = self:GetParent()

	if event.unit ~= parent and event.attacker ~= parent then
		return nil
	end
	
	-- Doesn't work on illusions
	if parent:IsIllusion() then
		return nil
	end

	if IsServer() then
		-- Don't trigger on damage with HP removal flag
		if HasBit(event.damage_flags, DOTA_DAMAGE_FLAG_HPLOSS) then
			return nil
		end

		local damage_taken = event.original_damage -- Damage before reductions

		-- Don't trigger on every unit getting damaged, only the one that has this modifier
		if event.unit == parent then
			
			-- Don't trigger if parent has break applied to him
			if parent:PassivesDisabled() then
				return nil
			end

			local mana_gain_percentage_on_damage_taken = self.mana_gain
			local mana_amount = damage_taken*mana_gain_percentage_on_damage_taken*0.01

			-- Give mana to the parent in relation to damage taken; 
			parent:GiveMana(mana_amount)
		end
		
		if event.attacker == parent then
			-- Check for talent
			local talent = parent:FindAbilityByName("special_bonus_unique_puck")
			if talent then
				if talent:GetLevel() ~= 0 then
					local mana_gain_percentage_on_damage_dealt = 50
					local mana_amount = damage_taken*mana_gain_percentage_on_damage_dealt*0.01

					-- Give mana to the parent in relation to damage taken; 
					parent:GiveMana(mana_amount)
				end
			end
		end
	end
end
