-- This library allow for easily delayed/timed actions
require('libraries/timers')
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

--[[
  This function should be used to set up Async precache calls at the beginning of the gameplay.

  In this function, place all of your PrecacheItemByNameAsync and PrecacheUnitByNameAsync.  These calls will be made
  after all players have loaded in, but before they have selected their heroes. PrecacheItemByNameAsync can also
  be used to precache dynamically-added datadriven abilities instead of items.  PrecacheUnitByNameAsync will 
  precache the precache{} block statement of the unit and all precache{} block statements for every Ability# 
  defined on the unit.

  This function should only be called once.  If you want to/need to precache more items/abilities/units at a later
  time, you can call the functions individually (for example if you want to precache units in a new wave of
  holdout).

  This function should generally only be used if the Precache() function in addon_game_mode.lua is not working.
]]
function ancient_battle_gamemode:PostLoadPrecache()

end

--[[
  This function is called once and only once as soon as the first player (almost certain to be the server in local lobbies) loads in.
  It can be used to initialize state that isn't initializeable in InitGameMode() but needs to be done before everyone loads in.
]]
function ancient_battle_gamemode:OnFirstPlayerLoaded()

end

--[[
  This function is called once and only once after all players have loaded into the game, right as the hero selection time begins.
  It can be used to initialize non-hero player state or adjust the hero selection (i.e. force random etc)
]]
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
  This function is called once and only once for every player when they spawn into the game for the first time.  It is also called
  if the player's hero is replaced with a new hero for any reason.  This function is useful for initializing heroes, such as adding
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
			local ancient_entindex = ancient:GetEntityIndex()
			local ancient_handle = EntIndexToHScript(ancient_entindex)
			ancient_handle:AddNewModifier(ancient_handle, nil, "modifier_custom_building_invulnerable", {})
		end)
		-- Start Spawning the Horde
		SpawnFirstSevenWaves()
	end
end

