-- Cleanup a player when they leave
function weird_dota_gamemode:OnDisconnect(keys)
	--PrintTable(keys)
	local name = keys.name
	local networkID = keys.networkid
	local reason = keys.reason
	local userID = keys.userid
end

-- The overall game state has changed
function weird_dota_gamemode:OnGameRulesStateChange(keys)
	--PrintTable(keys)
	local new_state = GameRules:State_Get()
	
	if new_state == DOTA_GAMERULES_STATE_INIT then
	
	elseif new_state == DOTA_GAMERULES_STATE_WAIT_FOR_PLAYERS_TO_LOAD then
		self.bSeenWaitForPlayers = true
	elseif new_state == DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP then
		GameRules:SetCustomGameSetupAutoLaunchDelay(CUSTOM_GAME_SETUP_TIME)
	elseif new_state == DOTA_GAMERULES_STATE_HERO_SELECTION then
		weird_dota_gamemode:PostLoadPrecache()
		weird_dota_gamemode:OnAllPlayersLoaded()
		Timers:CreateTimer(HERO_SELECTION_TIME - 1.1, function()
			for playerID = 0, 19 do
				if PlayerResource:IsValidPlayerID(playerID) then
					-- If this player still hasn't picked a hero, random one
					if not PlayerResource:HasSelectedHero(playerID) then
						PlayerResource:GetPlayer(playerID):MakeRandomHeroSelection()
						PlayerResource:SetHasRandomed(playerID)
						PlayerResource:SetCanRepick(playerID, false)
						print("Randomed a hero for a player number "..playerID)
					end
				end
			end
		end)
	elseif new_state == DOTA_GAMERULES_STATE_STRATEGY_TIME then
	
	elseif new_state == DOTA_GAMERULES_STATE_TEAM_SHOWCASE then
	
	elseif new_state == DOTA_GAMERULES_STATE_WAIT_FOR_MAP_TO_LOAD then
		
	elseif new_state == DOTA_GAMERULES_STATE_PRE_GAME then
		
	elseif new_state == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		weird_dota_gamemode:OnGameInProgress()
	elseif new_state == DOTA_GAMERULES_STATE_POST_GAME then
	
	elseif new_state == DOTA_GAMERULES_STATE_DISCONNECT then
	
	end
end

-- An NPC has spawned somewhere in game.  This includes heroes.
function weird_dota_gamemode:OnNPCSpawned(keys)
	--PrintTable(keys)
	local npc = EntIndexToHScript(keys.entindex)
	local unit_owner = npc:GetOwner()
	
	-- OnHeroInGame
	if npc:IsRealHero() and npc.bFirstSpawned == nil then
		npc.bFirstSpawned = true
		weird_dota_gamemode:OnHeroInGame(npc)
	end
end

-- An entity somewhere has been hurt.  This event fires very often with many units so don't do too many expensive
-- operations here
function weird_dota_gamemode:OnEntityHurt(keys)
	--PrintTable(keys)
end

-- An item was picked up off the ground
function weird_dota_gamemode:OnItemPickedUp(keys)
	--PrintTable(keys)
end

-- A player has reconnected to the game.  This function can be used to repaint Player-based particles or change
-- state as necessary
function weird_dota_gamemode:OnPlayerReconnect(keys)
	--PrintTable(keys)
end

-- An item was purchased by a player
function weird_dota_gamemode:OnItemPurchased(keys)
	--PrintTable(keys)
	
	-- The playerID of the hero who is buying something
	local plyID = keys.PlayerID
	if not plyID then return end

	-- The name of the item purchased
	local itemName = keys.itemname
	
	-- The cost of the item purchased
	local itemcost = keys.itemcost
end

-- An ability was used by a player
function weird_dota_gamemode:OnAbilityUsed(keys)
	--PrintTable(keys)
	
	local player = PlayerResource:GetPlayer(keys.PlayerID)
	local abilityname = keys.abilityname
end

