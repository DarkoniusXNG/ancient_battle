-- Cleanup a player when they leave
function ancient_battle_gamemode:OnDisconnect(keys)
	local name = keys.name
	local networkID = keys.networkid
	local reason = keys.reason
	local userID = keys.userid
end

function ancient_battle_gamemode:OnGameRulesStateChange(keys)
	local new_state = GameRules:State_Get()

	if new_state == DOTA_GAMERULES_STATE_INIT then

	elseif new_state == DOTA_GAMERULES_STATE_WAIT_FOR_PLAYERS_TO_LOAD then

	elseif new_state == DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP then
		GameRules:SetCustomGameSetupAutoLaunchDelay(CUSTOM_GAME_SETUP_TIME)
	elseif new_state == DOTA_GAMERULES_STATE_HERO_SELECTION then
		self:PostLoadPrecache()
		self:OnAllPlayersLoaded()
	elseif new_state == DOTA_GAMERULES_STATE_STRATEGY_TIME then

	elseif new_state == DOTA_GAMERULES_STATE_TEAM_SHOWCASE then

	elseif new_state == DOTA_GAMERULES_STATE_PRE_GAME then
		--GameRules:GetGameModeEntity():SetCustomDireScore(0)
	elseif new_state == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		self:OnGameInProgress()
	elseif new_state == DOTA_GAMERULES_STATE_POST_GAME then

	elseif new_state == DOTA_GAMERULES_STATE_DISCONNECT then

	end
end

-- An NPC has spawned somewhere in game.  This includes heroes.
function ancient_battle_gamemode:OnNPCSpawned(keys)
	local npc 
	if keys.entindex then
		npc = EntIndexToHScript(keys.entindex)
	else
		print("npc_spawned event doesn't have entindex key")
		return
	end

	-- OnHeroInGame
	if npc:IsRealHero() and npc.bFirstSpawned == nil then
		npc.bFirstSpawned = true
		self:OnHeroInGame(npc)
	end
end

function ancient_battle_gamemode:OnHeroInGame(hero)
	-- List of innate abilities
	local innate_abilities = {
		"firelord_arcana_model",
		"blood_mage_orbs",
		"mana_eater_mana_regen",
		"warp_beast_silly_attack_mutator"
	}

	-- Cycle through any innate abilities found, then set their level to 1
	for i = 1, #innate_abilities do
		local current_ability = hero:FindAbilityByName(innate_abilities[i])
		if current_ability then
			current_ability:SetLevel(1)
		end
	end

	Timers:CreateTimer(0.5, function()
		local playerID = hero:GetPlayerID()	-- never nil (-1 by default), needs delay 1 or more frames

		if PlayerResource:IsFakeClient(playerID) then
			-- This is happening only for bots
			-- Set starting gold for bots
			hero:SetGold(NORMAL_START_GOLD, false)
		else
			if not PlayerResource.PlayerData[playerID] and PlayerResource:IsValidPlayerID(playerID) then
				PlayerResource:InitPlayerDataForID(playerID)
			end
			-- Set some hero stuff on first spawn or on every spawn (custom or not)
			if PlayerResource.PlayerData[playerID].already_set_hero == true then
				-- This is happening only when players create new heroes with custom hero-create spells:
				-- Dark Ranger Charm, Archmage Conjure Image
			else
				-- This is happening for players when their first hero spawns for the first time
				--print("[Ancient Battle] Hero "..hero:GetUnitName().." spawned in the game for the first time for the player with ID "..playerID)
				
				-- Make heroes briefly visible on spawn (to prevent bad fog interactions)
				hero:MakeVisibleToTeam(DOTA_TEAM_GOODGUYS, 0.5)
				hero:MakeVisibleToTeam(DOTA_TEAM_BADGUYS, 0.5)
				
				-- Add permanent modifiers to the hero
				if PlayerResource:IsValidPlayerID(playerID) then
					hero:AddNewModifier(hero, nil, "modifier_client_convars", {})
					hero:AddNewModifier(hero, nil, "modifier_custom_passive_gold", {})
					hero:AddNewModifier(hero, nil, "modifier_custom_passive_xp", {})
				end
				
				-- This ensures that this will not happen again if some other hero spawns for the first time during the game
				PlayerResource.PlayerData[playerID].already_set_hero = true
				--print("[Ancient Battle] Hero "..hero:GetUnitName().." set for the player with ID "..playerID)
			end
		end
	end)
end

-- An item was picked up off the ground
function ancient_battle_gamemode:OnItemPickedUp(keys)

end