-- This function initializes the game mode and is called before anyone loads into the game
-- It can be used to pre-initialize any values/tables that will be needed later
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
	GameRules:SetUseCustomHeroXPValues(USE_CUSTOM_XP_VALUES)
	GameRules:SetGoldPerTick(GOLD_PER_TICK)
	GameRules:SetGoldTickTime(GOLD_TICK_TIME)
	GameRules:SetUseBaseGoldBountyOnHeroes(USE_STANDARD_HERO_GOLD_BOUNTY)
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
	
	--ListenToGameEvent("dota_tutorial_shop_toggled", Dynamic_Wrap(ancient_battle_gamemode, 'OnShopToggled'), self)
	--ListenToGameEvent('player_spawn', Dynamic_Wrap(ancient_battle_gamemode, 'OnPlayerSpawn'), self)
	--ListenToGameEvent('dota_unit_event', Dynamic_Wrap(ancient_battle_gamemode, 'OnDotaUnitEvent'), self)
	--ListenToGameEvent('nommed_tree', Dynamic_Wrap(ancient_battle_gamemode, 'OnPlayerAteTree'), self)
	--ListenToGameEvent('player_completed_game', Dynamic_Wrap(ancient_battle_gamemode, 'OnPlayerCompletedGame'), self)
	--ListenToGameEvent('dota_match_done', Dynamic_Wrap(ancient_battle_gamemode, 'OnDotaMatchDone'), self)
	--ListenToGameEvent('dota_combatlog', Dynamic_Wrap(ancient_battle_gamemode, 'OnCombatLogEvent'), self)
	--ListenToGameEvent('dota_player_killed', Dynamic_Wrap(ancient_battle_gamemode, 'OnPlayerKilled'), self)
	--ListenToGameEvent('player_team', Dynamic_Wrap(ancient_battle_gamemode, 'OnPlayerTeam'), self)

	-- Change random seed
	local timeTxt = string.gsub(string.gsub(GetSystemTime(), ':', ''), '0','')
	math.randomseed(tonumber(timeTxt))

	-- Initialized tables for tracking state
	self.bSeenWaitForPlayers = false
	
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
  
	-- Lua Modifiers
	LinkLuaModifier("modifier_client_convars", "libraries/modifiers/modifier_client_convars", LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_custom_building_invulnerable", "libraries/modifiers/modifier_custom_building_invulnerable", LUA_MODIFIER_MOTION_NONE)
	
	print("Ancient Battle game mode initialized.")
end

mode = nil
-- This function is called as the first player loads and sets up the game mode parameters
function ancient_battle_gamemode:CaptureGameMode()
	if mode == nil then
		-- Set GameMode parameters
		mode = GameRules:GetGameModeEntity()
		mode:SetRecommendedItemsDisabled(RECOMMENDED_BUILDS_DISABLED)
		mode:SetCameraDistanceOverride(CAMERA_DISTANCE_OVERRIDE)
		mode:SetCustomBuybackCostEnabled(CUSTOM_BUYBACK_COST_ENABLED)
		mode:SetCustomBuybackCooldownEnabled(CUSTOM_BUYBACK_COOLDOWN_ENABLED)
		mode:SetBuybackEnabled(BUYBACK_ENABLED)
		mode:SetTopBarTeamValuesOverride(USE_CUSTOM_TOP_BAR_VALUES)
		mode:SetTopBarTeamValuesVisible(TOP_BAR_VISIBLE)
		mode:SetUseCustomHeroLevels(USE_CUSTOM_HERO_LEVELS)
		mode:SetCustomXPRequiredToReachNextLevel(XP_PER_LEVEL_TABLE)

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
		end
		
		mode:SetUnseenFogOfWarEnabled(USE_UNSEEN_FOG_OF_WAR)
		mode:SetDaynightCycleDisabled(DISABLE_DAY_NIGHT_CYCLE)
		mode:SetKillingSpreeAnnouncerDisabled(DISABLE_KILLING_SPREE_ANNOUNCER)
		mode:SetStickyItemDisabled(DISABLE_STICKY_ITEM)

		self:OnFirstPlayerLoaded()
  end 
end

-- Order filter function
function ancient_battle_gamemode:OrderFilter(event)
	--PrintTable(event)
	
	local order = event.order_type
	local units = event.units
	
	-- Drunken haze movement order modification: imitating drunk state
	if order == DOTA_UNIT_ORDER_MOVE_TO_POSITION then
		local unit_with_order = EntIndexToHScript(units["0"])
		
		if unit_with_order:HasModifier("modifier_custom_drunken_haze_debuff") and unit_with_order:IsHero() then
			local offsetVector = RandomVector(200)
			event.position_x = event.position_x + offsetVector.x
			event.position_y = event.position_y + offsetVector.y
			return true
		end
    end
	
	-- Anti-Magic Field cast order modification: Cast spells inside this field have no effect but they go on cd and mana is spent
	if order == DOTA_UNIT_ORDER_CAST_POSITION or order == DOTA_UNIT_ORDER_CAST_TARGET or order == DOTA_UNIT_ORDER_CAST_NO_TARGET or order == DOTA_UNIT_ORDER_CAST_TOGGLE or order == DOTA_UNIT_ORDER_CAST_TOGGLE_AUTO then
		local abilityIndex = event.entindex_ability
		local ability = EntIndexToHScript(abilityIndex)
		local caster = EntIndexToHScript(units["0"])
		
		if caster:HasModifier("modifier_anti_magic_field_debuff") and (not ability:IsItem()) then
			ability:UseResources(true,true,true)
			local pID = caster:GetPlayerOwnerID()
			SendErrorMessage(pID, "Used Spell has no effect!")
			return false
		end		
	end
	
	return true
end

-- Damage filter function
function ancient_battle_gamemode:DamageFilter(keys)
	--PrintTable(keys)
	
	local attacker
	local victim
	if keys.entindex_attacker_const and keys.entindex_victim_const then
		attacker = EntIndexToHScript(keys.entindex_attacker_const)
		victim = EntIndexToHScript(keys.entindex_victim_const)
	else
		return false
	end
	
	local damage_type = keys.damagetype_const
	local inflictor = keys.entindex_inflictor_const	-- keys.entindex_inflictor_const is nil if damage is not caused by ability
	local damage_after_reductions = keys.damage 	-- keys.damage is damage after reductions
	
	local damaging_ability
	if inflictor then
		damaging_ability = EntIndexToHScript(inflictor)
	else
		damaging_ability = nil
	end
	
	-- Dont reflect the reflected damage
	local dont_reflect_flag = nil
	if damaging_ability then
		local damaging_ability_name = damaging_ability:GetName()
		if damaging_ability_name == "item_blade_mail" or damaging_ability_name =="item_orb_of_reflection" then
			dont_reflect_flag = true
		end
	end
	
	-- Lack of entities handling (illusions error fix)
	if attacker:IsNull() or victim:IsNull() then
		return false
	end
	
	-- Axe Blood Mist Power: Converting physical and magical damage of SPELLS to pure damage
	if damaging_ability and attacker:HasModifier("modifier_blood_mist_power_buff") and keys.damage > 0 then
		
		local ability = attacker:FindAbilityByName("axe_custom_blood_mist_power")
		if ability and ability ~= damaging_ability then
			
			-- Doesn't convert damage from items
			if (not damaging_ability:IsItem()) then
				
				-- Nullifying the damage of the spell (It will be reapplied later)
				keys.damage = 0
				
				-- Initializing the value of original damage
				local original_damage = damage_after_reductions
			
				-- Is the damage_type physical or magical?
				if damage_type == DAMAGE_TYPE_PHYSICAL then
					-- Armor of the victim
					local armor = victim:GetPhysicalArmorValue()
					-- Physical damage is reduced by armor
					local damage_armor_reduction = 1-(armor*0.05/(1+0.05*(math.abs(armor))))
					-- Physical damage equation: damage_after_reductions = original_damage * damage_armor_reduction
					original_damage = damage_after_reductions/damage_armor_reduction
				elseif damage_type == DAMAGE_TYPE_MAGICAL then
					-- Magic Resistance of the victim
					local magic_resistance = victim:GetMagicalArmorValue()
					-- Magical damage is reduced by magic resistance
					local damage_magic_resist_reduction = 1-magic_resistance
					-- Magical damage equation: damage_after_reductions = original_damage * damage_magic_resist_reduction
					original_damage = damage_after_reductions/damage_magic_resist_reduction
				end
				
				local damage_table = {}
				damage_table.victim = victim
				damage_table.attacker = attacker
				damage_table.damage_type = DAMAGE_TYPE_PURE
				damage_table.ability = ability
				damage_table.damage = math.floor(original_damage)
		
				ApplyDamage(damage_table)
			end
		end
	end
	
	if attacker:IsNull() or victim:IsNull() then
		return false
	end
	
	-- Orb of Reflection: Damage prevention and Reflecting all damage before reductions as Pure damage to the attacker
	if victim:HasModifier("item_modifier_orb_of_reflection_active_reflect") and keys.damage > 0 then

		-- Nullifying the damage to victim
		keys.damage = 0
		
		-- Reflect or not
		if not dont_reflect_flag then	
			local ability
			for i = 0,8 do
				local this_item = victim:GetItemInSlot(i)
				if this_item then
					if this_item:GetName() == "item_orb_of_reflection" then
						ability = this_item
					end
				end
			end
			
			-- Initializing the value of original damage
			local original_damage = damage_after_reductions
			
			if damage_type == DAMAGE_TYPE_PHYSICAL then
				-- Armor of the victim
				local armor = victim:GetPhysicalArmorValue()
				-- Physical damage is reduced by armor
				local damage_armor_reduction = 1-(armor*0.05/(1+0.05*(math.abs(armor))))
				-- Physical damage equation: damage_after_reductions = original_damage * damage_armor_reduction
				if damaging_ability then
					-- Damage came from an ability (spell or item)
					original_damage = damage_after_reductions/damage_armor_reduction
				else
					-- Damage came from a physical attack (Damage block is not calculated)
					local average_attack_damage = attacker:GetAverageTrueAttackDamage(attacker)
					local damage_before_armor_reduction = damage_after_reductions / damage_armor_reduction
					original_damage = math.max(damage_before_armor_reduction, average_attack_damage)
				end
			elseif damage_type == DAMAGE_TYPE_MAGICAL then
				-- Magic Resistance of the victim
				local magic_resistance = victim:GetMagicalArmorValue()
				-- Magical damage is reduced by magic resistance
				local damage_magic_resist_reduction = 1-magic_resistance
				-- Magical damage equation: damage_after_reductions = original_damage * damage_magic_resist_reduction
				original_damage = damage_after_reductions/damage_magic_resist_reduction
			end
			
			if ability and ability ~= damaging_ability and attacker ~= victim and (attacker:IsTower() == false) and (IsFountain(attacker) == false) then
				-- Reflect damage to the attacker
				local damage_table = {}
				damage_table.victim = attacker
				damage_table.attacker = victim
				damage_table.damage_type = DAMAGE_TYPE_PURE
				damage_table.ability = ability
				damage_table.damage = original_damage
				damage_table.damage_flags = DOTA_DAMAGE_FLAG_REFLECTION
		
				ApplyDamage(damage_table)
			end
		end
	end
	
	if attacker:IsNull() or victim:IsNull() then
		return false
	end
	
	-- Orb of Reflection: Partial Damage return to the attacker as Magical damage (DOESN'T WORK ON ILLUSIONS!)
	if victim:HasModifier("item_modifier_orb_of_reflection_passive_return") and not (victim:HasModifier("item_modifier_orb_of_reflection_active_reflect")) and victim:IsRealHero() and keys.damage > 0 then

		-- Return or not
		if not dont_reflect_flag then	
			local ability
			for i = 0,8 do
				local this_item = victim:GetItemInSlot(i)
				if this_item then
					if this_item:GetName() == "item_orb_of_reflection" then
						ability = this_item
					end
				end
			end
			
			-- Fetch the damage return amount/percentage
			local ability_level = ability:GetLevel() - 1
			local damage_return = ability:GetLevelSpecialValueFor("passive_damage_return", ability_level)
			
			-- Calculating damage that will be returned to attacker
			local new_damage = damage_after_reductions*damage_return/100
			
			if attacker:IsNull() or victim:IsNull() then
				return false
			end
			
			if ability and ability ~= damaging_ability and attacker ~= victim and (attacker:IsTower() == false) and (IsFountain(attacker) == false) then
				-- Returning Damage to the attacker
				local damage_table = {}
				damage_table.victim = attacker
				damage_table.attacker = victim
				damage_table.damage_type = DAMAGE_TYPE_MAGICAL
				damage_table.ability = ability
				damage_table.damage = new_damage
				damage_table.damage_flags = DOTA_DAMAGE_FLAG_REFLECTION
				
				ApplyDamage(damage_table)
			end
		end
	end
	
	if attacker:IsNull() or victim:IsNull() then
		return false
	end
	
	-- Infused Robe Damage Blocking any damage type after all reductions (DOESN'T WORK ON ILLUSIONS!)
	if victim:HasModifier("item_modifier_infused_robe_damage_block") and not (victim:HasModifier("item_modifier_infused_robe_damage_barrier")) and victim:IsRealHero() and keys.damage > 0 then
		
		local ability
		for i = 0,8 do
			local this_item = victim:GetItemInSlot(i)
			if this_item then
				if this_item:GetName() == "item_infused_robe" then
					ability = this_item
				end
			end
		end
		-- Fetch the damage block amount
		local ability_level = ability:GetLevel() - 1
		local damage_block = ability:GetLevelSpecialValueFor("damage_block", ability_level)
		
		-- Calculating new/reduced damage and blocked damage
		local new_damage = math.max(keys.damage - damage_block, 0)
		local blocked_damage = keys.damage - new_damage -- max(blocked_damage) = damage_block
		
		if attacker:IsNull() or victim:IsNull() then
			return false
		end
		
		if (attacker:IsTower() == false) and (IsFountain(attacker) == false) then
			-- Show block message
			if damage_type == DAMAGE_TYPE_PHYSICAL then
				SendOverheadEventMessage(nil, OVERHEAD_ALERT_BLOCK, victim, blocked_damage, nil)
			else
				SendOverheadEventMessage(nil, OVERHEAD_ALERT_MAGICAL_BLOCK, victim, blocked_damage, nil)
			end

			-- Reduce damage
			keys.damage = new_damage
		end
	end
	
	if attacker:IsNull() or victim:IsNull() then
		return false
	end
	
	-- Infused Robe Divine Barrier (Anti-Damage Shield/Shell)
	if victim:HasModifier("item_modifier_infused_robe_damage_barrier") and keys.damage > 0 then
		
		local ability
		for i = 0,8 do
			local this_item = victim:GetItemInSlot(i)
			if this_item then
				if this_item:GetName() == "item_infused_robe" then
					ability = this_item
				end
			end
		end
		-- Fetch the barrier block amount
		local ability_level = ability:GetLevel() - 1
		local barrier_absorb_damage = ability:GetLevelSpecialValueFor("barrier_block", ability_level)
		
		local absorbed_now = 0
		local absorbed_already
		if victim.anti_damage_shell_absorbed then
			absorbed_already = victim.anti_damage_shell_absorbed
		else
			absorbed_already = 0
		end

		if keys.damage + absorbed_already < barrier_absorb_damage then
			absorbed_now = keys.damage
			victim.anti_damage_shell_absorbed = absorbed_already + keys.damage
		else
			-- Absorb up to the limit and end
			absorbed_now = barrier_absorb_damage - absorbed_already
			victim:RemoveModifierByName("item_modifier_infused_robe_damage_barrier")
			victim.anti_damage_shell_absorbed = nil
		end
		-- Absorb damage with Anti-Damage shield/shell
		keys.damage = keys.damage - absorbed_now
	end
	
	if attacker:IsNull() or victim:IsNull() then
		return false
	end
	
	-- Disabling custom passive modifiers with Silver Edge: We first detect all attacks made with heroes that have silver edge in inventory on real heroes without spell immunity.
	if (not damaging_ability) and attacker:HasModifier("modifier_item_silver_edge") and attacker:IsRealHero() and victim:IsRealHero() and (not victim:IsMagicImmune()) then
		-- Is the victim breaked (passive_disabled) with Silver Edge?
		if victim:HasModifier("modifier_silver_edge_debuff") then
			if not victim.custom_already_breaked then
				CustomPassiveBreak(victim, 5.0) -- duration should be the same as silver edge debuff
			end
		end
	end
	
	return true
end

-- Modifier filter function
function ancient_battle_gamemode:ModifierFilter(keys)
	--PrintTable(keys)
	
	local unit_with_modifier = EntIndexToHScript(keys.entindex_parent_const)
	local modifier_name = keys.name_const
	local modifier_duration = keys.duration
	local modifier_caster
	if keys.entindex_caster_const then
		modifier_caster = EntIndexToHScript(keys.entindex_caster_const)
	else
		modifier_caster = nil
	end
	
	return true
end

-- Experience filter function
function ancient_battle_gamemode:ExperienceFilter(keys)
	--PrintTable(keys)
	local experience = keys.experience
	local playerID = keys.player_id_const
	local reason = keys.reason_const
	
	return true
end

-- Tracking Projectile (attack and spell projectiles) filter function
function ancient_battle_gamemode:ProjectileFilter(keys)
	--PrintTable(keys)
	
	local can_be_dodged = keys.dodgeable				-- values: 1 or 0
	local ability_index = keys.entindex_ability_const	-- value if not ability: -1
	local source_index = keys.entindex_source_const
	local target_index = keys.entindex_target_const
	local expire_time = keys.expire_time
	local is_an_attack_projectile = keys.is_attack		-- values: 1 or 0
	local max_impact_time = keys.max_impact_time
	local projectile_speed = keys.move_speed
	
	return true
end
