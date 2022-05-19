modifier_custom_passive_gold = class({})

function modifier_custom_passive_gold:IsHidden()
	return true
end

function modifier_custom_passive_gold:IsPurgable()
	return false
end

function modifier_custom_passive_gold:RemoveOnDeath()
	return false
end

function modifier_custom_passive_gold:OnCreated()
	if not IsServer() then
		return
	end
	local parent = self:GetParent()
	if parent.original or parent:IsIllusion() then
		self:Destroy()
		return
	end
	local gpm = 100
	if gpm ~= 0 then
		self.goldTickTime = 60/gpm
		self.goldPerTick = 1
	else
		self.goldTickTime = -1
		self.goldPerTick = 0
		self:Destroy()
	end
	self:StartIntervalThink(self.goldTickTime)
end

function modifier_custom_passive_gold:OnIntervalThink()
	if not IsServer() then
		return
	end
	local parent = self:GetParent()
	local game_state = GameRules:State_Get()
	if game_state >= DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		parent:ModifyGold(self.goldPerTick, false, DOTA_ModifyGold_GameTick)
	end
end
