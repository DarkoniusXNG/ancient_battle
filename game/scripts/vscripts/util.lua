function PrintTable(t, indent, done)
  --print ( string.format ('PrintTable type %s', type(keys)) )
  if type(t) ~= "table" then return end

  done = done or {}
  done[t] = true
  indent = indent or 0

  local l = {}
  for k, v in pairs(t) do
    table.insert(l, k)
  end

  table.sort(l)
  for k, v in ipairs(l) do
    -- Ignore FDesc
    if v ~= 'FDesc' then
      local value = t[v]

      if type(value) == "table" and not done[value] then
        done [value] = true
        print(string.rep ("\t", indent)..tostring(v)..":")
        PrintTable (value, indent + 2, done)
      elseif type(value) == "userdata" and not done[value] then
        done [value] = true
        print(string.rep ("\t", indent)..tostring(v)..": "..tostring(value))
        PrintTable ((getmetatable(value) and getmetatable(value).__index) or getmetatable(value), indent + 2, done)
      else
        if t.FDesc and t.FDesc[v] then
          print(string.rep ("\t", indent)..tostring(t.FDesc[v]))
        else
          print(string.rep ("\t", indent)..tostring(v)..": "..tostring(value))
        end
      end
    end
  end
end

-- Colors
COLOR_NONE = '\x06'
COLOR_GRAY = '\x06'
COLOR_GREY = '\x06'
COLOR_GREEN = '\x0C'
COLOR_DPURPLE = '\x0D'
COLOR_SPINK = '\x0E'
COLOR_DYELLOW = '\x10'
COLOR_PINK = '\x11'
COLOR_RED = '\x12'
COLOR_LGREEN = '\x15'
COLOR_BLUE = '\x16'
COLOR_DGREEN = '\x18'
COLOR_SBLUE = '\x19'
COLOR_PURPLE = '\x1A'
COLOR_ORANGE = '\x1B'
COLOR_LRED = '\x1C'
COLOR_GOLD = '\x1D'

--[[ This function is showing Error Messages using notifications library from BMD's Barebones
	Author: Noya
]]
function SendErrorMessage(pID, string)
    Notifications:ClearBottom(pID)
    Notifications:Bottom(pID, {text=string, style={color='#E62020'}, duration=2})
    EmitSoundOnClient("General.Cancel", PlayerResource:GetPlayer(pID))
end

--[[ This function hides all hats (wearables) from the hero and store them into a handle variable
  Date: 09.08.2015.
  Author: Noya (Part of BMD Barebones)
]]
function HideWearables(hero)
	hero.hiddenWearables = {} -- Keep every wearable handle in a table to show them later
	local model = hero:FirstMoveChild()
	while model ~= nil do
		if model:GetClassname() == "dota_item_wearable" then
			model:AddEffects(EF_NODRAW) -- Set model hidden
			table.insert(hero.hiddenWearables, model)
		end
		model = model:NextMovePeer()
	end
end

--[[ This function unhides/shows wearables that were hidden with HideWearables() function.
	Author: Noya (Part of BMD Barebones)
]]
function ShowWearables(hero)
  for i,v in pairs(hero.hiddenWearables) do
    v:RemoveEffects(EF_NODRAW)
  end
end

--[[ This function is needed for changing models (for Arcanas for example)
	Used in firelord_arcana.lua etc.
	Author: Noya
]]
function SwapWearable(unit, target_model, new_model)
    local wearable = unit:FirstMoveChild()
    while wearable ~= nil do
        if wearable:GetClassname() == "dota_item_wearable" then
            if wearable:GetModelName() == target_model then
                wearable:SetModel(new_model)
                return
            end
        end
        wearable = wearable:NextMovePeer()
    end
end
 
-- This function checks if a given unit is Roshan, returns boolean value;
function IsRoshan(unit)
	if unit:IsAncient() and unit:GetName() == "npc_dota_roshan" then
		return true
	else
		return false
	end
end

-- This function checks if this unit/entity is a fountain or not; returns boolean value;
function IsFountain(unit)
	if unit:GetName() == "ent_dota_fountain_bad" or unit:GetName() == "ent_dota_fountain_good" then
		return true
	end
	
	return false
end

