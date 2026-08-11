LinkLuaModifier("modifier_warp", "scripts/vscripts/heroes/warp_beast/warp_beast_warp.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_warp_indicator", "scripts/vscripts/heroes/warp_beast/warp_beast_warp.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_warp_effect", "scripts/vscripts/heroes/warp_beast/warp_beast_warp.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_warp_castrange_buffer", "scripts/vscripts/heroes/warp_beast/warp_beast_warp.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_mana_eater_bonus_mana_count", "scripts/vscripts/heroes/warp_beast/warp_beast_warp.lua", LUA_MODIFIER_MOTION_NONE)

warp_beast_warp = class({})

function warp_beast_warp:GetIntrinsicModifierName()
	return "modifier_warp"
end

function warp_beast_warp:OnToggle()
	local caster = self:GetCaster()

	if self:GetToggleState() then
		caster:AddNewModifier(caster, self, "modifier_warp_indicator", {})
	else
		caster:RemoveModifierByName("modifier_warp_indicator")
	end
end

function warp_beast_warp:GetCastRange(vLocation, hTarget)
	return self:GetSpecialValueFor("distance_per_mana") * self:GetCaster():GetMana()
end

function warp_beast_warp:CanWarp(maxCastRange, castPosition, ability)
	local caster = self:GetCaster()
	local distancePerMana = self:GetSpecialValueFor("distance_per_mana")
	local talent = caster:FindAbilityByName("special_bonus_unique_warp_beast_warp_mana_pool")
	if talent and talent:GetLevel() > 0 then
		distancePerMana = distancePerMana + talent:GetSpecialValueFor("value")
	end
	local distance = (castPosition - caster:GetAbsOrigin()):Length2D()

	local manaCost = ability:GetManaCost(-1)
	local currentWarpMana = caster:GetMana()
	local warpManaCost = (distance - maxCastRange) / distancePerMana

	-- print("Warp active status: " .. (currentWarpMana >= warpManaCost + manaCost))
	return currentWarpMana >= warpManaCost + manaCost
end