-- A non-player entity (necro-book, chen creep, etc) used an ability
function weird_dota_gamemode:OnNonPlayerUsedAbility(keys)
	--PrintTable(keys)
	
	local abilityname = keys.abilityname
end

-- A player changed their name
function weird_dota_gamemode:OnPlayerChangedName(keys)
	--PrintTable(keys)
	
	local newName = keys.newname
	local oldName = keys.oldName
end

-- A player leveled up an ability
function weird_dota_gamemode:OnPlayerLearnedAbility(keys)
	--PrintTable(keys)
	
	local player = EntIndexToHScript(keys.player)
	local ability_name = keys.abilityname
	
	if ability_name == "special_bonus_unique_sven" then
		local playerID = player:GetPlayerID()
		local hero = PlayerResource:GetAssignedHero(playerID)
		
		local talent = hero:FindAbilityByName(ability_name)
		if talent then
			hero:AddNewModifier(hero, nil, "modifier_custom_paladin_talent", {})
		end
	end
end

-- A channelled ability finished by either completing or being interrupted
function weird_dota_gamemode:OnAbilityChannelFinished(keys)
	--PrintTable(keys)
	
	local abilityname = keys.abilityname
	local interrupted = keys.interrupted == 1
end

-- A player leveled up
function weird_dota_gamemode:OnPlayerLevelUp(keys)
	--PrintTable(keys)
	
	local player = EntIndexToHScript(keys.player)
	local level = keys.level
	local playerID = player:GetPlayerID()
	
	local hero = PlayerResource:GetAssignedHero(playerID)
	local hero_level = hero:GetLevel()
	local hero_streak = hero:GetStreak()
	
	if hero.original == nil then
		-- Update Minimum hero gold bounty on level up
		local gold_bounty
		if hero_streak > 1 then
			gold_bounty = HERO_KILL_GOLD_BASE + hero_level * HERO_KILL_GOLD_PER_LEVEL + hero_streak*60
		else
			gold_bounty = HERO_KILL_GOLD_BASE + hero_level * HERO_KILL_GOLD_PER_LEVEL
		end

		hero:SetMinimumGoldBounty(gold_bounty)
		
		local levels_without_ability_point = {17, 19, 21, 22, 23}	-- on this levels you should get a skill point
		for i = 1, #levels_without_ability_point do
			if level == levels_without_ability_point[i] then
				local unspent_ability_points = hero:GetAbilityPoints()
				hero:SetAbilityPoints(unspent_ability_points+1)
			end
		end
	else
		-- When hero.original isn't nil, hero is a clone and he gets a level, remove skill points
		hero:SetAbilityPoints(0)
	end
end

-- A player last hit a creep, a tower, or a hero
function weird_dota_gamemode:OnLastHit(keys)
	--PrintTable(keys)
	
	local isFirstBlood = keys.FirstBlood == 1
	local isHeroKill = keys.HeroKill == 1
	local isTowerKill = keys.TowerKill == 1
	local player = PlayerResource:GetPlayer(keys.PlayerID)
	local killedEnt = EntIndexToHScript(keys.EntKilled)
end

-- A tree was cut down by tango, quelling blade, etc.
function weird_dota_gamemode:OnTreeCut(keys)
	--PrintTable(keys)
	
	local treeX = keys.tree_x
	local treeY = keys.tree_y
end

-- A rune was activated by a player
function weird_dota_gamemode:OnRuneActivated (keys)
	--PrintTable(keys)
	
	local player = PlayerResource:GetPlayer(keys.PlayerID)
	local rune = keys.rune
end

-- A player took damage from a tower
function weird_dota_gamemode:OnPlayerTakeTowerDamage(keys)
	--PrintTable(keys)
	
	local player = PlayerResource:GetPlayer(keys.PlayerID)
	local damage = keys.damage
end

