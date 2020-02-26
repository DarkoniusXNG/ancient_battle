modifier_custom_passive_gold = class({})

function modifier_custom_passive_gold:IsPermanent()
	return true
end

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
	local parent = self:GetParent()
	if not IsServer() then
		return
	end
	if GetMapName() ~= "two_vs_two" or parent.original then
		self:Destroy()
	end
	self:StartIntervalThink(GOLD_TICK_TIME)
end

function modifier_custom_passive_gold:OnIntervalThink()
	if not IsServer() then
		return
	end
	local parent = self:GetParent()
	local game_state = GameRules:State_Get()
	if game_state >= DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		parent:ModifyGold(GOLD_PER_TICK, false, DOTA_ModifyGold_GameTick)
	end
end