function warp_beast_warp:Warp(maxCastRange, castPosition, ability, order)
	local caster = self:GetCaster()

	local distancePerMana = self:GetSpecialValueFor("distance_per_mana")
	local talent1 = caster:FindAbilityByName("special_bonus_unique_warp_beast_warp_mana_pool")
	if talent1 and talent1:GetLevel() > 0 then
		distancePerMana = distancePerMana + talent1:GetSpecialValueFor("value")
	end
	local warpDuration = self:GetSpecialValueFor("warp_duration")

	local latchModifier = caster:FindModifierByName("modifier_latch")
	if latchModifier then
		if latchModifier.target then latchModifier.target:RemoveModifierByNameAndCaster("modifier_latch_target", caster) end
		caster:RemoveModifierByName("modifier_latch")
	end

	-- DebugDrawSphere(castPosition, Vector(255,255,255), 1, maxCastRange, true, 2)
	local origin = caster:GetAbsOrigin()
	local castVector = castPosition + caster:GetForwardVector() * RandomFloat(maxCastRange / 3, maxCastRange - 50)
	local angle = RandomInt(0, 360)

	local warpPosition = RotatePosition(castPosition, QAngle(0,angle, 0), castVector)
	local forwardVec = (castPosition - warpPosition):Normalized()

	local distance = (castPosition - caster:GetAbsOrigin()):Length2D()
	local warpManaCost = (distance - maxCastRange) / distancePerMana

	caster:StartGesture(ACT_DOTA_SPAWN)
	caster:Stop()
	caster:Hold()
	caster:AddNewModifier(caster, self, "modifier_warp_effect", {duration = warpDuration + 0.5})
	caster:AddNewModifier(caster, self, "modifier_rooted", {duration = warpDuration + 0.1})

	local talent2 = caster:FindAbilityByName("special_bonus_unique_warp_beast_warp_silence")
	if talent2 and talent2:GetLevel() > 0 then
		local units = FindUnitsInRadius(caster:GetTeamNumber(), warpPosition, nil, talent2:GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
		for _, unit in pairs(units) do
			if unit and not unit:IsNull() then
				unit:AddNewModifier(caster, self, "modifier_silence", {duration = talent2:GetSpecialValueFor("value")})
			end
		end
	end

	self:CreateVisibilityNode(warpPosition, 300, 0.5)

	local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_warp_beast/warp_beast_warp_in_beam.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(particle, 0, warpPosition)
	ParticleManager:SetParticleControl(particle, 1, Vector(150,0,0))
	ParticleManager:SetParticleControl(particle, 2, Vector(50,0,0))

	EmitSoundOnLocationWithCaster(warpPosition, "Hero_Warp_Beast.Warp", caster)

	local particle2 = ParticleManager:CreateParticle("particles/units/heroes/hero_warp_beast/warp_beast_warp_in_beam.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(particle2, 0, caster:GetAbsOrigin())
	ParticleManager:SetParticleControl(particle2, 1, Vector(150,0,0))
	ParticleManager:SetParticleControl(particle2, 2, Vector(50,0,0))

	EmitSoundOnLocationWithCaster(caster:GetAbsOrigin(), "Hero_Warp_Beast.Warp", caster)

	Timers:CreateTimer(warpDuration, function()
		caster:RemoveModifierByNameAndCaster("modifier_rooted", caster)
		caster:RemoveGesture(ACT_DOTA_SPAWN)
		if not caster:IsStunned() and not caster:IsSilenced() and not caster:IsRooted() and not caster:IsLeashedCustom() then
			caster:SpendMana(warpManaCost, self)
			ProjectileManager:ProjectileDodge(caster)
			FindClearSpaceForUnit(caster, Vector(warpPosition.x, warpPosition.y, origin.z), true)
			caster:SetForwardVector(forwardVec)
			caster:AddNewModifier(caster, self, "modifier_warp_castrange_buffer", {duration = 0.1})
			caster:EmitSound("Hero_Warp_Beast.Warp.Portal")
			caster:RemoveModifierByName("modifier_warp_effect")
			ExecuteOrderFromTable(order)
			-- Timers:CreateTimer(1, function() ExecuteOrderFromTable(order) return nil end )
		end
	end)

	-- Timers:CreateTimer(WARP_DURATION + 0.05, function()
	-- 	caster:SetModelScale(self.modelSize)
	-- end)

end

---------------------------------------------------------------------------------------------------

modifier_warp = class({})

function modifier_warp:IsHidden()
	return true
end

function modifier_warp:IsPermanent()
	return true
end

function modifier_warp:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ABILITY_START,
		MODIFIER_EVENT_ON_ORDER,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
		MODIFIER_EVENT_ON_DEATH,
	}
end

if IsServer() then
	local cast_orders = {
		[DOTA_UNIT_ORDER_CAST_POSITION] = true,
		[DOTA_UNIT_ORDER_CAST_TARGET] = true,
	}

	function modifier_warp:OnAbilityStart(event)
		local caster = self:GetCaster()
		if event.unit == caster and caster:IsRealHero() then
			caster:RemoveModifierByNameAndCaster("modifier_warp_effect", caster)
		end
	end

	function modifier_warp:OnOrder(event)
		local caster = self:GetCaster()
		local warpAbility = self:GetAbility()
		if event.unit == caster and caster:IsRealHero() then
			-- Stop checking if issuing commands other than toggles
			if event.order_type ~= DOTA_UNIT_ORDER_CAST_TOGGLE then self.checkRange = false end
			if cast_orders[event.order_type] and not caster:IsSilenced() and not caster:IsRooted() and not caster:IsLeashedCustom() then
				local ability = event.ability

				local order = {
					UnitIndex = caster:GetEntityIndex(),
					OrderType = event.order_type,
					AbilityIndex = event.ability:GetEntityIndex(),
					Queue = false
				}

				local castPosition
				if event.target then
					castPosition = event.target:GetAbsOrigin()
					order.Position = event.target:GetAbsOrigin()
					order.TargetIndex = event.target:GetEntityIndex()
				else
					castPosition = event.new_pos
					order.Position = event.new_pos
				end

				if order.Position.z > 1200 then return end

				self.checkRange = true

				local maxCastRange = ability:GetCastRange(castPosition, caster) + caster:GetCastRangeBonus()
				--print("Max cast range is: "..maxCastRange)
				local warpRange = maxCastRange
				if warpRange > 600 then
					warpRange = 600
				end
				local distance = (caster:GetAbsOrigin() - castPosition):Length2D()
				if maxCastRange > 0 and maxCastRange < distance then
					Timers:CreateTimer(0, function()
						if order and self.checkRange then
							if warpAbility:GetToggleState() and warpAbility:CanWarp(warpRange, castPosition, ability) then
								self.checkRange = false
								caster:Stop()
								warpAbility:Warp(warpRange, castPosition, ability, order)
								return nil
							end
							return 0.1
						else
							return nil
						end
					end)
				end
			end
		end
	end

	function modifier_warp:OnAttackLanded(event)
		local parent = self:GetParent()
		local attacker = event.attacker
		local target = event.target

		-- Check if attacker exists
		if not attacker or attacker:IsNull() then
			return
		end

		-- Check if attacker has this modifier
		if parent ~= attacker then
			return
		end

		-- No mana drain/gain while broken
		if parent:PassivesDisabled() then
			return
		end

		-- Check if attacked entity exists
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

		if target:IsIllusion() then
			return
		end

		if target:GetMana() > 0 then
			local ability = self:GetAbility()
			local drainAmount = ability:GetSpecialValueFor("drain_amount")
			local duration = ability:GetSpecialValueFor("bonus_duration")

			-- Talent that increases mana drain/gain
			local talent = parent:FindAbilityByName("special_bonus_unique_warp_beast_mana_eater")
			if talent and talent:GetLevel() > 0 then
				drainAmount = drainAmount + talent:GetSpecialValueFor("value")
			end

			--local targetMana = target:GetMana()
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
						modifier = parent:AddNewModifier(parent, ability, "modifier_mana_eater_bonus_mana_count", {duration = duration})
						if modifier then
							modifier:SetStackCount(math.min(drainAmount - missingMana, ability:GetSpecialValueFor("bonus_mana_cap")))
						end
					end
					parent:CalculateStatBonus(true)
				end
				parent:GiveMana(drainAmount)
			end

			--target:ReduceMana(drainAmount, ability)

			target:EmitSound("Hero_Warp_Beast.ManaEater")

			local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_warp_beast/warp_beast_mana_eater.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
			ParticleManager:SetParticleControlEnt(particle, 1, parent, PATTACH_POINT_FOLLOW, "attach_eye_l", Vector(0,0,0), true)
		end
	end

	function modifier_warp:OnDeath(event)
		local parent = self:GetParent()
		local attacker = event.attacker
		local dead = event.unit

		-- Check if attacker exists
		if not attacker or attacker:IsNull() then
			return
		end

		-- Check if attacker has this modifier
		if parent ~= attacker then
			return
		end

		-- No mana drain/gain on kill while broken or for illusions
		if parent:PassivesDisabled() or parent:IsIllusion() then
			return
		end

		-- Check if attacked entity exists
		--if not dead or dead:IsNull() then
			--return
		--end

		-- Check for existence of GetUnitName method to determine if target is a unit or an item
		-- items don't have that method -> nil; if the target is an item, don't continue
		if dead.GetUnitName == nil then
			return
		end

		-- If the attack target is a building or a ward then stop (return)
		if dead:IsTower() or dead:IsBarracks() or dead:IsBuilding() or dead:IsOther() or dead:IsIllusion() then
			return
		end

		if dead:GetMaxMana() < 1 then
			return
		end

		local dead_mana = dead:GetMaxMana()
		local ability = self:GetAbility()

		local drainAmount = ability:GetSpecialValueFor("kill_drain_percentage") * dead_mana / 100
		local duration = ability:GetSpecialValueFor("bonus_duration")

		local missingMana = parent:GetMaxMana() - parent:GetMana()
		if missingMana < drainAmount then
			local modifier = parent:FindModifierByName("modifier_mana_eater_bonus_mana_count")
			if modifier then
				modifier:SetDuration(duration, true)
				modifier:SetStackCount(math.min(modifier:GetStackCount() + drainAmount - missingMana, ability:GetSpecialValueFor("bonus_mana_cap")))
			else
				modifier = parent:AddNewModifier(parent, ability, "modifier_mana_eater_bonus_mana_count", {duration = duration})
				if modifier then
					modifier:SetStackCount(math.min(drainAmount - missingMana, ability:GetSpecialValueFor("bonus_mana_cap")))
				end
			end
			parent:CalculateStatBonus(true)
		end

		parent:GiveMana(drainAmount)
	end
end

---------------------------------------------------------------------------------------------------

modifier_warp_effect = class({})

function modifier_warp_effect:IsHidden()
	return true
end

function modifier_warp_effect:IsDebuff()
	return false
end

function modifier_warp_effect:IsPurgable()
	return false
end

function modifier_warp_effect:CheckState()
	return {
		[MODIFIER_STATE_COMMAND_RESTRICTED] = true,
		[MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
		[MODIFIER_STATE_NO_HEALTH_BAR] = true
		-- [MODIFIER_STATE_FROZEN] = true
	}
end

---------------------------------------------------------------------------------------------------

modifier_warp_castrange_buffer = class({})

function modifier_warp_castrange_buffer:IsHidden()
	return true
end

function modifier_warp_castrange_buffer:IsDebuff()
	return false
end

function modifier_warp_castrange_buffer:IsPurgable()
	return false
end

function modifier_warp_castrange_buffer:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_CAST_RANGE_BONUS,
	}
end

function modifier_warp_castrange_buffer:GetModifierCastRangeBonus()
	return 600
end

---------------------------------------------------------------------------------------------------

modifier_warp_indicator = class({})

function modifier_warp_indicator:IsHidden()
	return false
end

function modifier_warp_indicator:IsDebuff()
	return false
end

function modifier_warp_indicator:IsPurgable()
	return false
end

function modifier_warp_indicator:IsPermanent()
	return true
end

---------------------------------------------------------------------------------------------------

modifier_mana_eater_bonus_mana_count = class({})

function modifier_mana_eater_bonus_mana_count:IsHidden()
	return false
end

function modifier_mana_eater_bonus_mana_count:IsDebuff()
	return false
end

function modifier_mana_eater_bonus_mana_count:IsPurgable()
	return false
end

function modifier_mana_eater_bonus_mana_count:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_EXTRA_MANA_BONUS,
		MODIFIER_EVENT_ON_SPENT_MANA
	}
end

function modifier_mana_eater_bonus_mana_count:GetModifierExtraManaBonus()
	return self:GetStackCount()
end

if IsServer() then
	function modifier_mana_eater_bonus_mana_count:OnSpentMana(keys)
		if keys.unit == self:GetParent() then
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
