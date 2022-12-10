modifier_custom_courier = class({})

function modifier_custom_courier:IsHidden()
	return true
end

function modifier_custom_courier:IsPurgable()
	return false
end

function modifier_custom_courier:RemoveOnDeath()
	return false
end

function modifier_custom_courier:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
		MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
		MODIFIER_PROPERTY_MOVESPEED_LIMIT,
		MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE,
		MODIFIER_PROPERTY_VISUAL_Z_DELTA,
		--MODIFIER_EVENT_ON_TAKEDAMAGE
	}
end

function modifier_custom_courier:GetAbsoluteNoDamageMagical()
	return 1
end

function modifier_custom_courier:GetAbsoluteNoDamagePhysical()
	return 1
end

function modifier_custom_courier:GetAbsoluteNoDamagePure()
	return 1
end

function modifier_custom_courier:GetModifierExtraHealthBonus()
	return 5000 -- So Axe cannot kill it with Culling Blade
end

function modifier_custom_courier:CheckState()
	return {
		[MODIFIER_STATE_FLYING] = true,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
		[MODIFIER_STATE_BLIND] = true,
		[MODIFIER_STATE_INVULNERABLE] = true,
		--[MODIFIER_STATE_NO_HEALTH_BAR] = true
	}
end
--[[
function modifier_custom_courier:OnTakeDamage(event)
	if event.unit == self:GetParent() then
		--print("Courier has taken damage")
		local parent = self:GetParent()
		parent.taken_damage = true

		Timers:CreateTimer(1, function()
			parent.taken_damage = false
		end)
	end
end
]]

function modifier_custom_courier:GetModifierMoveSpeed_Limit()
	--local parent = self:GetParent()
	--if parent.taken_damage then
		--return 100
	--end
	return 550
end

function modifier_custom_courier:GetModifierMoveSpeed_Absolute()
	--local parent = self:GetParent()
	--if parent.taken_damage then
		--return 100
	--end
	return 550
end

function modifier_custom_courier:GetVisualZDelta()
	return 220
end
