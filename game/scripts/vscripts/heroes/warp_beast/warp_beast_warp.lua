LinkLuaModifier("modifier_warp", "scripts/vscripts/heroes/warp_beast/warp_beast_warp.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_warp_indicator", "scripts/vscripts/heroes/warp_beast/warp_beast_warp.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_warp_effect", "scripts/vscripts/heroes/warp_beast/warp_beast_warp.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_warp_castrange_buffer", "scripts/vscripts/heroes/warp_beast/warp_beast_warp.lua", LUA_MODIFIER_MOTION_NONE)

warp_beast_warp = class({})

function warp_beast_warp:GetIntrinsicModifierName()
	return "modifier_warp"
end

function warp_beast_warp:OnToggle()
	if not IsServer() then return end

	local caster = self:GetCaster()

	if self:GetToggleState() then
		caster:AddNewModifier(caster, self, "modifier_warp_indicator", {})
	else
		caster:RemoveModifierByName("modifier_warp_indicator")
	end
end

function warp_beast_warp:GetCastRange()
	return self:GetSpecialValueFor("distance_per_mana") * self:GetCaster():GetMana()
end

function warp_beast_warp:CanWarp(maxCastRange, castPosition, ability)
	local caster = self:GetCaster()
	local distancePerMana = self:GetSpecialValueFor("distance_per_mana")
	local talent = caster:FindAbilityByName("special_bonus_unique_warp_beast_warp_mana_pool")
	if talent then
		if talent:GetLevel() ~= 0 then
			distancePerMana = distancePerMana + talent:GetSpecialValueFor("value")
		end
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
	if talent1 then
		if talent1:GetLevel() ~= 0 then
			distancePerMana = distancePerMana + talent1:GetSpecialValueFor("value")
		end
	end
	local warpDuration = self:GetSpecialValueFor("warp_duration")

	local manaCost = ability:GetManaCost(-1)

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
	
	local currentWarpMana = caster:GetMana()
	local warpManaCost = (distance - maxCastRange) / distancePerMana

	caster:StartGesture(ACT_DOTA_SPAWN)
	caster:Stop()
	caster:Hold()
	caster:AddNewModifier(caster, self, "modifier_warp_effect", {Duration = warpDuration + 0.5})
	caster:AddNewModifier(caster, self, "modifier_rooted", {Duration = warpDuration + 0.1})

	local talent2 = caster:FindAbilityByName("special_bonus_unique_warp_beast_warp_silence")
	if talent2 then
		if talent2:GetLevel() ~= 0 then
			local units = FindUnitsInRadius(caster:GetTeamNumber(), warpPosition, nil, talent2:GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
			for k, unit in pairs(units) do
				if unit then
					unit:AddNewModifier(caster, self, "modifier_silence", {duration = talent2:GetSpecialValueFor("value")})
				end
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
		if not caster:IsStunned() and not caster:IsSilenced() and not caster:IsRooted() then
			caster:SpendMana(warpManaCost, self)
			ProjectileManager:ProjectileDodge(caster)
			FindClearSpaceForUnit(caster, Vector(warpPosition.x, warpPosition.y, origin.z), true)
			-- caster:SetAbsOrigin(Vector(warpPosition.x, warpPosition.y, origin.z))
			caster:SetForwardVector(forwardVec)
			caster:AddNewModifier(caster, self, "modifier_warp_castrange_buffer", {Duration = 0.1})
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

---------------------------------------------------------------------------------------------------------------

modifier_warp = class({})

if IsServer() then
	cast_orders = {
    	[DOTA_UNIT_ORDER_CAST_POSITION] = true,
    	[DOTA_UNIT_ORDER_CAST_TARGET] = true,
	}
end

function modifier_warp:IsHidden()
	return true
end


function modifier_warp:IsPermanent()
	return true
end

function modifier_warp:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_ABILITY_START,
		MODIFIER_EVENT_ON_ORDER,
	}
	return funcs
end

function modifier_warp:OnAbilityStart(event)
	if IsServer() and event.unit == self:GetCaster() and self:GetCaster():IsRealHero() then
		self:GetCaster():RemoveModifierByNameAndCaster("modifier_warp_effect", self:GetCaster())
	end
end


function modifier_warp:OnOrder(event)
	if IsServer() and event.unit == self:GetCaster() and self:GetCaster():IsRealHero() then
		-- Stop checking if issuing commands other than toggles
		if event.order_type ~= DOTA_UNIT_ORDER_CAST_TOGGLE then self.checkRange = false end
		if cast_orders[event.order_type] and not self:GetCaster():IsSilenced() and not self:GetCaster():IsRooted() then
			local caster = self:GetCaster()
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

			local maxCastRange = ability:GetCastRange(castPosition, caster)+250 -- + caster:GetCastRangeBonus()
			local warpRange = maxCastRange
			if maxCastRange > 600 then 
				warpRange = 600
			end
			local distance = (caster:GetAbsOrigin() - castPosition):Length2D()
			if maxCastRange > 0 and maxCastRange < distance then
				Timers.CreateTimer(0, function()
					local warpAbility = self:GetAbility()
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

---------------------------------------------------------------------------------------------------------------

modifier_warp_effect = class({})

function modifier_warp_effect:CheckState()
	local states = {
		[MODIFIER_STATE_COMMAND_RESTRICTED] = true,
		[MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
		[MODIFIER_STATE_NO_HEALTH_BAR] = true
		-- [MODIFIER_STATE_FROZEN] = true
	}

	return states
end

function modifier_warp_effect:IsHidden()
	return true
end

modifier_warp_castrange_buffer = class({})

function modifier_warp_castrange_buffer:IsHidden()
	return true
end


function modifier_warp_castrange_buffer:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_CAST_RANGE_BONUS	
	}

	return funcs
end

function modifier_warp_castrange_buffer:GetModifierCastRangeBonus()
	return 600
end

modifier_warp_indicator = class({})

function modifier_warp_indicator:IsPermanent()
	return true
end
