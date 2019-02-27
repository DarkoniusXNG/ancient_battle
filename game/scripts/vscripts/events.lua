-- Cleanup a player when they leave
function ancient_battle_gamemode:OnDisconnect(keys)
	local name = keys.name
	local networkID = keys.networkid
	local reason = keys.reason
	local userID = keys.userid
	print("A player "..name.." disconnected:")
	print("==================================================")
	PrintTable(keys)
	print("==================================================")
end

function ancient_battle_gamemode:OnGameRulesStateChange(keys)
	local new_state = GameRules:State_Get()

	if new_state == DOTA_GAMERULES_STATE_INIT then

	elseif new_state == DOTA_GAMERULES_STATE_WAIT_FOR_PLAYERS_TO_LOAD then

	elseif new_state == DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP then
		GameRules:SetCustomGameSetupAutoLaunchDelay(CUSTOM_GAME_SETUP_TIME)
	elseif new_state == DOTA_GAMERULES_STATE_HERO_SELECTION then
		ancient_battle_gamemode:PostLoadPrecache()
		ancient_battle_gamemode:OnAllPlayersLoaded()
		Timers:CreateTimer(HERO_SELECTION_TIME+STRATEGY_TIME-1.1, function()
			for playerID = 0, 19 do
				if PlayerResource:IsValidPlayerID(playerID) then
					-- If this player still hasn't picked a hero, random one
					if not PlayerResource:HasSelectedHero(playerID) and PlayerResource:IsConnected(playerID) and (not PlayerResource:IsBroadcaster(playerID)) then
						PlayerResource:GetPlayer(playerID):MakeRandomHeroSelection()
						PlayerResource:SetHasRandomed(playerID)
						PlayerResource:SetCanRepick(playerID, false)
						print("[Ancient Battle] Randomed a hero for a player number "..playerID)
					end
				end
			end
		end)
	elseif new_state == DOTA_GAMERULES_STATE_STRATEGY_TIME then

	elseif new_state == DOTA_GAMERULES_STATE_TEAM_SHOWCASE then

	elseif new_state == DOTA_GAMERULES_STATE_PRE_GAME then

	elseif new_state == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		ancient_battle_gamemode:OnGameInProgress()
	elseif new_state == DOTA_GAMERULES_STATE_POST_GAME then

	elseif new_state == DOTA_GAMERULES_STATE_DISCONNECT then

	end
end

-- An NPC has spawned somewhere in game.  This includes heroes.
function ancient_battle_gamemode:OnNPCSpawned(keys)
	local npc = EntIndexToHScript(keys.entindex)

	-- OnHeroInGame
	if npc:IsRealHero() and npc.bFirstSpawned == nil then
		npc.bFirstSpawned = true
		ancient_battle_gamemode:OnHeroInGame(npc)
	end
end

-- An item was picked up off the ground
function ancient_battle_gamemode:OnItemPickedUp(keys)

end

-- A player has reconnected to the game.  This function can be used to repaint Player-based particles or change
-- state as necessary
function ancient_battle_gamemode:OnPlayerReconnect(keys)
	print("A player reconnected:")
	print("==================================================")
	PrintTable(keys)
	print("==================================================")

	local new_state = GameRules:State_Get()
	if new_state > DOTA_GAMERULES_STATE_HERO_SELECTION then
		Timers:CreateTimer(1.0, function()
			local playerID = keys.PlayerID

			if PlayerResource:HasSelectedHero(playerID) or PlayerResource:HasRandomed(playerID) then
				-- This playerID already had a hero before disconnect
			else
				if PlayerResource:IsConnected(playerID) and (not PlayerResource:IsBroadcaster(playerID)) then
					PlayerResource:GetPlayer(playerID):MakeRandomHeroSelection()
					PlayerResource:SetHasRandomed(playerID)
					PlayerResource:SetCanRepick(playerID, false)
					print("[Ancient Battle] Randomed a hero for a player number "..playerID.." that reconnected.")
				end
			end
		end)
	end
end

-- An item was purchased by a player
function ancient_battle_gamemode:OnItemPurchased(keys)

end

-- An ability was used by a player
function ancient_battle_gamemode:OnAbilityUsed(keys)

end

-- A non-player entity (necro-book, chen creep, etc) used an ability
function ancient_battle_gamemode:OnNonPlayerUsedAbility(keys)

end

-- A player changed their name
function ancient_battle_gamemode:OnPlayerChangedName(keys)

end

