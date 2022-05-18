modifier_custom_passive_xp = class({})

function modifier_custom_passive_xp:IsHidden()
	return true
end

function modifier_custom_passive_xp:IsPurgable()
	return false
end

function modifier_custom_passive_xp:RemoveOnDeath()
	return false
end

function modifier_custom_passive_xp:OnCreated()
	if not IsServer() then
		return
	end
	local parent = self:GetParent()
	if parent.original or parent:IsIllusion() then
		self:Destroy()
		return
	end
	local xpm = 10
	if xpm ~= 0 then
		self.xpTickTime = 60/xpm
		self.xpPerTick = 1
	else
		self.xpTickTime = -1
		self.xpPerTick = 0
		self:Destroy()
	end
	self:StartIntervalThink(self.xpTickTime)
end

function modifier_custom_passive_xp:OnIntervalThink()
	if not IsServer() then
		return
	end
	local parent = self:GetParent()
	local game_state = GameRules:State_Get()
	if game_state >= DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		parent:AddExperience(self.xpPerTick, DOTA_ModifyXP_Unspecified, false, true)
	end
end
