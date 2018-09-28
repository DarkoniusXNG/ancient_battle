-- This library can be used for advanced physics/motion/collision of units.
--require('libraries/physics')
-- This library can be used for advanced 3D projectile systems.
--require('libraries/projectiles')
-- This library can be used for starting customized animations on units from lua
require('libraries/animations')
-- This library can be used for sending panorama notifications to the UIs of players/teams/everyone
require('libraries/notifications')
-- This library (by Noya) provides player selection inspection and management from server lua
require('libraries/selection')

-- settings.lua is where you can specify many different properties for your game mode and is one of the core barebones files.
require('settings')
-- events.lua is where you can specify the actions to be taken when any event occurs and is one of the core barebones files.
require('events')
require('spawns')
require('filters')

function ancient_battle_gamemode:PostLoadPrecache()

end

function ancient_battle_gamemode:OnFirstPlayerLoaded()

end

function ancient_battle_gamemode:OnAllPlayersLoaded()
	
	-- Find all buildings on the map
	local buildings = FindUnitsInRadius(DOTA_TEAM_GOODGUYS, Vector(0,0,0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_BUILDING, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)

	-- Iterate through each one
	for _, building in pairs(buildings) do
		local building_name = building:GetName()
		-- Check if its a fountain
		if string.find(building_name, "fountain") then
			-- Add abilities to fountains
			building:AddAbility("custom_building_true_strike")
			local fountain_true_strike = building:FindAbilityByName("custom_building_true_strike")
			fountain_true_strike:SetLevel(1)
			building:AddAbility("custom_fountain_true_sight")
			local fountain_true_sight = building:FindAbilityByName("custom_fountain_true_sight")
			fountain_true_sight:SetLevel(1)
			if GetMapName() == "two_vs_two" then
				building:AddAbility("custom_fountain_regen")
				local fountain_regen = building:FindAbilityByName("custom_fountain_regen")
				fountain_regen:SetLevel(1)
			end
		end
		-- Check if its a tower
		if string.find(building_name, "tower") then
			-- Add abilities to towers
			building:AddAbility("custom_building_true_strike")
			local towers_true_strike = building:FindAbilityByName("custom_building_true_strike")
			towers_true_strike:SetLevel(1)
			if GetMapName() == "holdout" then
				if building:GetTeam() == DOTA_TEAM_BADGUYS then
					building:AddNewModifier(building, nil, "modifier_custom_building_invulnerable", {})
					-- Adding Fury Swipes
					building:AddAbility("ursa_fury_swipes")
					local towers_fury_swipes = building:FindAbilityByName("ursa_fury_swipes")
					towers_fury_swipes:SetLevel(4)
				end
			end
		end
		-- Check if its an ancient
		if string.find(building_name, "fort") then
			if GetMapName() == "holdout" then
				building:AddNewModifier(building, nil, "modifier_custom_building_invulnerable", {})
			end
		end
	end
end

--[[
  It is also called if the player's hero is replaced with a new hero for any reason.  This function is useful for initializing heroes, such as adding
  levels, changing the starting gold, removing/adding abilities, adding physics, etc.
  The hero parameter is the hero entity that just spawned in
]]
function ancient_battle_gamemode:OnHeroInGame(hero)
	
	-- Innate abilities (this is applied to custom created heroes/illusions too)
	InitializeInnateAbilities(hero)
	
	Timers:CreateTimer(0.5, function()
		local playerID = hero:GetPlayerID()	-- never nil (-1 by default), needs delay 1 or more frames
		
		if PlayerResource:IsFakeClient(playerID) then
			-- This is happening only for bots
			-- Set starting gold for bots
			hero:SetGold(NORMAL_START_GOLD, false)
		else
			-- Set some hero stuff on first spawn or on every spawn (custom or not)
			if PlayerResource.PlayerData[playerID].already_set_hero == true then
				-- This is happening only when players create new heroes with custom hero-create spells:
				-- Dark Ranger Charm, Archmage Conjure Image
			else
				-- This is happening for players when their first hero spawn for the first time
				
				-- Make heroes briefly visible on spawn (to prevent bad fog interactions)
				hero:MakeVisibleToTeam(DOTA_TEAM_GOODGUYS, 0.5)
				hero:MakeVisibleToTeam(DOTA_TEAM_BADGUYS, 0.5)
				
				-- Set the starting gold for the player's hero
				if PlayerResource:HasRandomed(playerID) then
					PlayerResource:ModifyGold(playerID, RANDOM_START_GOLD-600, false, 0)
				else
					-- If the NORMAL_START_GOLD is smaller then 600, don't use this line:
					PlayerResource:ModifyGold(playerID, NORMAL_START_GOLD-600, false, 0)
				end
				
				-- Client Settings
				if PlayerResource:IsValidPlayerID(playerID) then
					hero:AddNewModifier(hero, nil, "modifier_client_convars", {})
				end
				
				-- This ensures that this will not happen again if some other hero spawns for the first time during the game
				PlayerResource.PlayerData[playerID].already_set_hero = true
				print("Hero "..hero:GetUnitName().." set for player with ID "..playerID)
			end
		end
	end)
end

--[[
  This function is called once and only once when the game completely begins (about 0:00 on the clock).  At this point,
  gold will begin to go up in ticks if configured, creeps will spawn, towers will become damageable etc.  This function
  is useful for starting any game logic timers/thinkers, beginning the first round, etc.
]]
function ancient_battle_gamemode:OnGameInProgress()

	if GetMapName() == "holdout" then
		-- Custom backdoor protection
		Timers:CreateTimer(function()
			local ancient = Entities:FindByName(nil, "ancient")
			local ancient_index = ancient:GetEntityIndex()
			local ancient_handle = EntIndexToHScript(ancient_index)
			ancient_handle:AddNewModifier(ancient_handle, nil, "modifier_custom_building_invulnerable", {})
		end)
		-- Start Spawning the Horde
		SpawnFirstSevenWaves()
	end
end

function ancient_battle_gamemode:InitGameMode()
	-- Setup rules
	GameRules:SetHeroRespawnEnabled(ENABLE_HERO_RESPAWN)
	GameRules:SetUseUniversalShopMode(UNIVERSAL_SHOP_MODE)
	GameRules:SetSameHeroSelectionEnabled(ALLOW_SAME_HERO_SELECTION)
	GameRules:SetHeroSelectionTime(HERO_SELECTION_TIME)
	GameRules:SetPreGameTime(PRE_GAME_TIME)
	GameRules:SetPostGameTime(POST_GAME_TIME)
	GameRules:SetShowcaseTime(SHOWCASE_TIME)
	GameRules:SetStrategyTime(STRATEGY_TIME)
	GameRules:SetTreeRegrowTime(TREE_REGROW_TIME)
	if USE_CUSTOM_HERO_LEVELS then
		GameRules:SetUseCustomHeroXPValues(true)
	end
	GameRules:SetGoldPerTick(GOLD_PER_TICK)
	GameRules:SetGoldTickTime(GOLD_TICK_TIME)
	if USE_CUSTOM_HERO_GOLD_BOUNTY then
		GameRules:SetUseBaseGoldBountyOnHeroes(false)
	end
	GameRules:SetHeroMinimapIconScale(MINIMAP_ICON_SIZE)
	GameRules:SetCreepMinimapIconScale(MINIMAP_CREEP_ICON_SIZE)
	GameRules:SetRuneMinimapIconScale(MINIMAP_RUNE_ICON_SIZE)	
  
	GameRules:SetFirstBloodActive(ENABLE_FIRST_BLOOD)
	GameRules:SetHideKillMessageHeaders(HIDE_KILL_BANNERS)
	
	-- This is multiteam configuration stuff
	if USE_AUTOMATIC_PLAYERS_PER_TEAM then
		local num = math.floor(10 / MAX_NUMBER_OF_TEAMS)
		local count = 0
		for team,number in pairs(TEAM_COLORS) do
			if count >= MAX_NUMBER_OF_TEAMS then
				GameRules:SetCustomGameTeamMaxPlayers(team, 0)
			else
				GameRules:SetCustomGameTeamMaxPlayers(team, num)
			end
			count = count + 1
		end
	else
		local count = 0
		for team,number in pairs(CUSTOM_TEAM_PLAYER_COUNT) do
			if count >= MAX_NUMBER_OF_TEAMS then
				GameRules:SetCustomGameTeamMaxPlayers(team, 0)
			else
				GameRules:SetCustomGameTeamMaxPlayers(team, number)
			end
			count = count + 1
		end
	end

	if USE_CUSTOM_TEAM_COLORS then
		for team,color in pairs(TEAM_COLORS) do
			SetTeamCustomHealthbarColor(team, color[1], color[2], color[3])
		end
	end
	
	-- Event Hooks
	ListenToGameEvent('dota_player_gained_level', Dynamic_Wrap(ancient_battle_gamemode, 'OnPlayerLevelUp'), self)
	ListenToGameEvent('dota_ability_channel_finished', Dynamic_Wrap(ancient_battle_gamemode, 'OnAbilityChannelFinished'), self)
	ListenToGameEvent('dota_player_learned_ability', Dynamic_Wrap(ancient_battle_gamemode, 'OnPlayerLearnedAbility'), self)
	ListenToGameEvent('entity_killed', Dynamic_Wrap(ancient_battle_gamemode, 'OnEntityKilled'), self)
	ListenToGameEvent('player_connect_full', Dynamic_Wrap(ancient_battle_gamemode, 'OnConnectFull'), self)
	ListenToGameEvent('player_disconnect', Dynamic_Wrap(ancient_battle_gamemode, 'OnDisconnect'), self)
	ListenToGameEvent('dota_item_purchased', Dynamic_Wrap(ancient_battle_gamemode, 'OnItemPurchased'), self)
	ListenToGameEvent('dota_item_picked_up', Dynamic_Wrap(ancient_battle_gamemode, 'OnItemPickedUp'), self)
	ListenToGameEvent('last_hit', Dynamic_Wrap(ancient_battle_gamemode, 'OnLastHit'), self)
	ListenToGameEvent('dota_non_player_used_ability', Dynamic_Wrap(ancient_battle_gamemode, 'OnNonPlayerUsedAbility'), self)
	ListenToGameEvent('player_changename', Dynamic_Wrap(ancient_battle_gamemode, 'OnPlayerChangedName'), self)
	ListenToGameEvent('dota_rune_activated_server', Dynamic_Wrap(ancient_battle_gamemode, 'OnRuneActivated'), self)
	ListenToGameEvent('dota_player_take_tower_damage', Dynamic_Wrap(ancient_battle_gamemode, 'OnPlayerTakeTowerDamage'), self)
	ListenToGameEvent('tree_cut', Dynamic_Wrap(ancient_battle_gamemode, 'OnTreeCut'), self)
	ListenToGameEvent('entity_hurt', Dynamic_Wrap(ancient_battle_gamemode, 'OnEntityHurt'), self)
	ListenToGameEvent('player_connect', Dynamic_Wrap(ancient_battle_gamemode, 'PlayerConnect'), self)
	ListenToGameEvent('dota_player_used_ability', Dynamic_Wrap(ancient_battle_gamemode, 'OnAbilityUsed'), self)
	ListenToGameEvent('game_rules_state_change', Dynamic_Wrap(ancient_battle_gamemode, 'OnGameRulesStateChange'), self)
	ListenToGameEvent('npc_spawned', Dynamic_Wrap(ancient_battle_gamemode, 'OnNPCSpawned'), self)
	ListenToGameEvent('dota_player_pick_hero', Dynamic_Wrap(ancient_battle_gamemode, 'OnPlayerPickHero'), self)
	ListenToGameEvent('dota_team_kill_credit', Dynamic_Wrap(ancient_battle_gamemode, 'OnTeamKillCredit'), self)
	ListenToGameEvent("player_reconnected", Dynamic_Wrap(ancient_battle_gamemode, 'OnPlayerReconnect'), self)
	ListenToGameEvent("player_chat", Dynamic_Wrap(ancient_battle_gamemode, 'OnPlayerChat'), self)

	ListenToGameEvent("dota_illusions_created", Dynamic_Wrap(ancient_battle_gamemode, 'OnIllusionsCreated'), self)
	ListenToGameEvent("dota_item_combined", Dynamic_Wrap(ancient_battle_gamemode, 'OnItemCombined'), self)
	ListenToGameEvent("dota_player_begin_cast", Dynamic_Wrap(ancient_battle_gamemode, 'OnAbilityCastBegins'), self)
	ListenToGameEvent("dota_tower_kill", Dynamic_Wrap(ancient_battle_gamemode, 'OnTowerKill'), self)
	ListenToGameEvent("dota_player_selected_custom_team", Dynamic_Wrap(ancient_battle_gamemode, 'OnPlayerSelectedCustomTeam'), self)
	ListenToGameEvent("dota_npc_goal_reached", Dynamic_Wrap(ancient_battle_gamemode, 'OnNPCGoalReached'), self)
	
	--ListenToGameEvent('player_spawn', Dynamic_Wrap(ancient_battle_gamemode, 'OnPlayerSpawn'), self)
	--ListenToGameEvent('nommed_tree', Dynamic_Wrap(ancient_battle_gamemode, 'OnPlayerAteTree'), self)
	--ListenToGameEvent('player_completed_game', Dynamic_Wrap(ancient_battle_gamemode, 'OnPlayerCompletedGame'), self)
	--ListenToGameEvent('dota_match_done', Dynamic_Wrap(ancient_battle_gamemode, 'OnDotaMatchDone'), self)
	--ListenToGameEvent('dota_combatlog', Dynamic_Wrap(ancient_battle_gamemode, 'OnCombatLogEvent'), self)
	--ListenToGameEvent('player_team', Dynamic_Wrap(ancient_battle_gamemode, 'OnPlayerTeam'), self)

	-- Change random seed
	local timeTxt = string.gsub(string.gsub(GetSystemTime(), ':', ''), '0','')
	math.randomseed(tonumber(timeTxt))

	local gamemode = GameRules:GetGameModeEntity()
	
	-- Setting the Order filter
	gamemode:SetExecuteOrderFilter(Dynamic_Wrap(ancient_battle_gamemode, "OrderFilter"), self)
  
	-- Setting the Damage filter
	gamemode:SetDamageFilter(Dynamic_Wrap(ancient_battle_gamemode, "DamageFilter"), self)
	
	-- Setting the Modifier filter
	gamemode:SetModifierGainedFilter(Dynamic_Wrap(ancient_battle_gamemode, "ModifierFilter"), self)
	
	-- Setting the Experience filter
	gamemode:SetModifyExperienceFilter(Dynamic_Wrap(ancient_battle_gamemode, "ExperienceFilter"), self)
	
	-- Setting the Tracking Projectile filter
	gamemode:SetTrackingProjectileFilter(Dynamic_Wrap(ancient_battle_gamemode, "ProjectileFilter"), self)
	
	-- Setting the rune filters
	gamemode:SetBountyRunePickupFilter(Dynamic_Wrap(your_gamemode_name, "BountyRuneFilter"), self)
	gamemode:SetRuneSpawnFilter(Dynamic_Wrap(your_gamemode_name, "RuneSpawnFilter"), self)

	-- Setting the Healing filter
	gamemode:SetHealingFilter(Dynamic_Wrap(your_gamemode_name, "HealingFilter"), self)

	-- Setting the Gold Filter
	gamemode:SetModifyGoldFilter(Dynamic_Wrap(your_gamemode_name, "GoldFilter"), self)

	-- Setting the Inventory filter
	gamemode:SetItemAddedToInventoryFilter(Dynamic_Wrap(your_gamemode_name, "InventoryFilter"), self)
  
	-- Lua Modifiers
	LinkLuaModifier("modifier_client_convars", "libraries/modifiers/modifier_client_convars", LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_custom_building_invulnerable", "libraries/modifiers/modifier_custom_building_invulnerable", LUA_MODIFIER_MOTION_NONE)
	
	print("Ancient Battle custom game initialized.")
end

-- This function is called as the first player loads and sets up the game mode parameters
function ancient_battle_gamemode:CaptureGameMode()

	-- Set GameMode parameters
	local mode = GameRules:GetGameModeEntity()
	mode:SetRecommendedItemsDisabled(RECOMMENDED_BUILDS_DISABLED)
	mode:SetCameraDistanceOverride(CAMERA_DISTANCE_OVERRIDE)
	mode:SetCustomBuybackCostEnabled(CUSTOM_BUYBACK_COST_ENABLED)
	mode:SetCustomBuybackCooldownEnabled(CUSTOM_BUYBACK_COOLDOWN_ENABLED)
	mode:SetBuybackEnabled(BUYBACK_ENABLED)
	mode:SetTopBarTeamValuesOverride(USE_CUSTOM_TOP_BAR_VALUES)
	mode:SetTopBarTeamValuesVisible(TOP_BAR_VISIBLE)

	if USE_CUSTOM_XP_VALUES then
		mode:SetUseCustomHeroLevels(true)
		mode:SetCustomXPRequiredToReachNextLevel(XP_PER_LEVEL_TABLE)
	end

	mode:SetBotThinkingEnabled(USE_STANDARD_DOTA_BOT_THINKING)
	mode:SetTowerBackdoorProtectionEnabled(ENABLE_TOWER_BACKDOOR_PROTECTION)

	mode:SetFogOfWarDisabled(DISABLE_FOG_OF_WAR_ENTIRELY)
	mode:SetGoldSoundDisabled(DISABLE_GOLD_SOUNDS)
	mode:SetRemoveIllusionsOnDeath(REMOVE_ILLUSIONS_ON_DEATH)

	mode:SetAlwaysShowPlayerInventory(SHOW_ONLY_PLAYER_INVENTORY)
	mode:SetAnnouncerDisabled(DISABLE_ANNOUNCER)

	if FORCE_PICKED_HERO ~= nil then
		mode:SetCustomGameForceHero(FORCE_PICKED_HERO)
	end

	mode:SetFixedRespawnTime(FIXED_RESPAWN_TIME)
	mode:SetFountainConstantManaRegen(FOUNTAIN_CONSTANT_MANA_REGEN)
	mode:SetFountainPercentageHealthRegen(FOUNTAIN_PERCENTAGE_HEALTH_REGEN)
	mode:SetFountainPercentageManaRegen(FOUNTAIN_PERCENTAGE_MANA_REGEN)
	mode:SetLoseGoldOnDeath(LOSE_GOLD_ON_DEATH)
	mode:SetMaximumAttackSpeed(MAXIMUM_ATTACK_SPEED)
	mode:SetMinimumAttackSpeed(MINIMUM_ATTACK_SPEED)
	mode:SetStashPurchasingDisabled(DISABLE_STASH_PURCHASING)

	if USE_DEFAULT_RUNE_SYSTEM then
		mode:SetUseDefaultDOTARuneSpawnLogic(USE_DEFAULT_RUNE_SYSTEM)
	else
		for rune, spawn in pairs(ENABLED_RUNES) do
			mode:SetRuneEnabled(rune, spawn)
		end
		mode:SetBountyRuneSpawnInterval(BOUNTY_RUNE_SPAWN_INTERVAL)
		mode:SetPowerRuneSpawnInterval(POWER_RUNE_SPAWN_INTERVAL)
	end

	mode:SetUnseenFogOfWarEnabled(USE_UNSEEN_FOG_OF_WAR)
	mode:SetDaynightCycleDisabled(DISABLE_DAY_NIGHT_CYCLE)
	mode:SetKillingSpreeAnnouncerDisabled(DISABLE_KILLING_SPREE_ANNOUNCER)
	mode:SetStickyItemDisabled(DISABLE_STICKY_ITEM)

	self:OnFirstPlayerLoaded()
end