-- A player has reconnected to the game.  This function can be used to repaint Player-based particles or change
-- state as necessary
function ancient_battle_gamemode:OnPlayerReconnect(keys)
	local new_state = GameRules:State_Get()
	if new_state > DOTA_GAMERULES_STATE_HERO_SELECTION then
		Timers:CreateTimer(1.0, function()
			local playerID = keys.PlayerID or keys.player_id
			
			if not playerID or not PlayerResource:IsValidPlayerID(playerID) then
				print("OnPlayerReconnect - Reconnected player ID isn't valid!")
			end

			if PlayerResource:HasSelectedHero(playerID) or PlayerResource:HasRandomed(playerID) then
				-- This playerID already had a hero before disconnect
			else
				if PlayerResource:IsConnected(playerID) and not PlayerResource:IsBroadcaster(playerID) then
					PlayerResource:GetPlayer(playerID):MakeRandomHeroSelection()
					PlayerResource:SetHasRandomed(playerID)
					PlayerResource:SetCanRepick(playerID, false)
					print("[Ancient Battle] OnPlayerReconnect - Randomed a hero for a player ID "..playerID.." that reconnected.")
				end
			end
		end)
	end
end

-- An ability was used by a player
function ancient_battle_gamemode:OnAbilityUsed(keys)

end

-- A player leveled up an ability; Note: it doesn't trigger when you use SetLevel() on the ability!
function ancient_battle_gamemode:OnPlayerLearnedAbility(keys)
	local player
	if keys.player then
		player = EntIndexToHScript(keys.player)
	end

	local ability_name = keys.abilityname

	local playerID
	if player then
		playerID = player:GetPlayerID()
	else
		playerID = keys.PlayerID
	end

	local hero = PlayerResource:GetBarebonesAssignedHero(playerID)

	-- Handling talents without custom net tables
	-- local talents = {
		-- {"special_bonus_unique_hero_name_1", "modifier_ability_name_talent_name_1"},
	-- }

	-- for i = 1, #talents do
		-- local talent = talents[i]
		-- if ability_name == talent[1] then
			-- local talent_ability = hero:FindAbilityByName(ability_name)
			-- if talent_ability then
				-- local talent_modifier = talent[2]
				-- hero:AddNewModifier(hero, talent_ability, talent_modifier, {})
			-- end
		-- end
	-- end
end

-- A player leveled up
function ancient_battle_gamemode:OnPlayerLevelUp(keys)
	local level = keys.level
	local playerID = keys.player_id or keys.PlayerID
	local hero 
	if keys.hero_entindex then
		hero = EntIndexToHScript(keys.hero_entindex)
	else
		hero = PlayerResource:GetBarebonesAssignedHero(playerID)
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
		local levels_without_ability_point = {17, 19, 21, 22, 23, 24, 26}	-- on this levels you should get a skill point
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

-- A player picked or randomed a hero (this is happening before OnHeroInGame)
function ancient_battle_gamemode:OnPlayerPickHero(keys)
	local hero_name = keys.hero
	local hero_entity
	if keys.heroindex then
		hero_entity = EntIndexToHScript(keys.heroindex)
	end
	local player
	if keys.player then
		player = EntIndexToHScript(keys.player)
	end

	Timers:CreateTimer(0.5, function()
		if not hero_entity then
			return
		end
		local playerID = hero_entity:GetPlayerID()
		if PlayerResource:IsFakeClient(playerID) then
			-- This is happening only for bots when they spawn for the first time or if they use custom hero-create spells:
			-- Dark Ranger Charm, Archmage Conjure Image
		else
			if not PlayerResource.PlayerData[playerID] and PlayerResource:IsValidPlayerID(playerID) then
				PlayerResource:InitPlayerDataForID(playerID)
				print("[Ancient Battle] OnPlayerPickHero - PlayerResource's PlayerData for playerID "..playerID.." was not properly initialized.")
			end
			if PlayerResource.PlayerData[playerID].already_assigned_hero == true then
				-- This is happening only when players create new heroes with spells (Dark Ranger Charm, Archmage Conjure Image)
				print("[BAREBONES] OnPlayerPickHero - Player with playerID "..playerID.." got another hero: "..hero_entity:GetUnitName())
			else
				PlayerResource:AssignHero(playerID, hero_entity)
				PlayerResource.PlayerData[playerID].already_assigned_hero = true
			end
		end
	end)
end