-- A player leveled up an ability; Note: it doesn't trigger when you use SetLevel() on the ability!
function ancient_battle_gamemode:OnPlayerLearnedAbility(keys)
	local player = EntIndexToHScript(keys.player)
	local ability_name = keys.abilityname

	local playerID
	if player then
		playerID = player:GetPlayerID()
	else
		playerID = keys.PlayerID
	end

	local hero = PlayerResource:GetAssignedHero(playerID)

	-- Handling talents without custom net tables
	local talents = {
		{"special_bonus_unique_sven", "modifier_paladin_storm_hammer_talent"},
		{"special_bonus_unique_hero_name_1", "modifier_ability_name_talent_name_1"}
	}

	for i = 1, #talents do
		local talent = talents[i]
		if ability_name == talent[1] then
			local talent_ability = hero:FindAbilityByName(ability_name)
			if talent_ability then
				local talent_modifier = talent[2]
				hero:AddNewModifier(hero, talent_ability, talent_modifier, {})
			end
		end
	end
end

-- A channelled ability finished by either completing or being interrupted
function ancient_battle_gamemode:OnAbilityChannelFinished(keys)

end

-- A player leveled up
function ancient_battle_gamemode:OnPlayerLevelUp(keys)
	local player = EntIndexToHScript(keys.player)
	local level = keys.level

	local playerID
	local hero
	if player then
		playerID = player:GetPlayerID()
		hero = PlayerResource:GetAssignedHero(playerID)
	end

	if hero then
		if hero.original then
			-- When hero.original isn't nil, hero is a clone and he gets a level, remove skill points
			hero:SetAbilityPoints(0)
			return nil
		end

		-- Update hero gold bounty when a hero gains a level
		if USE_CUSTOM_HERO_GOLD_BOUNTY then
			local hero_level = hero:GetLevel() or level
			local hero_streak = hero:GetStreak()

			local gold_bounty
			if hero_streak > 2 then
				gold_bounty = HERO_KILL_GOLD_BASE + hero_level*HERO_KILL_GOLD_PER_LEVEL + (hero_streak-2)*HERO_KILL_GOLD_PER_STREAK
			else
				gold_bounty = HERO_KILL_GOLD_BASE + hero_level*HERO_KILL_GOLD_PER_LEVEL
			end

			hero:SetMinimumGoldBounty(gold_bounty)
			hero:SetMaximumGoldBounty(gold_bounty)
		end

		-- Add a skill point when a hero levels up
		local levels_without_ability_point = {17, 19, 21, 22, 23, 24}	-- on this levels you should get a skill point
		for i = 1, #levels_without_ability_point do
			if level == levels_without_ability_point[i] then
				local unspent_ability_points = hero:GetAbilityPoints()
				hero:SetAbilityPoints(unspent_ability_points+1)
			end
		end
	end
end

-- A player last hit a creep, a tower, or a hero
function ancient_battle_gamemode:OnLastHit(keys)

end

-- A tree was cut down by tango, quelling blade, etc.
function ancient_battle_gamemode:OnTreeCut(keys)

end

-- A rune was activated by a player
function ancient_battle_gamemode:OnRuneActivated(keys)

end

-- A player took damage from a tower
function ancient_battle_gamemode:OnPlayerTakeTowerDamage(keys)

end

-- A player picked or randomed a hero (this is happening before OnNPCSpawned)
function ancient_battle_gamemode:OnPlayerPickHero(keys)
	local hero_name = keys.hero
	local hero_entity = EntIndexToHScript(keys.heroindex)
	local player = EntIndexToHScript(keys.player)

	Timers:CreateTimer(0.5, function()
		local playerID = hero_entity:GetPlayerID()
		if PlayerResource:IsFakeClient(playerID) then
			-- This is happening only for bots when they spawn for the first time or if they use custom hero-create spells:
			-- Dark Ranger Charm, Archmage Conjure Image
		else
			if PlayerResource.PlayerData[playerID].already_assigned_hero == true then
				-- This is happening only when players create new heroes with spells (Dark Ranger Charm, Archmage Conjure Image)
			else
				PlayerResource:AssignHero(playerID, hero_entity)
				PlayerResource.PlayerData[playerID].already_assigned_hero = true
			end
		end
	end)
end

-- A player killed another player in a multi-team context
function ancient_battle_gamemode:OnTeamKillCredit(keys)

end