-- Initializes heroes' innate abilities
function InitializeInnateAbilities(hero)

	-- List of innate abilities
	local innate_abilities = {
		"firelord_arcana_model",
		"blood_mage_orbs",
		"mana_eater_mana_regen"
	}

	-- Cycle through any innate abilities found, then upgrade them
	for i = 1, #innate_abilities do
		local current_ability = hero:FindAbilityByName(innate_abilities[i])
		if current_ability then
			current_ability:SetLevel(1)
		end
	end
end

--[[ This function interrupts and hide the target hero, applies SuperStrongDispel and CustomPassiveBreak to the target,
    and creates a copy of the target for the caster, returns the hScript copy;
	Target hero has vision over the area where he is moved! You need a modifier to disable this vision;
	Copy/Clone of the target hero is not invulnerable! You need a modifier for that too;
	Used in many abilities ...
]]
function HideAndCopyHero(target, caster)
	if target and caster then
		local caster_team = caster:GetTeamNumber()
		local playerID = caster:GetPlayerOwnerID()
		local target_name = target:GetUnitName()
		local target_origin = target:GetAbsOrigin()
		local target_ability_count = target:GetAbilityCount()
		local target_HP = target:GetHealth()
		local target_MP = target:GetMana()
		local target_level = target:GetLevel()
		
		target:Interrupt()
		target:InterruptChannel()
		target:AddNoDraw() -- needed for hiding the original hero
		
		-- Moving the target (original hero) to the corner of the map
		local corner = Vector(0,0,0)
		if GetMapName() == "two_vs_two" then
			corner = Vector(2300,-2300,-322)
		else
			corner = Vector(7500,-7200,-322)
		end
		target:SetAbsOrigin(corner)
		
		local hidden_modifiers = {
			"modifier_firelord_arcana",
			"modifier_not_removed_with_super_strong_dispel_or_custom_passive_break"
		}
		
		-- Remove all buffs and debuffs from the target
		SuperStrongDispel(target, true, true)
		
		-- Remove passive modifiers from the target with Custom Passive Break
		CustomPassiveBreak(target, 100)
		
		-- Cycle through remaining hidden modifiers and bugging visual effects and remove them
		for i=1, #hidden_modifiers do
			target:RemoveModifierByName(hidden_modifiers[i])	
		end
		
		local ability_table = {}
		local item_table = {}
		ability_table[1] = "dark_ranger_charm" -- obvious reasons, weird interactions
		ability_table[2] = "paladin_eternal_devotion" -- disabling just in case, playerID issues
		ability_table[3] = "perun_electric_trap" -- crashes
		ability_table[4] = "shredder_chakram"	-- crashes
		ability_table[5] = "shredder_chakram_2"	-- crashes
		ability_table[6] = "archmage_mass_teleport" -- preventing abuse
		item_table[1] = "item_tpscroll" -- preventing abuse
		item_table[2] = "item_travel_boots" -- preventing abuse
		item_table[3] = "item_travel_boots_2" -- preventing abuse
		
		-- Creating copy of the target hero
		local copy = CreateUnitByName(target_name, target_origin, true, caster, nil, caster_team) -- handle hUnitOwner MUST be nil, else it will crash the game.
		copy:SetPlayerID(playerID)
		copy:SetControllableByPlayer(playerID, true)
		copy:SetOwner(caster:GetOwner())
		FindClearSpaceForUnit(copy, target_origin, false)
		
		-- Levelling up the Copy of the hero
		for i=1,target_level-1 do
			copy:HeroLevelUp(false) -- false because we don't want to see level up effects
		end

		-- Recreate the items of the original, disabling some items, not ignoring items in backpack
		local disable_item = {}
		for itemSlot=0,8 do
			local item = target:GetItemInSlot(itemSlot)
			if item then
				local itemName = item:GetName()
				local newItem = CreateItem(itemName, copy, copy)
				local newItemName = newItem:GetName()
				disable_item[itemSlot+1] = 0
				for i= 1, #item_table do
					if newItemName == item_table[i] then
						--print("Disabling "..newItemName)
						disable_item[itemSlot+1] = 1
					end
				end
				if disable_item[itemSlot+1] == 0 then
					copy:AddItem(newItem)
				end
			end
		end
		
		-- Enabling and disabling abilities on a copy
		copy:SetAbilityPoints(0)
		local disable_ability = {}
		for abilitySlot=0,target_ability_count-1 do
			local ability = target:GetAbilityByIndex(abilitySlot)
			if ability then 
				local abilityLevel = ability:GetLevel()
				local abilityName = ability:GetAbilityName()
				local copyAbility = copy:FindAbilityByName(abilityName)
				local copyAbilityName = copyAbility:GetAbilityName()
				disable_ability[abilitySlot+1] = 0
				for i = 1, #ability_table do
					if copyAbilityName == ability_table[i] then
						--print("Disabling "..copyAbilityName)
						disable_ability[abilitySlot+1] = 1
					end
				end
				if disable_ability[abilitySlot+1] == 0 then
					copyAbility:SetLevel(abilityLevel)
				end
			end
		end

		-- Setting health and mana to be the same as the original(target) hero at the moment of casting
		copy:SetHealth(target_HP)
		copy:SetMana(target_MP)
		-- Preventing dropping and selling items in inventory
		copy:SetHasInventory(false)
		copy:SetCanSellItems(false)
		-- Disabling bounties because copy can die (even if its invulnerable it can still die: suicide (bloodstone) or axe's cut from above/culling blade)
		copy:SetMaximumGoldBounty(0)
		copy:SetMinimumGoldBounty(0)
		copy:SetDeathXP(0)
		-- Preventing copy hero from respawning (IMPORTANT)
		copy:SetRespawnsDisabled(true)
		-- Storing the information about the original (IMPORTANT for placing the original at the position of the copy, for OnEntityKilled, for OnPlayerLevelUp, for OnHeroInGame)
		copy.original = target
		return copy
	else
		print("target or caster are nil values.")
		return nil
	end
end

--[[ This function interrupts, hides the hero and disables all his passives and auras; If he is not alive it revives him first;
	This function is meant to be used on heroes that will not be unhidden afterwards.
	Used in many abilities ...
]]
function HideTheCopyPermanently(copy)
	if copy then
		-- Effects and auras that are visual while hidden - Special cases
		local hidden_modifiers = {
		"modifier_firelord_arcana",												-- Fire Lord Arcana
		"modifier_drow_ranger_trueshot",										-- Precision Aura (built-in)
		"modifier_drow_ranger_trueshot_aura",									-- Precision Aura (built-in)
		"modifier_drow_ranger_trueshot_global",									-- Precision Aura (built-in)
		"modifier_black_king_bar_immune",										-- Black King Bar (built-in)
		"modifier_item_ring_of_basilius_aura",									-- Ring of Basilius Aura
		"modifier_item_ring_of_aquila_aura",									-- Ring of Aquila Aura
		"modifier_item_mekansm_aura",											-- Mekansm Aura
		"modifier_item_ancient_janggo",											-- Drums of Endurance Aura
		"modifier_item_vladmir",												-- Vladmir's Aura
		"modifier_item_guardian_greaves",										-- Guardian Greaves Aura
		"modifier_item_assault_positive_aura",									-- Assault Cuirass Positive Aura
		"modifier_item_assault_positive_buildings_aura",						-- Assault Cuirass Positive Aura (buildings)
		"modifier_item_assault_negative_armor_aura",							-- Assault Cuirass Negative Aura
		"modifier_item_pipe",													-- Pipe of Insight Aura
		"modifier_item_headdress",												-- Headdress Aura
		"modifier_item_radiance",												-- Radiance Aura
		"modifier_item_crimson_guard_extra",									-- Crimson Guard Active
		"modifier_item_shivas_guard",											-- Shiva's Guard Aura
		"modifier_slippers_of_halcyon_caster"									-- Slippers of Halcyon Active
		}
		if copy:IsAlive() then
			copy:Stop()
			copy:Interrupt()
			copy.died = false
		else
			-- MakeIllusion() and RemoveSelf() are not good here:
			-- Illusions cant deal damage over time (poisons etc.) -> automatic crash to desktop if illusions have dot
			-- Removed units cant deal damage over time -> automatic crash to desktop if dot is still active after removing the unit
			copy:RespawnUnit()
			copy.died = true
		end
		copy:AddNoDraw() 	-- Hiding the hero
		HideWearables(copy)	-- Hiding hats/wearables if some are still visible
		-- Remove most buffs and most debuffs with Super Strong Dispel
		SuperStrongDispel(copy, true, true)
		-- Remove passive modifiers with Custom Break
		CustomPassiveBreak(copy, 100)
		-- Cycle through hidden modifiers and remove them (Death, SuperStrongDispel and CustomPassiveBreak remove most modifiers but we need to make sure for remaining modifiers)
		for i=1, #hidden_modifiers do
			copy:RemoveModifierByName(hidden_modifiers[i])	
		end
		-- Moving the copy to the corner of the map (Hiding him for sure)
		local corner = Vector(0,0,0)
		if GetMapName() == "two_vs_two" then
			corner = Vector(2300,-2300,-322)
		else
			corner = Vector(7500,-7200,-322)
		end
		copy:SetAbsOrigin(corner)
	else
		print("Copy is nil!")
	end
end

--[[ This function reveals the original (that was hidden) hero at certain location;
	This function re-enables abilities and auras (some, not all! it's intentional!) that were disabled in HideAndCopyHero function
	Used in many abilities ...
]]
function UnhideOriginalOnLocation(original, location)
	if original then
		original:RemoveNoDraw()	-- Unhiding the hero
		if location~= nil then
			original:SetAbsOrigin(location) -- Moving the original to location instantly
		else
			print("Original is revealed at the location where it was hidden")
		end
		FindClearSpaceForUnit(original, original:GetAbsOrigin(), false)
		
		-- List of auras and abilities with visual effect
		local hidden_abilities = {
		"firelord_arcana_model",
		"hidden_ability_not_affected_with_custom_passive_break"
		}
		local passive_modifiers = {
		"modifier_firelord_arcana",
		"modifier_not_removed_with_super_strong_dispel_or_custom_passive_break"
		}
		-- Re-enabling removed passive modifiers with CustomPassiveBreak
		CustomPassiveBreak(original, 0.1)
		-- Cycle through remaining hidden abilities found on the hero, then re-activate them
		for i=1, #hidden_abilities do
			local ability = original:FindAbilityByName(hidden_abilities[i])
			if ability then
				if ability:GetLevel() ~= 0 then
					ability:ApplyDataDrivenModifier(original, original, passive_modifiers[i], {})
				end
			end
		end
	else
		print("Hero that needed to be unhidden is nil.")
	end
end

--[[ This function disables passive modifiers from custom abilities for the duration
	Attention: This only works with abilities that have 1 passive modifier and if the order of strings in tables is not random.
	If Duration is 100, passives are disabled forever / until death or removal of the hero.
	Used in DamageFilter, HideAndCopyHero, HideTheCopyPermanently, UnhideOriginalOnLocation ...
]]
function CustomPassiveBreak(unit, duration)
	-- List of custom abilities with passive modifiers
	local abilities_with_passives = {
	"axe_custom_counter_helix",
	"death_knight_chilling_touch",
	"dark_ranger_custom_marksmanship",
	"life_stealer_custom_anabolic_frenzy",
	"paladin_eternal_devotion",
	"paladin_divine_retribution",
	"queenofpain_custom_pain_steal",
	"firelord_flaming_presence",
	"stealth_assassin_desolate",
	"gambler_lucky_stars",
	"silencer_custom_last_word",
	"astral_trekker_time_constant",
	"astral_trekker_giant_growth",
	"archmage_arcane_magic",
	"lich_custom_freezing_touch",
	"brewmaster_custom_drunken_brawler",
	"mana_eater_mana_shell",
	"alchemist_custom_philosophers_stone",
	"blademaster_custom_blade_dance",
	"astral_trekker_pulverize"
	}
	local passive_modifiers = {
	"modifier_counter_helix_aura_ultimate",
	"modifier_chilling_death_aura",
	"modifier_custom_marksmanship_passive",
	"modifier_anabolic_frenzy_passive",
	"modifier_devotion_aura_applier",
	"modifier_retribution_aura_applier",
	"modifier_pain_steal_aura_applier",
	"modifier_firelord_presence_aura_applier",
	"modifier_stealth_assassin_desolate",
	"modifier_gambler_lucky_stars_passive",
	"modifier_last_word_aura_applier",
	"modifier_time_constant",
	"modifier_giant_growth_passive",
	"modifier_archmage_aura_applier",
	"modifier_lich_freezing_touch_passive",
	"modifier_custom_drunken_brawler_passive",
	"modifier_mana_shell_passive",
	"modifier_philosophers_stone_passive_buff",
	"modifier_custom_blade_dance_passive",
	"modifier_custom_pulverize_passive"
	}
	if unit and duration then
		for i=1, #passive_modifiers do
			unit:RemoveModifierByName(passive_modifiers[i])
		end
		
		unit.custom_already_breaked = true
		
		if duration ~= 100 then
			Timers:CreateTimer(duration, function()
				for i=1, #abilities_with_passives do
					local ability = unit:FindAbilityByName(abilities_with_passives[i])
					if ability then
						if ability:GetLevel() ~= 0 then
							ability:ApplyDataDrivenModifier(unit, unit, passive_modifiers[i], {})
						end
					end
				end
				unit.custom_already_breaked = false
			end)
		end
	end
end

--[[ This function disables inventory and removes item passives.
	Used in Master Staff ...
]]
function CustomItemDisable(caster, unit)
	local passive_item_modifiers_exceptions ={
	"modifier_item_empty_bottle",
	"modifier_item_observer_ward",
	"modifier_item_tome_of_knowledge",
	"modifier_item_sentry_ward",
	"modifier_item_blink_dagger",
	"modifier_item_armlet_unholy_strength"
	}
	if unit then
		for itemSlot=0,8 do
			local item = unit:GetItemInSlot(itemSlot)
			if item then
				local item_owner = item:GetPurchaser()
				local unit_owner = unit:GetOwner()
				local caster_owner = caster:GetOwner()
				if item_owner == unit then
					item:SetPurchaser(caster)
				elseif item_owner == unit_owner then
					item:SetPurchaser(caster_owner)
				end
			end
		end
		-- Find All modifiers (ALL buffs, debuffs, passives)
		local all_modifiers = unit:FindAllModifiers()
		-- Iterate through each one and check their ability
		for _, modifier in pairs(all_modifiers) do
			local modifier_ability = modifier:GetAbility()			-- can be nil
			if modifier_ability then
				if modifier_ability:IsItem() then
					-- Get the duration of the item modifier
					local item_modifier_duration = modifier:GetDuration()
					-- If the modifier duration is -1 (infinite duration) there is a chance that this is a passive modifier
					if item_modifier_duration == -1 then
						-- Get the name of the item modifier
						local item_modifier_name = modifier:GetName()
						-- Initializing handle: safe_to_remove
						modifier.safe_to_remove = true
						for i=1, #passive_item_modifiers_exceptions do
							if item_modifier_name == passive_item_modifiers_exceptions[i] then
								modifier.safe_to_remove = false
							end
						end
						if modifier.safe_to_remove == true then
							unit:RemoveModifierByName(item_modifier_name)
						end
					end
				end
			end
		end
		
		-- Preventing dropping and selling items in inventory
		unit:SetHasInventory(false)
		unit:SetCanSellItems(false)
	else
		print("unit is nil!")
	end
end

--[[ This function enables inventory and item passives if they were disabled with CustomItemDisable
	Used in Master Staff ...
]]
function CustomItemEnable(caster, unit)
	if unit then
		for itemSlot=0,8 do
			local item = unit:GetItemInSlot(itemSlot)
			if item then
				local item_owner = item:GetPurchaser()
				local unit_owner = unit:GetOwner()
				local caster_owner = caster:GetOwner()
				if item_owner == caster then
					item:SetPurchaser(unit)
				elseif item_owner == caster_owner then
					item:SetPurchaser(unit_owner)
				end
			end
		end
		-- Enable dropping and selling items back
		unit:SetHasInventory(true)
		unit:SetCanSellItems(true)
		-- To reset unit's items and their passive modifiers: add an item and remove it
		local new_item = CreateItem("item_magic_wand", unit, unit)
		unit:AddItem(new_item)
		new_item:RemoveSelf()
	else
		print("unit is nil!")
	end
end

--[[ This function applies strong dispel and removes almost all debuffs; 
	Can remove most buffs that are not removable with basic dispel;
	Can remove most debuffs that are not removable with strong dispel;
	Used in many abilities, HideAndCopyHero, HideTheCopyPermanently, ...
]]
function SuperStrongDispel(target, bCustomRemoveAllDebuffs, bCustomRemoveAllBuffs)
	if target then
		local BuffsCreatedThisFrameOnly = false
		local RemoveExceptions = false
		local RemoveStuns = false
		
		if bCustomRemoveAllDebuffs == true then
			
			RemoveStuns = true -- this ensures removing modifiers debuffs with "IsStunDebuff" "1"
			
			target:RemoveModifierByName("modifier_entrapment")					-- pierces BKB, doesn't get removed with BKB
			target:RemoveModifierByName("modifier_volcano_stun")				-- pierces BKB
			target:RemoveModifierByName("modifier_time_stop")					-- pierces BKB
			target:RemoveModifierByName("modifier_custom_enfeeble_debuff")		-- pierces BKB, doesn't get removed with BKB
			target:RemoveModifierByName("modifier_venomancer_poison_sting")		-- pierces BKB, doesn't get removed with BKB
			target:RemoveModifierByName("modifier_purge_enemy_hero")			-- pierces BKB, doesn't get removed with BKB
			target:RemoveModifierByName("modifier_purge_enemy_creep")			-- pierces BKB, doesn't get removed with BKB
			target:RemoveModifierByName("modifier_bane_nightmare_invulnerable") -- invulnerable type
			target:RemoveModifierByName("modifier_axe_berserkers_call")			-- pierces BKB, doesn't get removed with BKB
			
			target:RemoveModifierByName("modifier_item_skadi_slow")				-- pierces BKB, doesn't get removed with BKB
			target:RemoveModifierByName("modifier_heavens_halberd_debuff")		-- doesn't pierce BKB, doesn't get removed with BKB
			target:RemoveModifierByName("modifier_sheepstick_debuff")			-- doesn't pierce BKB, cannot be removed with Strong Dispel
			target:RemoveModifierByName("modifier_silver_edge_debuff")			-- doesn't pierce BKB, doesn't get removed with BKB
			-- Exceptions:
			-- Exception 1: modifier_charmed_hero       			(Dark Ranger Charm - not advisable)
			-- Exception 2: modifier_incinerate_stack   			(Fire Lord Incinerate - not advisable)
		end
		
		if bCustomRemoveAllBuffs == true then
			-- List of undispellable buffs that are safe to remove without making errors, crashes etc.
			local undispellable_with_normal_dispel_buffs = {
				"modifier_time_slow_aura_applier",
				"modifier_custom_chemical_rage_buff",
				"modifier_alchemist_chemical_rage",
				"modifier_custom_blade_storm",
				"modifier_custom_rage_buff",
				"modifier_roulette_caster_buff",
				"modifier_mass_haste_buff",
				"modifier_giant_growth_active",
				"modifier_drunken_fist_knockback",
				"modifier_drunken_fist_bonus",
				"modifier_mana_flare_armor_buff",
				"modifier_mana_flare_aura_applier",
				"modifier_absorb_bonus_mana_scepter",
				"modifier_paladin_divine_shield",
				"modifier_paladin_divine_shield_upgraded",
				"modifier_black_king_bar_immune",
				"modifier_slippers_of_halcyon_caster",
				"modifier_custom_marksmanship_buff"
				-- Death Pact
			}
			
			for i=1, #undispellable_with_normal_dispel_buffs do
				target:RemoveModifierByName(undispellable_with_normal_dispel_buffs[i])	
			end
		end
		
		target:Purge(bCustomRemoveAllBuffs, bCustomRemoveAllDebuffs, BuffsCreatedThisFrameOnly, RemoveStuns, RemoveExceptions)
	else
		print("Target for Super Strong Dispel is nil.")
	end
end

-- Finding units in a trapezoid
function FindUnitsinTrapezoid(team_number, direction, start_position, cache_unit, start_radius, end_radius, distance, target_team, target_type, target_flags, order, cache)
	local circle = FindUnitsInRadius(team_number, start_position, cache_unit, distance+end_radius, target_team, target_type, target_flags, order, cache)
	local direction = direction
	direction.z = 0.0
	direction = direction:Normalized()
	local perpendicular_direction = Vector(direction.y, -direction.x, 0.0)
	local end_position = start_position + direction*distance
	
	-- Trapezoid vertexes
	local vertex1 = start_position - perpendicular_direction*start_radius
	local vertex2 = start_position + perpendicular_direction*start_radius
	local vertex3 = end_position - perpendicular_direction*end_radius
	local vertex4 = end_position + perpendicular_direction*end_radius
	
	-- Trapezoid sides (vectors)
	local vector1 = vertex2 - vertex1	-- vector12
	local vector2 = vertex4 - vertex2	-- vector24
	local vector3 = vertex3 - vertex4	-- vector43
	local vector4 = vertex1 - vertex3	-- vector31
	
	-- For debugging - it shows vertexes briefly
	--local ward1 = CreateUnitByName("npc_dota_observer_wards", vertex1, true, attacker, attacker, team_number)
	--FindClearSpaceForUnit(ward1, vertex1, false)
	--ward1:AddNewModifier(attacker, nil, "modifier_kill", {duration = 2.0})
	--local ward2 = CreateUnitByName("npc_dota_observer_wards", vertex2, true, attacker, attacker, team_number)
	--FindClearSpaceForUnit(ward2, vertex2, false)
	--ward2:AddNewModifier(attacker, nil, "modifier_kill", {duration = 2.0})
	--local ward3 = CreateUnitByName("npc_dota_observer_wards", vertex3, true, attacker, attacker, team_number)
	--FindClearSpaceForUnit(ward3, vertex3, false)
	--ward3:AddNewModifier(attacker, nil, "modifier_kill", {duration = 2.0})
	--local ward4 = CreateUnitByName("npc_dota_observer_wards", vertex4, true, attacker, attacker, team_number)
	--FindClearSpaceForUnit(ward4, vertex4, false)
	--ward4:AddNewModifier(attacker, nil, "modifier_kill", {duration = 2.0})
	
	local unit_table = {}
	
	for _, unit in pairs(circle) do
		if unit then
			local unit_location = unit:GetAbsOrigin()
			local vector1p = unit_location - vertex1
			local vector2p = unit_location - vertex2
			local vector3p = unit_location - vertex4
			local vector4p = unit_location - vertex3
			local cross1 = vector1.x * vector1p.y - vector1.y * vector1p.x
			local cross2 = vector2.x * vector2p.y - vector2.y * vector2p.x
			local cross3 = vector3.x * vector3p.y - vector3.y * vector3p.x
			local cross4 = vector4.x * vector4p.y - vector4.y * vector4p.x
			if (cross1 > 0 and cross2 > 0 and cross3 > 0 and cross4 > 0) or (cross1 < 0 and cross2 < 0 and cross3 < 0 and cross4 < 0) then
				table.insert(unit_table, unit)
			end
		end
    end
	return unit_table
end

-- Custom Cleave function
function CustomCleaveAttack(attacker, target, ability, main_damage, damage_percent, cleave_origin, start_radius, end_radius, distance, particle)
	if attacker == nil then
		print("Attacker/Cleaver is nil!")
		return nil
	end
	local team_number = attacker:GetTeamNumber()
	local direction = attacker:GetForwardVector()
	local cache_unit = nil
	local order = 0
	local cache = false
	
	local damage_table = {}
	damage_table.attacker = attacker
	
	local target_team
	local target_type
	local target_flags
	
	if ability then
		target_team = ability:GetAbilityTargetTeam()
		target_type = ability:GetAbilityTargetType()
		target_flags = ability:GetAbilityTargetFlags()
		damage_table.damage_type = ability:GetAbilityDamageType()
		damage_table.ability = ability
	else
		target_team = DOTA_UNIT_TARGET_TEAM_BOTH
		target_type = bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
		target_flags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
		damage_table.damage_type = DAMAGE_TYPE_PHYSICAL
	end
	
	if target == nil then
		print("Attacked target is nil!")
		return nil
	end
	
	if target:GetTeamNumber() == team_number then
		--print("Cleave doesn't work when attacking allies!")
		return		-- Comment this if you want you to cleave of allies
	end
	
	if target:IsTower() or target:IsBarracks() or target:IsBuilding() then
		--print("Cleave doesn't work when attacking buildings!")
		return
	end
	
	if target:IsOther() then
		--print("Cleave doesn't work when attacking ward-like units!")
		return
	end
	
	local affected_units = FindUnitsinTrapezoid(team_number, direction, cleave_origin, cache_unit, start_radius, end_radius, distance, target_team, target_type, target_flags, order, cache)
	
	-- Calculating damage and setting damage flags
	damage_table.damage = main_damage*damage_percent/100
	damage_table.damage_flags = bit.bor(DOTA_DAMAGE_FLAG_IGNORES_PHYSICAL_ARMOR, DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL)
	
	for k, unit in pairs(affected_units) do
		if unit ~= target then
			damage_table.victim = unit
			ApplyDamage(damage_table)
		end
	end
	
	-- Particles
	--local cleave_pfx = ParticleManager:CreateParticle(particle, PATTACH_ABSORIGIN, target)
	--ParticleManager:SetParticleControl(cleave_pfx, 0, target:GetAbsOrigin())
	--ParticleManager:ReleaseParticleIndex(cleave_pfx)

end
