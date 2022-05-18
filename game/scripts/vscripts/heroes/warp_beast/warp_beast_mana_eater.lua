LinkLuaModifier("modifier_mana_eater_passive", "scripts/vscripts/heroes/warp_beast/warp_beast_mana_eater.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_mana_eater_bonus_mana_count", "scripts/vscripts/heroes/warp_beast/warp_beast_mana_eater.lua", LUA_MODIFIER_MOTION_NONE)

warp_beast_mana_eater = class({})

function warp_beast_mana_eater:GetIntrinsicModifierName()
	return "modifier_mana_eater_passive"
end

modifier_mana_eater_passive = class({})

function modifier_mana_eater_passive:IsHidden()
	return true
end

function modifier_mana_eater_passive:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_ATTACK_LANDED,
		MODIFIER_EVENT_ON_DEATH,
		MODIFIER_PROPERTY_EVASION_CONSTANT
	}
	return funcs
end

function modifier_mana_eater_passive:GetModifierEvasion_Constant()
	local parent = self:GetParent()
	local evasion_per_mana_percentage = self:GetAbility():GetSpecialValueFor("evasion_per_mana_percentage")
	local max_mana = parent:GetMaxMana()
	local current_mana = parent:GetMana()
	local current_mana_percentage = (current_mana/max_mana)*100
	local evasion = math.ceil(current_mana_percentage*evasion_per_mana_percentage/100)
	if not parent:PassivesDisabled() then
		return evasion
	else
		return 0
	end
end

function modifier_mana_eater_passive:OnAttackLanded(event)
	local parent = self:GetParent()
	local attacker = event.attacker
	local target = event.target

	if parent ~= attacker then
		return
	end
	
	if not IsServer() then
		return
	end

	-- No mana drain while broken
	if parent:PassivesDisabled() then
		return
	end

	-- To prevent crashes:
	if not target then
		return
	end

	if target:IsNull() then
		return
	end

	-- Check for existence of GetUnitName method to determine if target is a unit or an item
	-- items don't have that method -> nil; if the target is an item, don't continue
	if target.GetUnitName == nil then
		return
	end

	-- If the attack target is a building or a ward then stop (return)
	if target:IsTower() or target:IsBarracks() or target:IsBuilding() or target:IsOther() then
		return
	end
	
	if target:IsIllusion() then
		return
	end

	if target:GetMana() > 0 then
		local ability = self:GetAbility()
		local drainAmount = ability:GetSpecialValueFor("drain_amount") 
		local talent = parent:FindAbilityByName("special_bonus_unique_warp_beast_mana_eater")
		if talent then
			if talent:GetLevel() ~= 0 then
				drainAmount = drainAmount + talent:GetSpecialValueFor("value")
			end
		end
		--local targetMana = target:GetMana()
		local duration = ability:GetSpecialValueFor("bonus_duration")

		--if targetMana < drainAmount then
			--drainAmount = targetMana
		--end

		-- Don't give mana to illusions
		if not parent:IsIllusion() then
			local missingMana = parent:GetMaxMana() - parent:GetMana()
			if missingMana < drainAmount then
				local modifier = parent:FindModifierByName("modifier_mana_eater_bonus_mana_count")
				if modifier then
					modifier:SetDuration(duration, true)
					modifier:SetStackCount(math.min(modifier:GetStackCount() + drainAmount - missingMana, ability:GetSpecialValueFor("bonus_mana_cap")))
				else
					modifier = parent:AddNewModifier(parent, ability, "modifier_mana_eater_bonus_mana_count", {Duration = duration})
					if modifier then modifier:SetStackCount(math.min(drainAmount - missingMana, ability:GetSpecialValueFor("bonus_mana_cap"))) end
				end
				parent:CalculateStatBonus(true)
			end
		end

		--target:ReduceMana(drainAmount)

		-- Don't give mana to illusions
		if not parent:IsIllusion() then
			parent:GiveMana(drainAmount)
		end

		target:EmitSound("Hero_Warp_Beast.ManaEater")

		local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_warp_beast/warp_beast_mana_eater.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
		ParticleManager:SetParticleControlEnt(particle, 1, caster, PATTACH_POINT_FOLLOW, "attach_eye_l", Vector(0,0,0), true)
	end
end

function modifier_mana_eater_passive:OnDeath(keys)
	if not IsServer() then return end

	if keys.attacker and keys.attacker == self:GetParent() and keys.unit:GetMana() > 0 and not keys.attacker:PassivesDisabled() then
		local caster = self:GetParent()
		local unit = keys.unit

		if unit:IsIllusion() or caster:IsIllusion() then
			return
		end

		local drainAmount = self:GetAbility():GetSpecialValueFor("kill_drain_percentage") * unit:GetMaxMana() / 100
		local duration = self:GetAbility():GetSpecialValueFor("bonus_duration")

		local missingMana = caster:GetMaxMana() - caster:GetMana()
		if missingMana < drainAmount then
			local modifier = caster:FindModifierByName("modifier_mana_eater_bonus_mana_count")
			if modifier then 
				modifier:SetDuration(duration, true)
				modifier:SetStackCount(math.min(modifier:GetStackCount() + drainAmount - missingMana, self:GetAbility():GetSpecialValueFor("bonus_mana_cap")))
			else 
				modifier = caster:AddNewModifier(caster, self:GetAbility(), "modifier_mana_eater_bonus_mana_count", {Duration = duration})
				if modifier then modifier:SetStackCount(math.min(drainAmount - missingMana, self:GetAbility():GetSpecialValueFor("bonus_mana_cap"))) end
			end
			caster:CalculateStatBonus(true)
		end

		caster:GiveMana(drainAmount)
	end
end

modifier_mana_eater_bonus_mana_count = class({})

function modifier_mana_eater_bonus_mana_count:IsHidden() return false end
function modifier_mana_eater_bonus_mana_count:IsDebuff() return false end
function modifier_mana_eater_bonus_mana_count:IsPurgable() return false end

function modifier_mana_eater_bonus_mana_count:DeclareFunctions() 
	local funcs = {
		MODIFIER_PROPERTY_EXTRA_MANA_BONUS,
		MODIFIER_EVENT_ON_SPENT_MANA
	}
	return funcs
end

function modifier_mana_eater_bonus_mana_count:GetModifierExtraManaBonus()
	return self:GetStackCount()
end

function modifier_mana_eater_bonus_mana_count:OnSpentMana(keys)
	if IsServer() then
		if keys.unit == self:GetParent() then
			local caster = self:GetParent()
			local manaCost = keys.cost
			local restoreAmount = manaCost

			if restoreAmount > self:GetStackCount() then
				self:Destroy()
			else
				self:SetStackCount(self:GetStackCount() - restoreAmount)
			end
		end
	end
end