function ancient_battle_gamemode:OnEntityKilled(keys)
	-- The Unit that was Killed
	local killed_unit = EntIndexToHScript(keys.entindex_killed)

	-- The Killing entity
	local killer_unit = nil

	if keys.entindex_attacker ~= nil then
		killer_unit = EntIndexToHScript(keys.entindex_attacker)
	end

	-- The ability/item used to kill, or nil if not killed by an item/ability
	local killing_ability = nil

	if keys.entindex_inflictor ~= nil then
		killing_ability = EntIndexToHScript(keys.entindex_inflictor)
	end

	-- Killed Unit is a hero (not an illusion and not a copy) and he is not reincarnating
	if killed_unit:IsRealHero() and (not killed_unit:IsReincarnating()) and (killed_unit.original == nil) then

		-- Hero gold bounty update for the killer
		if USE_CUSTOM_HERO_GOLD_BOUNTY then
			if killer_unit:IsRealHero() then
				-- Get his killing streak
				local hero_streak = killer_unit:GetStreak()
				-- Get his level
				local hero_level = killer_unit:GetLevel()
				-- Adjust Gold bounty
				local gold_bounty
				if hero_streak > 2 then
					gold_bounty = HERO_KILL_GOLD_BASE + hero_level*HERO_KILL_GOLD_PER_LEVEL + (hero_streak-2)*HERO_KILL_GOLD_PER_STREAK
				else
					gold_bounty = HERO_KILL_GOLD_BASE + hero_level*HERO_KILL_GOLD_PER_LEVEL
				end

				killer_unit:SetMinimumGoldBounty(gold_bounty)
				killer_unit:SetMaximumGoldBounty(gold_bounty)
			end
		end

		-- Hero Respawn time configuration
		if ENABLE_HERO_RESPAWN then
			local killed_unit_level = killed_unit:GetLevel()

			-- Respawn time without buyback penalty (+25 sec)
			local respawn_time = 1
			if USE_CUSTOM_RESPAWN_TIMES then
				-- Get respawn time from the table that we defined
				respawn_time = CUSTOM_RESPAWN_TIME[killed_unit_level]
			else
				-- Get dota default respawn time
				respawn_time = killed_unit:GetRespawnTime()
			end

			-- Fixing respawn time after level 25
			local respawn_time_after_25 = 100 + (killed_unit_level-25)*5
			if killed_unit_level > 25 and respawn_time < respawn_time_after_25	then
				respawn_time = respawn_time_after_25
			end

			-- Reaper's Scythe respawn time increase
			if killing_ability then
				if killing_ability:GetAbilityName() == "necrolyte_reapers_scythe" then
					local respawn_extra_time = killing_ability:GetLevelSpecialValueFor("respawn_constant", killing_ability:GetLevel() - 1)
					respawn_time = respawn_time + respawn_extra_time
				end
			end
			
			-- Killer is a neutral creep
			if killer_unit:IsNeutralUnitType() then
				-- If a hero is killed by a neutral creep, respawn time can be modified here
			end

			-- Maximum Respawn Time
			if respawn_time > MAX_RESPAWN_TIME then
				respawn_time = MAX_RESPAWN_TIME
			end

			if not killed_unit:IsReincarnating() then
				killed_unit:SetTimeUntilRespawn(respawn_time)
			end
		end

		-- Buyback Cooldown
		if CUSTOM_BUYBACK_COOLDOWN_ENABLED then
			PlayerResource:SetCustomBuybackCooldown(killed_unit:GetPlayerID(), BUYBACK_COOLDOWN_TIME)
		end
		
		-- Buyback Fixed Gold Cost
		if CUSTOM_BUYBACK_COST_ENABLED then
			PlayerResource:SetCustomBuybackCost(killed_unit:GetPlayerID(), BUYBACK_FIXED_GOLD_COST)
		end

		-- Killer is not a hero but it killed a hero
		if killer_unit:IsTower() or killer_unit:IsCreep() or killer_unit:IsFountain() then

		end

		-- When team hero kill limit is reached
		if END_GAME_ON_KILLS and GetTeamHeroKills(killer_unit:GetTeam()) >= KILLS_TO_END_GAME_FOR_TEAM then
			GameRules:SetGameWinner(killer_unit:GetTeam())
		end

		if SHOW_KILLS_ON_TOPBAR then
			GameRules:GetGameModeEntity():SetTopBarTeamValue(DOTA_TEAM_BADGUYS, GetTeamHeroKills(DOTA_TEAM_BADGUYS))
			GameRules:GetGameModeEntity():SetTopBarTeamValue(DOTA_TEAM_GOODGUYS, GetTeamHeroKills(DOTA_TEAM_GOODGUYS))
		end
	end

	-- Axe Chop Sound with Cut From Above (Culling Blade) when he kills heroes (not illusions)
	if killed_unit:IsRealHero() and killer_unit:HasAbility("holdout_culling_blade") and killing_ability ~= nil then
		local ability = killer_unit:FindAbilityByName("holdout_culling_blade")
		if killing_ability == ability then
			killer_unit:EmitSound("Hero_Axe.Culling_Blade_Success")
		end
	end

	-- Ancient destruction detection (if the map doesn't have ancients with this names, this will never happen)
	if killed_unit:GetUnitName() == "npc_dota_badguys_fort" then
		GameRules:SetGameWinner(DOTA_TEAM_GOODGUYS)
		GameRules:SetCustomVictoryMessage("#dota_post_game_radiant_victory")
		GameRules:SetCustomVictoryMessageDuration(POST_GAME_TIME)
	elseif killed_unit:GetUnitName() == "npc_dota_goodguys_fort" then
		GameRules:SetGameWinner(DOTA_TEAM_BADGUYS)
		if GetMapName() == "holdout" then
			GameRules:SetCustomVictoryMessage("Defeated by the Horde!")
		else
			GameRules:SetCustomVictoryMessage("#dota_post_game_dire_victory")
			GameRules:SetCustomVictoryMessageDuration(POST_GAME_TIME)
		end
	end

	-- Remove dead non-hero units from selection -> bugged ability/cast bar
	if killed_unit:IsIllusion() or (killed_unit:IsControllableByAnyPlayer() and (not killed_unit:IsRealHero()) and (not killed_unit:IsCourier()) and (not killed_unit:IsClone())) and (not killed_unit:IsTempestDouble()) then
		local player = killed_unit:GetPlayerOwner()
		local playerID
		if player == nil then
			playerID = killed_unit:GetPlayerOwnerID()
		else
			playerID = player:GetPlayerID()
		end
		PlayerResource:RemoveFromSelection(playerID, killed_unit)
	end

	-- Holdout game mode
	if GetMapName() == "holdout" then
		-- Ancient to become vulnerable if all his towers are destroyed (Custom backdoor protection)
		if killed_unit:GetUnitName() == "npc_dota_goodguys_tower4" then
			local tower1 = Entities:FindByName(nil, "good_tower1")
			local tower2 = Entities:FindByName(nil, "good_tower2")
			local tower3 = Entities:FindByName(nil, "good_tower3")
			local tower4 = Entities:FindByName(nil, "good_tower4")
			local no_tower1
			local no_tower2
			local no_tower3
			local no_tower4
			if tower1 then
				if tower1:IsAlive() then
					no_tower1 = false
				else
					no_tower1 = true
				end
			else
				no_tower1 = true
			end
			if tower2 then
				if tower2:IsAlive() then
					no_tower2 = false
				else
					no_tower2 = true
				end
			else
				no_tower2 = true
			end
			if tower3 then
				if tower3:IsAlive() then
					no_tower3 = false
				else
					no_tower3 = true
				end
			else
				no_tower3 = true
			end
			if tower4 then
				if tower4:IsAlive() then
					no_tower4 = false
				else
					no_tower4 = true
				end
			else
				no_tower4 = true
			end
			if no_tower1 and no_tower2 and no_tower3 and no_tower4 then
				local ancient = Entities:FindByName(nil, "ancient")
				local ancient_index = ancient:GetEntityIndex()
				local ancient_handle = EntIndexToHScript(ancient_index)
				ancient_handle:RemoveModifierByName("modifier_custom_building_invulnerable")
			end
		end
	end
end

-- This function is called 1 to 2 times as the player connects initially but before they have completely connected
function ancient_battle_gamemode:PlayerConnect(keys)

end

-- This function is called once when the player fully connects and becomes "Ready" during Loading
function ancient_battle_gamemode:OnConnectFull(keys)
	--PrintTable(keys)

	ancient_battle_gamemode:CaptureGameMode()

	local index = keys.index
	local playerID = keys.PlayerID
	local userID = keys.userid

	PlayerResource:OnPlayerConnect(keys)
end

-- This function is called whenever illusions are created and tells you which was/is the original entity
function ancient_battle_gamemode:OnIllusionsCreated(keys)

end

-- This function is called whenever an item is combined to create a new item
function ancient_battle_gamemode:OnItemCombined(keys)

end

-- This function is called OnAbilityPhaseStart
function ancient_battle_gamemode:OnAbilityCastBegins(keys)

end

-- This function is called whenever a tower is killed
function ancient_battle_gamemode:OnTowerKill(keys)

end

-- This function is called whenever a player changes their custom team selection during Game Setup 
function ancient_battle_gamemode:OnPlayerSelectedCustomTeam(keys)

end

-- This function is called whenever a NPC reaches its goal position/target
function ancient_battle_gamemode:OnNPCGoalReached(keys)

end

-- This function is called whenever any player sends a chat message to team or All
function ancient_battle_gamemode:OnPlayerChat(keys)

end
