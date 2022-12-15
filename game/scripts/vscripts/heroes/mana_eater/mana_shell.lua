if mana_eater_mana_shell == nil then
	mana_eater_mana_shell = class({})
end

LinkLuaModifier("modifier_mana_shell_passive", "heroes/mana_eater/mana_shell.lua", LUA_MODIFIER_MOTION_NONE)

function mana_eater_mana_shell:Spawn()
  if IsServer() and self:GetLevel() ~= 1 then
    self:SetLevel(1)
  end
end

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

function modifier_mana_shell_passive:RemoveOnDeath()
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
	return {
		MODIFIER_EVENT_ON_TAKEDAMAGE,
	}
end

if IsServer() then
	function modifier_mana_shell_passive:OnTakeDamage(event)
		local parent = self:GetParent()
		local attacker = event.attacker
		local damaged_unit = event.unit

		-- Check if attacker exists
		if not attacker or attacker:IsNull() then
			return
		end

		-- Check if damaged entity exists
		if not damaged_unit or damaged_unit:IsNull() then
			return
		end

		-- Check if entity is an item, rune or something weird
		if damaged_unit.GetUnitName == nil then
			return
		end

		-- Check if either attacker or victim has this modifier
		if damaged_unit ~= parent and attacker ~= parent then
			return
		end

		-- Doesn't work on illusions, when affected by Break or when dead
		if parent:IsIllusion() or parent:PassivesDisabled() or not parent:IsAlive() then
			return
		end

		-- Don't trigger on damage with HP removal flag
		if HasBit(event.damage_flags, DOTA_DAMAGE_FLAG_HPLOSS) then
			return
		end

		local damage_taken = event.original_damage -- Damage before reductions

		-- Check if damage is somehow 0 or negative
		if damage_taken <= 0 then
			return
		end

		-- Don't do the following stuff on every unit getting damaged, only the one that has this modifier
		if damaged_unit == parent then
			local mana_gain_percentage_on_damage_taken = self.mana_gain
			local mana_amount = damage_taken*mana_gain_percentage_on_damage_taken*0.01

			-- Give mana to the parent in relation to damage taken
			parent:GiveMana(mana_amount)

			-- Indicator (there is a check if it's enough to reduce the spam)
			if mana_amount >= 50 then
				SendOverheadEventMessage(nil, OVERHEAD_ALERT_MANA_ADD, parent, mana_amount, nil)
			end
		end

		if attacker == parent then
			-- Check for talent
			local talent = parent:FindAbilityByName("special_bonus_unique_mana_eater_2")
			if talent and talent:GetLevel() > 0 then
				local mana_gain_percentage_on_damage_dealt = talent:GetSpecialValueFor("value")
				local mana_amount = damage_taken*mana_gain_percentage_on_damage_dealt*0.01

				-- Give mana to the parent in relation to damage dealt
				parent:GiveMana(mana_amount)

				-- Indicator
				SendOverheadEventMessage(nil, OVERHEAD_ALERT_MANA_ADD, parent, mana_amount, nil)
			end
		end
	end
end
