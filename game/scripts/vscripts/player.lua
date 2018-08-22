if not CDOTA_PlayerResource.UserIDToPlayerID then
	CDOTA_PlayerResource.UserIDToPlayerID = {}
end
if CDOTA_PlayerResource.PlayerData == nil then
	CDOTA_PlayerResource.PlayerData = {}
end

-- PlayerID stays the same after disconnect/reconnect
-- Player is volatile; After disconnect its destroyed.
-- what about userid?
function CDOTA_PlayerResource:OnPlayerConnect(event)
    local userID = event.userid
    local playerID = event.index -- or event.PlayerID

	if not self.PlayerData[playerID] then
        self.UserIDToPlayerID[userID] = playerID
        self.PlayerData[playerID] = {}
    end
end

-- Verifies if this player ID already has player data assigned to it
function CDOTA_PlayerResource:IsRealPlayer(playerID)
	if self.PlayerData[playerID] then
		return true
	else
		return false
	end
end

-- Assigns a hero to a player
function CDOTA_PlayerResource:AssignHero(playerID, hero_entity)
	if self:IsRealPlayer(playerID) then
		self.PlayerData[playerID].hero = hero_entity
		self.PlayerData[playerID].hero_name = hero_entity:GetUnitName()
		print("Assigned "..self.PlayerData[playerID].hero_name.." to player with ID "..playerID)
	end
end

-- Fetches a player's hero
function CDOTA_PlayerResource:GetAssignedHero(playerID)
	if self:IsRealPlayer(playerID) then
		local player = self:GetPlayer(playerID) -- can be nil if this check is not delayed 1 or more frames
		if player then 
			local hero = player:GetAssignedHero()
			if hero then
				return hero
			else
				return self.PlayerData[playerID].hero
			end
		else
			return self.PlayerData[playerID].hero
		end
	elseif self:IsFakeClient(playerID) then
		-- For bots
		local player = self:GetPlayer(playerID)
		return player:GetAssignedHero()
	end
	return nil
end

-- Fetches a player's hero name
function CDOTA_PlayerResource:GetAssignedHeroName(playerID)
	if self:IsRealPlayer(playerID) then
		return self.PlayerData[playerID].hero_name
	end
	return nil
end

-- Set a player's abandonment due to long disconnect status
function CDOTA_PlayerResource:SetHasAbandonedDueToLongDisconnect(playerID, state)
	if self:IsRealPlayer(playerID) then
		self.PlayerData[playerID]["has_abandoned_due_to_long_disconnect"] = state
		print("Set player "..playerID.." 's abandon due to long disconnect state as "..tostring(state))
	end
end

-- Fetch a player's abandonment due to long disconnect status
function CDOTA_PlayerResource:GetHasAbandonedDueToLongDisconnect(playerID)
	if self:IsRealPlayer(playerID) then
		return self.PlayerData[playerID]["has_abandoned_due_to_long_disconnect"]
	else
		return false
	end
end

-- Increase a player's team's player count
function CDOTA_PlayerResource:IncrementTeamPlayerCount(playerID)
	if self:IsRealPlayer(playerID) then
		if self:GetTeam(playerID) == DOTA_TEAM_GOODGUYS then
			REMAINING_GOODGUYS = REMAINING_GOODGUYS + 1
			print("Radiant now has "..REMAINING_GOODGUYS.." players remaining")
		else
			REMAINING_BADGUYS = REMAINING_BADGUYS + 1
			print("Dire now has "..REMAINING_BADGUYS.." players remaining")
		end
	end
end

-- Decrease a player's team's player count
function CDOTA_PlayerResource:DecrementTeamPlayerCount(playerID)
	if self:IsRealPlayer(playerID) then
		if self:GetTeam(playerID) == DOTA_TEAM_GOODGUYS then
			REMAINING_GOODGUYS = REMAINING_GOODGUYS - 1
			print("Radiant now has "..REMAINING_GOODGUYS.." players remaining")
		else
			REMAINING_BADGUYS = REMAINING_BADGUYS - 1
			print("Dire now has "..REMAINING_BADGUYS.." players remaining")
		end
	end
end

-- While active, redistributes a player's gold to its allies
function CDOTA_PlayerResource:StartAbandonGoldRedistribution(playerID)

	-- Set redistribution as active
	self.PlayerData[playerID]["distribute_gold_to_allies"] = true
	print("player "..playerID.." is now redistributing gold to its allies.")

	-- Fetch this player's team
	local player_team = self:GetTeam(playerID)
	local current_gold = self:GetGold(playerID)
	local current_allies = {}
	local ally_amount = 0
	local gold_per_interval = 3 * ( 1 + CUSTOM_GOLD_BONUS * 0.01 ) / GOLD_TICK_TIME

	-- Distribute initial gold
	for id = 0, 19 do
		if self:IsRealPlayer(id) and (not self.PlayerData[id]["distribute_gold_to_allies"]) and self:GetTeam(id) == player_team then
			current_allies[#current_allies + 1] = id
		end
	end

	-- If there is at least one ally to redirect gold to, do it
	ally_amount = #current_allies
	if ally_amount >= 1 and current_gold >= ally_amount then
		local gold_to_share = current_gold - (current_gold % ally_amount)
		local gold_per_ally = gold_to_share / ally_amount
		for _,ally_id in pairs(current_allies) do
			self:ModifyGold(ally_id, gold_per_ally, false, DOTA_ModifyGold_AbandonedRedistribute)
		end
		print("distributed "..gold_to_share.." gold initially ("..gold_per_ally.." per ally)")
	end

	-- Update the variables to start the cycle
	current_gold = current_gold % ally_amount
	ally_amount = 0
	current_allies = {}

	-- Start the redistribution cycle
	Timers:CreateTimer(3, function()

		-- Update gold according to passive gold gain
		current_gold = current_gold + gold_per_interval

		-- Update active ally amount
		for id = 0, 19 do
			if self:IsRealPlayer(id) and (not self.PlayerData[id]["distribute_gold_to_allies"]) and self:GetTeam(id) == player_team then
				current_allies[#current_allies + 1] = id
			end
		end

		-- If there is at least one ally to redirect gold to, do it
		ally_amount = #current_allies
		if ally_amount >= 1 and current_gold >= ally_amount then
			local gold_to_share = current_gold - (current_gold % ally_amount)
			local gold_per_ally = gold_to_share / ally_amount
			for _,ally_id in pairs(current_allies) do
				self:ModifyGold(ally_id, gold_per_ally, false, DOTA_ModifyGold_AbandonedRedistribute)
			end
			print("distributed "..gold_to_share.." gold ("..gold_per_ally.." per ally)")
		end

		-- Update variables
		current_gold = current_gold % ally_amount
		current_allies = {}
		ally_amount = 0

		-- Keep going, if applicable
		if self.PlayerData[playerID]["distribute_gold_to_allies"] then
			return 3
		end
	end)
end

-- Stops a specific player from redistributing their gold to its allies
function CDOTA_PlayerResource:StopAbandonGoldRedistribution(playerID)
	self.PlayerData[playerID]["distribute_gold_to_allies"] = false
	self:ModifyGold(playerID, -self:GetGold(playerID), false, DOTA_ModifyGold_AbandonedRedistribute)
	print("player "..playerID.." is no longer redistributing gold to its allies.")
end
