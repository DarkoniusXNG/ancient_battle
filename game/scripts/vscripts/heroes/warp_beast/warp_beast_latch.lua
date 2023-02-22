LinkLuaModifier("modifier_latch", "heroes/warp_beast/warp_beast_latch.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_latch_target", "heroes/warp_beast/warp_beast_latch.lua", LUA_MODIFIER_MOTION_NONE)

warp_beast_latch = class({})

function warp_beast_latch:CastFilterResultTarget(target)
	local caster = self:GetCaster()
	local default_result = self.BaseClass.CastFilterResultTarget(self, target)

	if target == caster or target:IsHeroDominatedCustom() then
		return UF_FAIL_CUSTOM
	end

	return default_result
end

function warp_beast_latch:GetCustomCastErrorTarget(target)
	local caster = self:GetCaster()
	if target == caster then
		return "#dota_hud_error_cant_cast_on_self"
	end
	if target:IsHeroDominatedCustom() then
		return "Can't Target Dominated Heroes!"
	end
	return ""
end

function warp_beast_latch:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	if not caster or not target then
		return
	end

	if target:GetTeam() ~= caster:GetTeam() then
		-- Check for spell block and spell immunity (latter because of lotus)
		if target:TriggerSpellAbsorb(self) or target:IsMagicImmune() then
			return
		end
	end

	-- Can't target clones
	if target:IsCloneCustom() then
		self:RefundManaCost()
		self:EndCooldown()
		-- Display the error message
		SendErrorMessage(caster:GetPlayerOwnerID(), "Can't Target Clones or Super illusions!")
		return
	end

	-- Prevent latching on latchers (those that are already latching)
	if target:HasModifier("modifier_item_lotus_orb_active") or target:HasModifier("modifier_latch") then -- or target:HasModifier("modifier_latch_target") then
		return
	end

	local distance = -80
	local duration = self:GetSpecialValueFor("duration")
	if target:GetTeam() == caster:GetTeam() then
		distance = -20
		duration = -1
	end

	local bonusAttackSpeed = self:GetSpecialValueFor("attackspeed_bonus")
	local talent = caster:FindAbilityByName("special_bonus_unique_warp_beast_latch_attackspeed")
	if talent and talent:GetLevel() > 0 then
		bonusAttackSpeed = bonusAttackSpeed + talent:GetSpecialValueFor("value")
	end
	local modifier = caster:AddNewModifier(caster, self, "modifier_latch", {duration = duration, attackSpeed = bonusAttackSpeed})
	target:AddNewModifier(caster, self, "modifier_latch_target", {duration = duration})
	modifier.target = target

	local latchPosition = target:GetAbsOrigin() + (target:GetForwardVector() * distance) + Vector(0, RandomFloat(-2, 2), 0)
	local latchDirection = (target:GetAbsOrigin() - latchPosition):Normalized()

	caster:EmitSound("Hero_Warp_Beast.Latch")

	local targetHeight = self:GetLatchHeight(target)

	caster:SetAbsOrigin(latchPosition + Vector(0, 0, targetHeight))
	caster:SetForwardVector(latchDirection)
	caster:SetParent(target, "attach_origin")

	if target:GetTeam() ~= caster:GetTeam() then
		local order = {
			UnitIndex = caster:entindex(),
			OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
			TargetIndex = target:entindex(),
		}
		ExecuteOrderFromTable(order)
		caster:SetForceAttackTarget(target)
		--caster:MoveToTargetToAttack(target)
	end
end

function warp_beast_latch:GetLatchHeight(target)
	if target:GetUnitName() == "npc_dota_hero_phoenix" then return 180 end
	if target:GetUnitName() == "npc_dota_hero_skywrath_mage" then return 240 end
	if target:IsHero() then return 120 end
	if target:IsBarracks() then return 250 end
	if target:IsTower() then return 275 end
	if target:IsRoshan() then return 300 end
	if target:IsFort() then return 400 end
	if target:GetUnitName() == "npc_dota_phoenix_sun" then return 340 end
	-- Default height
	return 80
end


---------------------------------------------------------------------------------------------------

modifier_latch = class({})

function modifier_latch:IsPurgable()
	return false
end

function modifier_latch:RemoveOnDeath()
	return true
end

