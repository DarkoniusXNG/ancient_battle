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
		self:StartIntervalThink(0.1)
	end
end

function modifier_holy_strike_passive:OnRefresh()
	local parent = self:GetParent()
	local ability = self:GetAbility()
	-- Add weapon glow effect only if the ability is off cooldown
	if IsServer() then
		if ability:IsCooldownReady() and (not parent:IsSilenced()) then
			if ability:GetAutoCastState() == true then
				parent:AddNewModifier(parent, ability, "modifier_holy_strike_passive_weapon_effect", {})
			else
				-- Autocast is off
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
	if IsServer() then
		self:ForceRefresh()
	end
end

function modifier_holy_strike_passive:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
		MODIFIER_EVENT_ON_ATTACK,
		MODIFIER_EVENT_ON_ATTACK_LANDED
	}

	return funcs
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

function modifier_holy_strike_passive:OnAttack(event)
    local parent = self:GetParent()
	local ability = self:GetAbility()
	
	if event.attacker ~= parent then
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
	local target = event.target
	
	if event.attacker == parent and ability:IsCooldownReady() and (not parent:IsSilenced()) then
		if ability:GetAutoCastState() == true then
			-- The Attack while autocast is on
			self:HolyStrike(event)
		else
			-- The Attack while autocast is off
			if self.manual_cast then
				self:HolyStrike(event)
			end
		end
	end
end

function modifier_holy_strike_passive:HolyStrike(event)
	if IsServer() and event then
		local attacker = event.attacker or self:GetParent()
		local target = event.target
		local ability = self:GetAbility()	
		local attack_damage = event.original_damage

		-- Calculate bonus pure damage
		local percent_as_pure = ability:GetSpecialValueFor("percent_damage_as_pure")
		local true_damage = attack_damage*percent_as_pure/100
			
		-- If the attack target is a building or a ward then stop (return)
		if target:IsTower() or target:IsBarracks() or target:IsBuilding() or target:IsOther() then
			return
		end
		
		-- If the attacker is an illusion then stop (return)
		if attacker:IsIllusion() then
			return
		end

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

		--attacker:EmitSound("Hero_Kunkka.Tidebringer.Attack")

		ability:UseResources(true, false, true)

		-- Remove weapon glow effect
		attacker:RemoveModifierByName("modifier_holy_strike_passive_weapon_effect")

		self.manual_cast = nil
	end
end
