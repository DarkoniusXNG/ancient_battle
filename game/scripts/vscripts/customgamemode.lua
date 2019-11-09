require('libraries/animations')
require('libraries/notifications')
require('libraries/selection')

require('settings')
require('events')
require('filters')
require('custom_illusions')
require('custom_RNG')
require('custom_spawner')

function ancient_battle_gamemode:PostLoadPrecache()

end

function ancient_battle_gamemode:OnFirstPlayerLoaded()

end

function ancient_battle_gamemode:OnAllPlayersLoaded()
	
	-- Find all buildings on the map
	local buildings = FindUnitsInRadius(DOTA_TEAM_GOODGUYS, Vector(0,0,0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_BUILDING, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)

	-- Iterate through each found entity and check its name
	for _, building in pairs(buildings) do
		if building then
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
			elseif string.find(building_name, "tower") then -- Check if its a tower
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
				elseif GetMapName() == "two_vs_two" then
					-- Buff Towers in 2v2
					building:AddNewModifier(building, nil, "modifier_custom_tower_buff", {})
				end
			elseif string.find(building_name, "fort") then -- Check if its an ancient (throne/tree)
				if GetMapName() == "holdout" then
					building:AddNewModifier(building, nil, "modifier_custom_building_invulnerable", {})
				end
			end
		end
	end
end

function ancient_battle_gamemode:OnHeroInGame(hero)
	
	-- Innate abilities (this is applied to custom created heroes/illusions too)
	self:InitializeInnateAbilities(hero)
	
	Timers:CreateTimer(0.5, function()
		local playerID = hero:GetPlayerID()	-- never nil (-1 by default), needs delay 1 or more frames
		
		if PlayerResource:IsFakeClient(playerID) then
			-- This is happening only for bots
			-- Set starting gold for bots
			hero:SetGold(NORMAL_START_GOLD, false)
		else
			if not PlayerResource.PlayerData[playerID] then
				PlayerResource.PlayerData[playerID] = {}
				print("[Ancient Battle] PlayerResource's PlayerData for playerID "..playerID.." was not properly initialized.")
			end
			-- Set some hero stuff on first spawn or on every spawn (custom or not)
			if PlayerResource.PlayerData[playerID].already_set_hero == true then
				-- This is happening only when players create new heroes with custom hero-create spells:
				-- Dark Ranger Charm, Archmage Conjure Image
			else
				-- This is happening for players when their first hero spawn for the first time
				--print("[Ancient Battle] Hero "..hero:GetUnitName().." spawned in the game for the first time for the player with ID "..playerID)
				
				-- Make heroes briefly visible on spawn (to prevent bad fog interactions)
				hero:MakeVisibleToTeam(DOTA_TEAM_GOODGUYS, 0.5)
				hero:MakeVisibleToTeam(DOTA_TEAM_BADGUYS, 0.5)
				
				-- Set the starting gold for the player's hero
				if PlayerResource:HasRandomed(playerID) then
					PlayerResource:ModifyGold(playerID, RANDOM_START_GOLD-600, false, 0)
				else
					PlayerResource:ModifyGold(playerID, NORMAL_START_GOLD-600, false, 0)
				end
				
				-- Client Settings
				if PlayerResource:IsValidPlayerID(playerID) then
					hero:AddNewModifier(hero, nil, "modifier_client_convars", {})
				end
				
				-- This ensures that this will not happen again if some other hero spawns for the first time during the game
				PlayerResource.PlayerData[playerID].already_set_hero = true
				--print("[Ancient Battle] Hero "..hero:GetUnitName().." set for the player with ID "..playerID)
			end
		end
	end)
end

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
		custom_spawner:Stage1()
	elseif GetMapName() == "two_vs_two" then
		custom_spawner:SpawnNeutrals()
	elseif GetMapName() == "five_vs_five" then
		--custom_spawner:SpawnRoshan()
	end
end

function ancient_battle_gamemode:InitGameMode()
	-- Setup rules
	GameRules:SetHeroRespawnEnabled(ENABLE_HERO_RESPAWN)
	GameRules:SetUseUniversalShopMode(UNIVERSAL_SHOP_MODE)
	GameRules:SetSameHeroSelectionEnabled(ALLOW_SAME_HERO_SELECTION)
	--GameRules:SetHeroSelectionTime(HERO_SELECTION_TIME)
	GameRules:SetHeroSelectPenaltyTime(HERO_SELECTION_PENALTY_TIME)
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
	--GameRules:SetStartingGold(NORMAL_START_GOLD)
	if USE_CUSTOM_HERO_GOLD_BOUNTY then
		GameRules:SetUseBaseGoldBountyOnHeroes(false)
	end
	GameRules:SetFirstBloodActive(ENABLE_FIRST_BLOOD)
	GameRules:SetHideKillMessageHeaders(HIDE_KILL_BANNERS)
	
	-- This is multi-team configuration stuff
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
	gamemode:SetBountyRunePickupFilter(Dynamic_Wrap(ancient_battle_gamemode, "BountyRuneFilter"), self)
	gamemode:SetRuneSpawnFilter(Dynamic_Wrap(ancient_battle_gamemode, "RuneSpawnFilter"), self)

	-- Setting the Healing filter
	gamemode:SetHealingFilter(Dynamic_Wrap(ancient_battle_gamemode, "HealingFilter"), self)

	-- Setting the Gold Filter
	gamemode:SetModifyGoldFilter(Dynamic_Wrap(ancient_battle_gamemode, "GoldFilter"), self)

	-- Setting the Inventory filter
	gamemode:SetItemAddedToInventoryFilter(Dynamic_Wrap(ancient_battle_gamemode, "InventoryFilter"), self)
  
	-- Lua Modifiers
	LinkLuaModifier("modifier_client_convars", "modifiers/modifier_client_convars", LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_custom_building_invulnerable", "modifiers/modifier_custom_building_invulnerable", LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_custom_tower_buff", "modifiers/modifier_custom_tower_buff", LUA_MODIFIER_MOTION_NONE)
	
	print("Ancient Battle custom game initialized.")
end

-- This function is called as the first player loads and sets up the game mode parameters
function ancient_battle_gamemode:CaptureGameMode()

	-- Set GameMode parameters
	local mode = GameRules:GetGameModeEntity()
	mode:SetRecommendedItemsDisabled(RECOMMENDED_BUILDS_DISABLED)
	mode:SetCameraDistanceOverride(CAMERA_DISTANCE_OVERRIDE)
	mode:SetBuybackEnabled(BUYBACK_ENABLED)
	mode:SetCustomBuybackCostEnabled(CUSTOM_BUYBACK_COST_ENABLED)
	mode:SetCustomBuybackCooldownEnabled(CUSTOM_BUYBACK_COOLDOWN_ENABLED)
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
	mode:SetAlwaysShowPlayerInventory(SHOW_ONLY_PLAYER_INVENTORY)
	mode:SetAnnouncerDisabled(DISABLE_ANNOUNCER)
	if FORCE_PICKED_HERO ~= nil then
		mode:SetCustomGameForceHero(FORCE_PICKED_HERO)
	else
		mode:SetDraftingBanningTimeOverride(BANNING_PHASE_TIME)
		mode:SetDraftingHeroPickSelectTimeOverride(HERO_SELECTION_TIME)
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
	
	mode:SetCustomGlyphCooldown(CUSTOM_GLYPH_COOLDOWN)
	mode:SetCustomScanCooldown(CUSTOM_SCAN_COOLDOWN)

	self:OnFirstPlayerLoaded()
end

-- Initializes heroes' innate abilities
function ancient_battle_gamemode:InitializeInnateAbilities(hero)

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
end