function modifier_latch:CheckState()
	return {
		-- [MODIFIER_STATE_ROOTED] = true,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
		[MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
		[MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true, -- to prevent force staff, knockbacks etc. causing Warp Beast to be glitched
	}
end

function modifier_latch:OnCreated(keys)
	if not IsServer() then return end

	self.attackspeed_bonus = keys.attackSpeed -- data sent with AddNewModifier is not available on the client
	self:StartIntervalThink(0.1)
end

function modifier_latch:OnIntervalThink()
	if not IsServer() then return end

	if self.target and not self.target:IsNull() then
		local caster = self:GetCaster()
		local target = self.target

		-- Check target
		if not caster:CanEntityBeSeenByMyTeam(target) or target:IsMagicImmune() then
			target:RemoveModifierByNameAndCaster("modifier_latch_target", caster)
			return
		end

		-- Check caster
		if caster:IsStunned() or caster:IsHexed() or caster:IsOutOfGame() then
			target:RemoveModifierByNameAndCaster("modifier_latch_target", caster)
		end
	else
		self:Destroy()
	end
end

function modifier_latch:GetEffectName()
	return "particles/units/heroes/hero_warp_beast/warp_beast_latch.vpcf"
end

function modifier_latch:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		-- MODIFIER_EVENT_ON_ATTACK_LANDED,
		MODIFIER_EVENT_ON_ORDER,
	}
end

function modifier_latch:GetModifierAttackSpeedBonus_Constant()
	return self.attackspeed_bonus
end

if IsServer() then
-- Lifesteal part
--[[
	function modifier_latch:OnAttackLanded(event)
		if self:GetParent() == event.attacker then
			local attacker = event.attacker
			local target = event.target

			if target:IsBuilding() or target:IsIllusion() or (target:GetTeam() == attacker:GetTeam()) then
				return
			end

			local damage = event.damage * (100 - target:GetPhysicalArmorReduction()) / 100
			local heal = self:GetAbility():GetSpecialValueFor("lifesteal_bonus") * damage / 100

			if attacker:IsRealHero() then
				attacker:Heal(heal, attacker)
			end

			local lifesteal_pfx = ParticleManager:CreateParticle("particles/generic_gameplay/generic_lifesteal.vpcf", PATTACH_ABSORIGIN_FOLLOW, attacker)
			ParticleManager:SetParticleControl(lifesteal_pfx, 0, attacker:GetAbsOrigin())
			ParticleManager:ReleaseParticleIndex(lifesteal_pfx)

		end
	end
]]
	function modifier_latch:OnOrder(event)
		if event.unit == self:GetParent() and self.target and self.target:HasModifier("modifier_latch_target") and self.target:GetTeam() == self:GetParent():GetTeam() then
			self.target:RemoveModifierByNameAndCaster("modifier_latch_target", self:GetCaster())
			self:Destroy()
		end
	end

	function modifier_latch:OnDestroy()
		local caster = self:GetCaster()

		caster:SetForceAttackTarget(nil)

		local ability = self:GetAbility()
		if ability and not ability:IsNull() then
			ability:SetActivated(true)
		end
		caster:SetParent(nil, "attach_origin")
		FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
	end
end

---------------------------------------------------------------------------------------------------

modifier_latch_target = class({})

-- if IsServer() then
	-- cast_orders = {
		-- [DOTA_UNIT_ORDER_CAST_POSITION] = true,
		-- [DOTA_UNIT_ORDER_CAST_TARGET] = true,
	-- }
-- end

function modifier_latch_target:IsPurgable()
	return false
end

function modifier_latch_target:RemoveOnDeath()
	return true
end

-- function modifier_latch_target:DeclareFunctions()
	-- local funcs = {
		-- MODIFIER_EVENT_ON_ORDER
	-- }
	-- return funcs
-- end

-- -- Being able to use spells and items while latched
-- function modifier_latch_target:OnOrder(event)
	-- if not IsServer() then return end

	-- local caster = self:GetCaster()
	-- if event.unit == caster and caster:IsRealHero() then
		-- if cast_orders[event.order_type] and not self:GetCaster():IsSilenced() then
			-- local ability = event.ability
			-- if ability then
				-- local castPosition
				-- if event.target then
					-- castPosition = event.target:GetAbsOrigin()
				-- else
					-- castPosition = event.new_pos
				-- end

				-- local maxCastRange = ability:GetCastRange(castPosition, caster) + caster:GetCastRangeBonus()
				-- local distance = (caster:GetAbsOrigin() - castPosition):Length2D()

				-- -- Remove latch if Temporal Jump is used and within range
				-- if maxCastRange >= distance and ability:GetName() == "warp_beast_temporal_jump" then
					-- self:Destroy()
				-- -- Remove latch if Warp is used
				-- elseif caster:HasModifier("modifier_warp") and maxCastRange < distance then
					-- self:Destroy()
				-- end
			-- end
		-- end
	-- end
-- end

function modifier_latch_target:OnDestroy()
	if not IsServer() then return end

	local caster = self:GetCaster()
	caster:RemoveModifierByName("modifier_latch")
end