-- A player picked or randomed a hero (this is happening before OnNPCSpawned)
function weird_dota_gamemode:OnPlayerPickHero(keys)
	--PrintTable(keys)
	
	local hero_name = keys.hero
	local hero_entity = EntIndexToHScript(keys.heroindex)
	local player = EntIndexToHScript(keys.player)
	
	Timers:CreateTimer(0.5, function()
		local playerID = hero_entity:GetPlayerID() -- or player:GetPlayerID()
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
function weird_dota_gamemode:OnTeamKillCredit(keys)
	--PrintTable(keys)
	
	local killerPlayer = PlayerResource:GetPlayer(keys.killer_userid)
	local victimPlayer = PlayerResource:GetPlayer(keys.victim_userid)
	local numKills = keys.herokills
	local killerTeamNumber = keys.teamnumber
end

-- An entity died (something or someone killed an entity)
function weird_dota_gamemode:OnEntityKilled(keys)
	--PrintTable(keys)
	
	-- The Unit that was Killed
	local killed_unit = EntIndexToHScript(keys.entindex_killed)
	
	-- The Killing entity
	local killer_unit = nil

	if keys.entindex_attacker ~= nil then
		killer_unit = EntIndexToHScript(keys.entindex_attacker)
	end
	
	-- The ability/item used to kill, or nil if not killed by an item/ability
	local killerAbility = nil

	if keys.entindex_inflictor ~= nil then
		killerAbility = EntIndexToHScript(keys.entindex_inflictor)
	end
	
	-- Killed Unit is a hero (not an illusion and not a copy) and he is not reincarnating
	if killed_unit:IsRealHero() and (not killed_unit:IsReincarnating()) and (killed_unit.original == nil) then
		
		-- Get his killing streak
		local hero_streak = killed_unit:GetStreak()
		-- Get his level
		local hero_level = killed_unit:GetLevel()
	
		-- Adjust Minimum Gold bounty
		local gold_bounty
		if hero_streak > 1 then
			gold_bounty = HERO_KILL_GOLD_BASE + hero_level * HERO_KILL_GOLD_PER_LEVEL + hero_streak*60
		else
			gold_bounty = HERO_KILL_GOLD_BASE + hero_level * HERO_KILL_GOLD_PER_LEVEL
		end
		killed_unit:SetMinimumGoldBounty(gold_bounty)
		
		-- Maximum Respawn Time
		if ENABLE_HERO_RESPAWN then
			local respawnTime = killed_unit:GetRespawnTime()
			if respawnTime > MAX_RESPAWN_TIME then
				--print("Hero has a long respawn time")
				respawnTime = MAX_RESPAWN_TIME
				killed_unit:SetTimeUntilRespawn(respawnTime)
			end
		end
		
		-- Buyback Cooldown
		if CUSTOM_BUYBACK_COOLDOWN_ENABLED then
			PlayerResource:SetCustomBuybackCooldown(killed_unit:GetPlayerID(), BUYBACK_COOLDOWN_TIME)
		end
		
		-- Killer is not a hero but it killed a hero
		if killer_unit:IsTower() or killer_unit:IsCreep() or IsFountain(killer_unit) then

		end
		
		-- When team hero kill limit is reached
		if END_GAME_ON_KILLS and GetTeamHeroKills(killer_unit:GetTeam()) >= KILLS_TO_END_GAME_FOR_TEAM then
			GameRules:SetSafeToLeave(true)
			GameRules:SetGameWinner(killer_unit:GetTeam())
		end
		
		if SHOW_KILLS_ON_TOPBAR then
			GameRules:GetGameModeEntity():SetTopBarTeamValue(DOTA_TEAM_BADGUYS, GetTeamHeroKills(DOTA_TEAM_BADGUYS))
			GameRules:GetGameModeEntity():SetTopBarTeamValue(DOTA_TEAM_GOODGUYS, GetTeamHeroKills(DOTA_TEAM_GOODGUYS))
		end
	end
	
	-- Axe Chop Sound with Cut From Above (Culling Blade) when he kills heroes (not illusions)
	if killed_unit:IsRealHero() and killer_unit:HasAbility("holdout_culling_blade") and killerAbility ~= nil then
		local ability = killer_unit:FindAbilityByName("holdout_culling_blade")
		if killerAbility == ability then
			killer_unit:EmitSound("Hero_Axe.Culling_Blade_Success")
		end
	end
	
	-- Ancient destruction detection (if the map doesn't have ancients with this names, this will never happen)
	if killed_unit:GetUnitName() == "npc_dota_badguys_fort" then
		GameRules:SetGameWinner(DOTA_TEAM_GOODGUYS)
	elseif killed_unit:GetUnitName() == "npc_dota_goodguys_fort" then
		GameRules:SetGameWinner(DOTA_TEAM_BADGUYS)
	end
	
	-- Remove dead non-hero units from selection -> bugged ability/cast bar
	if killed_unit:IsIllusion() or (killed_unit:IsControllableByAnyPlayer() and (not killed_unit:IsHero()) and (not killed_unit:IsCourier())) then
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
				local ancient_entindex = ancient:GetEntityIndex()
				local ancient_handle = EntIndexToHScript(ancient_entindex)
				ancient_handle:RemoveModifierByName("modifier_custom_building_invulnerable")
			end
		end
	end
end

-- This function is called 1 to 2 times as the player connects initially but before they have completely connected
function weird_dota_gamemode:PlayerConnect(keys)
	--PrintTable(keys)
end

-- This function is called once when the player fully connects and becomes "Ready" during Loading
function weird_dota_gamemode:OnConnectFull(keys)
	--PrintTable(keys)
	
	weird_dota_gamemode:CaptureGameMode()

	local index = keys.index
	local playerID = keys.PlayerID
	local userID = keys.userid
	
	PlayerResource:OnPlayerConnect(keys)
end

-- This function is called whenever illusions are created and tells you which was/is the original entity
function weird_dota_gamemode:OnIllusionsCreated(keys)
	--PrintTable(keys)
	
	local originalEntity = EntIndexToHScript(keys.original_entindex)
end

-- This function is called whenever an item is combined to create a new item
function weird_dota_gamemode:OnItemCombined(keys)
	--PrintTable(keys)
	
	-- The playerID of the hero who is buying something
	local plyID = keys.PlayerID
	if not plyID then return end
	local player = PlayerResource:GetPlayer(plyID)

	-- The name of the item purchased
	local itemName = keys.itemname 
  
	-- The cost of the item purchased
	local itemcost = keys.itemcost
end

-- This function is called OnAbilityPhaseStart
function weird_dota_gamemode:OnAbilityCastBegins(keys)
	--PrintTable(keys)
	
	local player = PlayerResource:GetPlayer(keys.PlayerID)
	local abilityName = keys.abilityname
end

-- This function is called whenever a tower is killed
function weird_dota_gamemode:OnTowerKill(keys)
	--PrintTable(keys)
	
	local gold = keys.gold
	local killerPlayer = PlayerResource:GetPlayer(keys.killer_userid)
	local team = keys.teamnumber
end

-- This function is called whenever a player changes their custom team selection during Game Setup 
function weird_dota_gamemode:OnPlayerSelectedCustomTeam(keys)
	--PrintTable(keys)
	
	local player = PlayerResource:GetPlayer(keys.player_id)
	local success = (keys.success == 1)
	local team = keys.team_id
end

-- This function is called whenever a NPC reaches its goal position/target
function weird_dota_gamemode:OnNPCGoalReached(keys)
	--PrintTable(keys)
	
	local goalEntity = EntIndexToHScript(keys.goal_entindex)
	local nextGoalEntity = EntIndexToHScript(keys.next_goal_entindex)
	local npc = EntIndexToHScript(keys.npc_entindex)
end

-- This function is called whenever any player sends a chat message to team or All
function weird_dota_gamemode:OnPlayerChat(keys)
	--PrintTable(keys)
	
	local teamonly = keys.teamonly
	local userID = keys.userid
	local text = keys.text
end