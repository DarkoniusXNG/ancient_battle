if not CDOTA_PlayerResource.UserIDToPlayerID then
	CDOTA_PlayerResource.UserIDToPlayerID = {}
end
if CDOTA_PlayerResource.PlayerData == nil then
	CDOTA_PlayerResource.PlayerData = {}
end

-- PlayerID stays the same after disconnect/reconnect
-- Player handle is volatile; After disconnect it's destroyed.

function CDOTA_PlayerResource:InitPlayerDataForID(playerID)
	print("[BAREBONES] Initializing PlayerResource's PlayerData for the player with ID: "..tostring(playerID))
	if not self:IsValidPlayerID(playerID) then
		return
	end
	if not self.PlayerData[playerID] then
		self.PlayerData[playerID] = {}
	end
	self.PlayerData[playerID].has_abandoned_due_to_long_disconnect = false
	self.PlayerData[playerID].distribute_gold_to_allies = false
	self.PlayerData[playerID].hero_name = self.PlayerData[playerID].hero_name or "Something went wrong"
	self.PlayerData[playerID].already_set_hero = false
end

function CDOTA_PlayerResource:OnPlayerConnect(event)
	local userID = event.userid
	local playerID = event.PlayerID or event.player_id
	if not playerID then
		if event.index then
			playerID = event.index - 1
			print("player_connect_full event doesn't contain PlayerID or player_id key!")
		else
			print("player_connect_full event doesn't contain PlayerID, player_id or index key! Thanks Valve")
		end
	end
	
	if userID then
		self.UserIDToPlayerID[userID] = playerID
	end
	if self:IsValidPlayerID(playerID) then
		self:InitPlayerDataForID(playerID)
	end
end

-- Verifies if this player ID already has player data assigned to it
function CDOTA_PlayerResource:IsRealPlayer(playerID)
	if self.PlayerData[playerID] then
		return true
	else
		if self:IsFakeClient(playerID) or not self:IsValidPlayerID(playerID) or not self:GetPlayer(playerID) then
			return false
		else
			self:InitPlayerDataForID(playerID)
			return true
		end
	end
end

-- Assigns a hero to a player
function CDOTA_PlayerResource:AssignHero(playerID, hero_entity)
	if not self.PlayerData[playerID] and self:IsValidPlayerID(playerID) then
		self:InitPlayerDataForID(playerID)
	end
	local hero = hero_entity
	if not hero then
		hero = self:GetBarebonesAssignedHero(playerID)
	end
	self.PlayerData[playerID].hero = hero
	self.PlayerData[playerID].hero_name = hero:GetUnitName()
	print("[BAREBONES] Assigned "..self.PlayerData[playerID].hero_name.." to the player with ID: "..tostring(playerID))
end

-- Fetches a player's hero
function CDOTA_PlayerResource:GetBarebonesAssignedHero(playerID)
  local player = self:GetPlayer(playerID)
  if self:IsRealPlayer(playerID) then
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
    return player:GetAssignedHero()
  else
    if player then
      return player:GetAssignedHero()
    end
  end
  return nil
end

-- Fetches a player's hero name
function CDOTA_PlayerResource:GetAssignedHeroName(playerID)
	if not self.PlayerData[playerID] and self:IsValidPlayerID(playerID) then
		self:InitPlayerDataForID(playerID)
		local player = self:GetPlayer(playerID)
		if player then
			local hero = player:GetAssignedHero()
			if hero then
				self.PlayerData[playerID].hero_name = hero:GetUnitName()
			end
		end
	end

	return self.PlayerData[playerID].hero_name
end

-- DotA Connection states:
-- DOTA_CONNECTION_STATE_UNKNOWN	0
-- DOTA_CONNECTION_STATE_NOT_YET_CONNECTED	1	
-- DOTA_CONNECTION_STATE_CONNECTED	2	
-- DOTA_CONNECTION_STATE_DISCONNECTED	3	
-- DOTA_CONNECTION_STATE_ABANDONED	4	
-- DOTA_CONNECTION_STATE_LOADING	5	
-- DOTA_CONNECTION_STATE_FAILED	6

-- Is a player with this playerID connected?
function CDOTA_PlayerResource:IsConnected(playerID)
	if self:GetConnectionState(playerID) == DOTA_CONNECTION_STATE_CONNECTED then
		return true
	end
	if IsInToolsMode() and self:GetConnectionState(playerID) == DOTA_CONNECTION_STATE_NOT_YET_CONNECTED then
		return true
	end
	return false
end

-- Find how many players didn't abandon
function CDOTA_PlayerResource:GetPlayerCountWithoutLeavers()
    local count = 0
     for playerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
        if self:IsValidPlayerID(playerID) then
			if self:GetConnectionState(playerID) ~= DOTA_CONNECTION_STATE_ABANDONED then
				count = count + 1
			end
        end
    end
    return count
end

-- Set a player's abandonment due to long disconnect status
function CDOTA_PlayerResource:SetHasAbandonedDueToLongDisconnect(playerID, state)
	if self:IsRealPlayer(playerID) then
		self.PlayerData[playerID].has_abandoned_due_to_long_disconnect = state
		print("Set player "..playerID.." 's abandon due to long disconnect state as "..tostring(state))
	end
end

-- Fetch a player's abandonment due to long disconnect status
function CDOTA_PlayerResource:GetHasAbandonedDueToLongDisconnect(playerID)
	if self:IsRealPlayer(playerID) then
		return self.PlayerData[playerID].has_abandoned_due_to_long_disconnect
	else
		return false
	end
end

-- While active, redistributes a player's gold to its allies (Work in Progress)
function CDOTA_PlayerResource:StartAbandonGoldRedistribution(playerID)

	-- Set redistribution as active
	self.PlayerData[playerID].distribute_gold_to_allies = true
	print("player "..playerID.." is now redistributing gold to its allies.")

	-- Fetch this player's team
	local player_team = self:GetTeam(playerID)
	local current_gold = self:GetGold(playerID)
	local current_allies = {}
	local ally_amount = 0
	local gold_per_interval = GOLD_PER_TICK

	-- Distribute initial gold
	for id = 0, DOTA_MAX_TEAM_PLAYERS-1 do
		if self:IsRealPlayer(id) and (not self.PlayerData[id].distribute_gold_to_allies) and self:GetTeam(id) == player_team then
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
		for id = 0, DOTA_MAX_TEAM_PLAYERS-1 do
			if self:IsRealPlayer(id) and (not self.PlayerData[id].distribute_gold_to_allies) and self:GetTeam(id) == player_team then
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
		if self.PlayerData[playerID].distribute_gold_to_allies then
			return 3
		end
	end)
end

-- Stops a specific player from redistributing their gold to its allies
function CDOTA_PlayerResource:StopAbandonGoldRedistribution(playerID)
  self.PlayerData[playerID].distribute_gold_to_allies = false
  self:ModifyGold(playerID, -self:GetGold(playerID), false, DOTA_ModifyGold_AbandonedRedistribute)
  print("player "..playerID.." is no longer redistributing gold to its allies.")
end

function CDOTA_PlayerResource:GetRealSteamID(PlayerID)
  return tostring(self:GetSteamID(PlayerID))
end

function CDOTA_PlayerResource:GetTotalEarnedXPForTeam(teamID)
  local total_xp = 0
  for playerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
    if (self:IsValidPlayerID(playerID)) and self:GetTeam(playerID) == teamID then
      total_xp = total_xp + self:GetTotalEarnedXP(playerID)
    end
  end
  return total_xp
end
