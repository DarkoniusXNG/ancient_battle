if modifier_holy_strike_passive == nil then
	modifier_holy_strike_passive = class({})
end

function modifier_holy_strike_passive:IsHidden()
	return true
end

function modifier_holy_strike_passive:IsPurgable()
	return false
end

function modifier_holy_strike_passive:IsDebuff()
	return false
end

function modifier_holy_strike_passive:RemoveOnDeath()
	return false
end

function modifier_holy_strike_passive:OnCreated()
	local parent = self:GetParent()
	local ability = self:GetAbility()
	-- Add weapon glow effect when the modifier is created
	if IsServer() then
		parent:AddNewModifier(parent, ability, "modifier_holy_strike_passive_weapon_effect", {})
		self:StartIntervalThink(0)
	end
end

function modifier_holy_strike_passive:OnRefresh()
	local parent = self:GetParent()
	local ability = self:GetAbility()
	-- Add weapon glow effect only if the ability is off cooldown
	if IsServer() then
		if ability:IsCooldownReady() and not parent:IsSilenced() and not parent:IsHexed() then
			if ability:GetAutoCastState() == true then
				-- Autocast is ON
				parent:AddNewModifier(parent, ability, "modifier_holy_strike_passive_weapon_effect", {})
			else
				-- Autocast is OFF
				parent:RemoveModifierByName("modifier_holy_strike_passive_weapon_effect")
				-- manual cast? doesn't work but don't remove
				if self.manual_cast then
					parent:AddNewModifier(parent, ability, "modifier_holy_strike_passive_weapon_effect", {})
				end
			end
		else
			parent:RemoveModifierByName("modifier_holy_strike_passive_weapon_effect")
		end
	end
end

function modifier_holy_strike_passive:OnIntervalThink()
	self:OnRefresh()
end

function modifier_holy_strike_passive:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
		MODIFIER_EVENT_ON_ATTACK,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end

function modifier_holy_strike_passive:GetModifierAttackRangeBonus()
	local parent = self:GetParent()
	local ability = self:GetAbility()
	local bonus_attack_range = ability:GetSpecialValueFor("bonus_attack_range")

	if parent:HasModifier("modifier_holy_strike_passive_weapon_effect") then
		return bonus_attack_range
	end

	return 0
end

if IsServer() then
	function modifier_holy_strike_passive:OnAttack(event)
		local parent = self:GetParent()
		local ability = self:GetAbility()
		local attacker = event.attacker

		-- Don't continue if the attacker doesn't exist
		if not attacker or attacker:IsNull() then
			return
		end

		-- Check if attacker has this modifier
		if attacker ~= parent then
			return
		end

		if parent:GetCurrentActiveAbility() ~= ability then
			return
		end

		-- Manual cast detected
		self.manual_cast = true
	end

	function modifier_holy_strike_passive:OnAttackLanded(event)
		local parent = self:GetParent()
		local ability = self:GetAbility()
		local attacker = event.attacker

		-- Don't continue if the attacker doesn't exist
		if not attacker or attacker:IsNull() then
			return
		end

		-- Check if attacker has this modifier
		if attacker ~= parent then
			return
		end

		-- Check if the attacker is an illusion
		if attacker:IsIllusion() then
			return
		end

		if ability:IsCooldownReady() and not parent:IsSilenced() and not parent:IsHexed() then
			if ability:GetAutoCastState() == true or self.manual_cast then
				-- The Attack while autocast is on
				self:HolyStrike(event)
			end
		end
	end

	function modifier_holy_strike_passive:HolyStrike(event)
		if event then
			local attacker = event.attacker or self:GetParent()
			local target = event.target
			local ability = self:GetAbility()
			local attack_damage = event.original_damage

			-- Don't continue if attacked entity doesn't exist
			if not target or target:IsNull() then
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

			-- Calculate bonus pure damage
			local percent_as_pure = ability:GetSpecialValueFor("percent_damage_as_pure")
			local true_damage = attack_damage*percent_as_pure/100

			-- Sound on attacker
			if true_damage > event.damage then
				attacker:EmitSound("Hero_Omniknight.HammerOfPurity.Crit")
			end

			-- Sound on target
			target:EmitSound("Hero_Omniknight.HammerOfPurity.Target")

			-- Damage table
			local damage_table = {}
			damage_table.attacker = attacker
			damage_table.damage = true_damage
			damage_table.damage_type = DAMAGE_TYPE_PURE
			damage_table.ability = ability
			damage_table.victim = target

			ApplyDamage(damage_table)

			local player = attacker:GetPlayerOwner()
			SendOverheadEventMessage(player, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, target, true_damage, player)

			ability:UseResources(true, false, true)

			-- Remove weapon glow effect
			attacker:RemoveModifierByName("modifier_holy_strike_passive_weapon_effect")

			self.manual_cast = nil
		end
	end
end