function ancient_battle_gamemode:OnEntityKilled(keys)
	-- Indexes:
    local killed_entity_index = keys.entindex_killed
    local attacker_entity_index = keys.entindex_attacker
    local inflictor_index = keys.entindex_inflictor -- it can be nil if not killed by an item/ability

    -- Find the entity that was killed
    local killed_unit
    if killed_entity_index then
      killed_unit = EntIndexToHScript(killed_entity_index)
    end

    -- Find the entity (killer) that killed the entity mentioned above
    local killer_unit
    if attacker_entity_index then
      killer_unit = EntIndexToHScript(attacker_entity_index)
    end

	if killed_unit == nil or killer_unit == nil then
      -- don't continue if killer or killed entity dont exist
      return
    end

	-- Find the ability/item used to kill, or nil if not killed by an item/ability
    local killing_ability
    if inflictor_index then
      killing_ability = EntIndexToHScript(inflictor_index)
    end

	-- Killed Unit is a hero (not an illusion and not a copy) and he is not reincarnating
	if killed_unit:IsRealHero() and not killed_unit:IsReincarnating() and (killed_unit.original == nil) then
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

			-- Respawn time without buyback penalty
			local respawn_time = 1
			if USE_CUSTOM_RESPAWN_TIMES then
				-- Get respawn time from the table that we defined
				respawn_time = CUSTOM_RESPAWN_TIME[killed_unit_level]
			else
				-- Get dota default respawn time
				respawn_time = killed_unit:GetRespawnTime()
			end

			-- Fixing respawn time after level 30
			local respawn_time_after_30 = 100 + (killed_unit_level-30)*5
			if killed_unit_level > 30 and respawn_time ~= respawn_time_after_30 and not USE_CUSTOM_RESPAWN_TIMES then
				respawn_time = respawn_time_after_30
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

		-- When team hero kill limit is reached
		if END_GAME_ON_KILLS and GetTeamHeroKills(killer_unit:GetTeam()) >= KILLS_TO_END_GAME_FOR_TEAM then
			local winning_team = killer_unit:GetTeam()
			GameRules:SetGameWinner(winning_team)
			if winning_team == DOTA_TEAM_GOODGUYS then
				GameRules:SetCustomVictoryMessage("#dota_post_game_radiant_victory")
			elseif winning_team == DOTA_TEAM_BADGUYS then
				GameRules:SetCustomVictoryMessage("#dota_post_game_dire_victory")
			end
			GameRules:SetCustomVictoryMessageDuration(POST_GAME_TIME)
		end

		if SHOW_KILLS_ON_TOPBAR then
			--GameRules:GetGameModeEntity():SetTopBarTeamValue(DOTA_TEAM_BADGUYS, GetTeamHeroKills(DOTA_TEAM_BADGUYS))
			--GameRules:GetGameModeEntity():SetTopBarTeamValue(DOTA_TEAM_GOODGUYS, GetTeamHeroKills(DOTA_TEAM_GOODGUYS))
			GameRules:GetGameModeEntity():SetCustomRadiantScore(GetTeamHeroKills(DOTA_TEAM_GOODGUYS))
			GameRules:GetGameModeEntity():SetCustomDireScore(GetTeamHeroKills(DOTA_TEAM_BADGUYS))
		end
	end

	-- Axe Chop Sound with Cut From Above (Culling Blade) when he kills heroes (not illusions)
	if killed_unit:IsRealHero() and killer_unit:HasAbility("holdout_culling_blade") and killing_ability then
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
		end
		GameRules:SetCustomVictoryMessageDuration(POST_GAME_TIME)
	end

	-- Remove dead non-hero units from selection -> bugged ability/cast bar
	if killed_unit:IsIllusion() or (killed_unit:IsControllableByAnyPlayer() and not killed_unit:IsRealHero() and not killed_unit:IsCourier()) then
		local player = killed_unit:GetPlayerOwner()
		local playerID
		if not player then
			playerID = killed_unit:GetPlayerOwnerID()
		else
			playerID = player:GetPlayerID()
		end
		if Selection then
			PlayerResource:RemoveFromSelection(playerID, killed_unit)
		end
	end

	-- 2v2 map optional win condition
	if GetMapName() == "two_vs_two" and string.find(killed_unit:GetUnitName(), "tower") and killed_unit:IsBuilding() then
		local tower_team = killed_unit:GetTeam()
		if tower_team == DOTA_TEAM_GOODGUYS then
			GameRules:SetGameWinner(DOTA_TEAM_BADGUYS)
			GameRules:SetCustomVictoryMessage("#dota_post_game_dire_victory")
		elseif tower_team == DOTA_TEAM_BADGUYS then
			GameRules:SetGameWinner(DOTA_TEAM_GOODGUYS)
			GameRules:SetCustomVictoryMessage("#dota_post_game_radiant_victory")
		end
		GameRules:SetCustomVictoryMessageDuration(POST_GAME_TIME)
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

-- This function is called once when the player fully connects and becomes "Ready" during Loading
function ancient_battle_gamemode:OnConnectFull(keys)

	self:CaptureGameMode()

	PlayerResource:OnPlayerConnect(keys)
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
