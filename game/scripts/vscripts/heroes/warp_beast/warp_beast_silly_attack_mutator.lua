LinkLuaModifier("modifier_silly_attack_mutator", "scripts/vscripts/heroes/warp_beast/warp_beast_silly_attack_mutator.lua", LUA_MODIFIER_MOTION_NONE)


warp_beast_silly_attack_mutator = class({})

function warp_beast_silly_attack_mutator:GetIntrinsicModifierName()
	return "modifier_silly_attack_mutator"
end

modifier_silly_attack_mutator = class({})

function modifier_silly_attack_mutator:IsHidden()
	return true
end

function modifier_silly_attack_mutator:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MODEL_SCALE,
		MODIFIER_EVENT_ON_ATTACK_START,
		MODIFIER_EVENT_ON_ATTACK_FINISHED
	}
	return funcs
end

-- Warp Beast grows bigger with levels (lvl 25 = 50% bigger)
function modifier_silly_attack_mutator:GetModifierModelScale()
	return self:GetParent():GetLevel() * 2
end

function modifier_silly_attack_mutator:OnAttackStart(keys)
	if keys.attacker == self:GetCaster() then
		self:GetCaster():StartGestureWithPlaybackRate(ACT_DOTA_DIE, self:GetCaster():GetAttacksPerSecond() * 1.5)
	end
end

function modifier_silly_attack_mutator:OnAttackFinished(keys)
	if keys.attacker == self:GetCaster() then
		self:GetCaster():FadeGesture(ACT_DOTA_DIE)
	end
end