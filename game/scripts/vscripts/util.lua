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

-- This function is showing Error Messages using BMD's notifications library
-- Author: Noya
function SendErrorMessage(pID, string)
    Notifications:ClearBottom(pID)
    Notifications:Bottom(pID, {text=string, style={color='#E62020'}, duration=2})
    EmitSoundOnClient("General.Cancel", PlayerResource:GetPlayer(pID))
end

-- This function hides all hats (wearables) from the hero and store them into a handle variable
-- Author: Noya
function HideWearables(hero)
	hero.hiddenWearables = {} -- Keep every wearable handle in a table to show them later
	local model = hero:FirstMoveChild()
	while model do
		if model:GetClassname() == "dota_item_wearable" then
			model:AddEffects(EF_NODRAW) -- Set model hidden
			table.insert(hero.hiddenWearables, model)
		end
		model = model:NextMovePeer()
	end
end

-- This function unhides/shows wearables that were hidden with HideWearables() function.
-- Author: Noya
function ShowWearables(hero)
	for _, v in pairs(hero.hiddenWearables) do
		v:RemoveEffects(EF_NODRAW)
	end
end

-- This function is needed for changing models (for Arcanas for example)
-- Author: Noya
function SwapWearable(unit, target_model, new_model)
    local wearable = unit:FirstMoveChild()
    while wearable do
        if wearable:GetClassname() == "dota_item_wearable" then
            if wearable:GetModelName() == target_model then
                wearable:SetModel(new_model)
                return
            end
        end
        wearable = wearable:NextMovePeer()
    end
end

-- This function checks if this entity is a fountain or not; returns boolean value;
function CBaseEntity:IsFountain()
	if self:GetName() == "ent_dota_fountain_bad" or self:GetName() == "ent_dota_fountain_good" then
		return true
	end

	return false
end

-- This function checks if a given unit is Roshan, returns boolean value;
function IsRoshan(unit)
	return unit:IsRoshan()
end

-- This function checks if this unit is a fountain or not; returns boolean value;
function IsFountain(unit)
	return unit:IsFountain()
end

--[[ This function interrupts and hide the target hero, applies SuperStrongDispel and CustomPassiveBreak to the target,
    and creates a copy of the target for the caster, returns the hScript copy;
	Target hero has vision over the area where he is moved! You need a modifier to disable this vision;
	Copy/Clone of the target hero is not invulnerable! You need a modifier for that too;
	Used in many abilities ...
]]
function HideAndCopyHero(target, caster)
	if target and caster then
		-- Hiding on the spot
		target:Interrupt()
		target:InterruptChannel()
		target:AddNoDraw() -- needed for hiding the original hero

		-- Create a copy at the original's location
		local copy = CopyHero(target, caster)

		-- Hide the original in the corner of the map
		local corner
		if GetMapName() == "two_vs_two" then
			corner = Vector(2300,-2300,-322)
		else
			corner = Vector(7500,-7200,-322)
		end
		target:SetAbsOrigin(corner)

		local hidden_modifiers = {
			"modifier_firelord_arcana",
			"modifier_not_removed_with_super_strong_dispel_or_custom_passive_break",
		}

		-- Remove all buffs and debuffs from the target
		SuperStrongDispel(target, true, true)

		-- Remove passive modifiers from the target with Custom Passive Break
		CustomPassiveBreak(target, 100)

		-- Cycle through remaining hidden modifiers and bugging visual effects and remove them
		for i = 1, #hidden_modifiers do
			target:RemoveModifierByName(hidden_modifiers[i])
		end

		return copy
	else
		print("target or caster are nil values.")
		return
	end
end

--[[ This function creates a copy of the target for the caster, returns the hScript copy;
	Copy/Clone of the target hero is not invulnerable! You need a modifier for that too;
	Used in HideAndCopyHero and for custom super illusions (illusions that can use spells and items)
]]
function CopyHero(target, caster)
	if target and caster then
		local caster_team = caster:GetTeamNumber()
		local playerID = caster:GetPlayerOwnerID()
		local target_name = target:GetUnitName()
		local target_origin = target:GetAbsOrigin()
		local target_ability_count = target:GetAbilityCount()
		local target_HP = target:GetHealth()
		local target_MP = target:GetMana()
		local target_level = target:GetLevel()

		local ability_table = {
			"dark_ranger_charm", 			-- obvious reasons, weird interactions
			"paladin_eternal_devotion", 	-- disabling just in case, playerID issues
			"perun_electric_trap", 			-- crashes
			"archmage_mass_teleport", 		-- preventing abuse
			"dark_terminator_blink",        -- preventing abuse
			"special_bonus_reincarnation_250",
		}
		local item_table = {
			"item_tpscroll", 				-- preventing abuse
			"item_travel_boots", 			-- preventing abuse
			"item_travel_boots_2", 			-- preventing abuse
			"item_rapier",
			"item_gem",
			"item_aegis",
		}

		-- Creating copy of the target hero
		local copy = CreateUnitByName(target_name, target_origin, true, caster, nil, caster_team) -- handle hUnitOwner MUST be nil, else it will crash the game.
		copy:SetPlayerID(playerID)
		copy:SetControllableByPlayer(playerID, true)
		copy:SetOwner(caster:GetOwner())
		FindClearSpaceForUnit(copy, target_origin, false)

		-- Levelling up the Copy of the hero
		for i = 1, target_level-1 do
			copy:HeroLevelUp(false) -- false because we don't want to see level up effects
		end

		-- Recreate the items of the original, disabling some items, not ignoring items in backpack
		local disable_item = {}
		for itemSlot = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_9 do
			local item = target:GetItemInSlot(itemSlot)
			if item then
				local itemName = item:GetName()
				local newItem = CreateItem(itemName, copy, copy)
				local newItemName = newItem:GetName()
				disable_item[itemSlot+1] = 0
				for i = 1, #item_table do
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

		-- Remove tp scrolls and neutral items from the copy (they have special item slots)
		local u1 = copy:GetItemInSlot(DOTA_ITEM_TP_SCROLL)
		local u2 = copy:GetItemInSlot(DOTA_ITEM_NEUTRAL_SLOT)
		if u1 then
			copy:RemoveItem(u1)
		end
		if u2 then
			copy:RemoveItem(u2)
		end

		-- Enabling and disabling abilities on a copy
		copy:SetAbilityPoints(0)
		local disable_ability = {}
		for abilitySlot = 0, target_ability_count-1 do
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
				if disable_ability[abilitySlot+1] == 0 and abilityLevel > 0 then
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
		-- Disabling bounties because copy can die (even if its invulnerable it can still die: suicide abilities or axe's cut from above/culling blade)
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
		return
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
			"modifier_item_ring_of_basilius_aura",									-- Ring of Basilius Aura
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
		}
		if copy:IsAlive() then
			copy:Stop()
			copy:Interrupt()
			copy.died = false
		else
			-- MakeIllusion() and RemoveSelf() are not good here:
			-- Illusions must not deal damage over time (poisons etc.) -> automatic server crash if illusions have DoT
			-- Removed units must not deal damage over time! -> automatic server crash if DoT is still active after removing the unit
			copy:RespawnUnit()
			copy.died = true
		end
		copy:AddNoDraw() 	-- Hiding the hero
		HideWearables(copy)	-- Hiding hats/wearables if some are still visible
		-- Remove 99% of modifiers
		copy:AbsolutePurge()
		-- Remove passive modifiers with Custom Break
		CustomPassiveBreak(copy, 100)
		-- Cycle through hidden modifiers and remove them (Death, SuperStrongDispel and CustomPassiveBreak remove most modifiers but we need to make sure for remaining modifiers)
		for i = 1, #hidden_modifiers do
			copy:RemoveModifierByName(hidden_modifiers[i])
		end
		-- Moving the copy to the corner of the map underground (Hiding him for sure)
		local corner
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
		if location then
			original:SetAbsOrigin(location) -- Moving the original to location instantly
		else
			print("Original is revealed at the location where it was hidden")
			location = original:GetAbsOrigin()
		end
		FindClearSpaceForUnit(original, location, false)

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
		for i = 1, #hidden_abilities do
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
		"dark_ranger_custom_marksmanship",
		"life_stealer_custom_anabolic_frenzy",
		"paladin_divine_retribution",
		"queenofpain_custom_pain_steal",
		"firelord_flaming_presence",
		"stealth_assassin_desolate",
		"gambler_lucky_stars",
		"astral_trekker_time_constant",
		"astral_trekker_giant_growth",
		"lich_custom_freezing_touch",
		"brewmaster_custom_drunken_brawler",
		"alchemist_custom_philosophers_stone",
		"blademaster_custom_blade_dance",
	}
	local passive_modifiers = {
		"modifier_custom_marksmanship_passive",
		"modifier_anabolic_frenzy_passive",
		"modifier_retribution_aura_applier",
		"modifier_pain_steal_aura_applier",
		"modifier_firelord_presence_aura_applier",
		"modifier_stealth_assassin_desolate",
		"modifier_gambler_lucky_stars_passive",
		"modifier_time_constant",
		"modifier_giant_growth_passive",
		"modifier_lich_freezing_touch_passive",
		"modifier_custom_drunken_brawler_passive",
		"modifier_philosophers_stone_passive_buff",
		"modifier_custom_blade_dance_passive",
	}
	if unit and duration then
		for i = 1, #passive_modifiers do
			unit:RemoveModifierByName(passive_modifiers[i])
		end

		unit.custom_already_breaked = true

		if duration ~= 100 then
			Timers:CreateTimer(duration, function()
				for i = 1, #abilities_with_passives do
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
		for itemSlot = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_9 do
			local item = unit:GetItemInSlot(itemSlot)
			if item then
				local item_owner = item:GetPurchaser()
				local unit_owner = unit:GetOwner()
				local caster_owner = caster:GetOwner()

				-- Store original purchaser only for the first time when CustomItemDisable is called
				if item.original_purchaser == nil then
					item.original_purchaser = item_owner
				end

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
			if modifier then
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
							for i = 1, #passive_item_modifiers_exceptions do
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
		for itemSlot = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_9 do
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

				if item.original_purchaser then
					item:SetPurchaser(item.original_purchaser)
				end
			end
		end

		-- Enable dropping and selling items back
		unit:SetHasInventory(true)
		unit:SetCanSellItems(true)

		-- To reset unit's items and their passive modifiers: add an item and remove it
		-- HasAnyAvailableInventorySpace() is bugged in that it counts wards as empty inventory slots for some reason
		if unit:HasAnyAvailableInventorySpace() then
			local new_item = CreateItem("item_magic_wand", unit, unit)
			unit:AddItem(new_item)
			new_item:RemoveSelf()
		end

		unit:CalculateStatBonus(true)
	else
		print("unit is nil!")
	end
end

--[[ This function applies strong dispel and removes almost all debuffs;
	Can remove most debuffs that are not removable with strong dispel;
	Used in many abilities, HideAndCopyHero, HideTheCopyPermanently, ...
]]
function SuperStrongDispel(target, bRemoveAlmostAllDebuffs, bRemoveDispellableBuffs)
	if target then
		local BuffsCreatedThisFrameOnly = false
		local RemoveExceptions = false
		local RemoveStuns = false

		local function RemoveTableOfModifiersFromUnit(unit, t)
			for i = 1, #t do
				unit:RemoveModifierByName(t[i])
			end
		end

		if bRemoveAlmostAllDebuffs == true then

			RemoveStuns = true -- this ensures removing modifiers debuffs with "IsStunDebuff" "1"

			-- Abilities
			local ability_debuffs = { -- for most stuff: pierces BKB, doesn't get removed with BKB
				"modifier_axe_berserkers_call",
				"modifier_bane_nightmare_invulnerable",						-- invulnerable type
				-- custom:
				"modifier_custom_enfeeble_debuff",
				"modifier_entrapment",										-- Astral Trekker Net
				"modifier_purge_enemy_creep",
				"modifier_purge_enemy_hero",
				"modifier_time_stop",
				"modifier_time_stop_scepter",
				"modifier_volcano_stun",
			}

			-- Items
			local item_debuffs = {
				"modifier_heavens_halberd_debuff",        -- doesn't pierce BKB, doesn't get removed with BKB
				"modifier_item_nullifier_mute",           -- pierces BKB, doesn't get removed with BKB
				"modifier_item_skadi_slow",               -- pierces BKB, doesn't get removed with BKB
				"modifier_silver_edge_debuff",            -- doesn't pierce BKB, doesn't get removed with BKB
				-- custom:
				"modifier_pull_staff_active_buff",        -- doesn't pierce BKB, doesn't get removed with BKB
			}

			RemoveTableOfModifiersFromUnit(target, ability_debuffs)
			RemoveTableOfModifiersFromUnit(target, item_debuffs)

			-- Exceptions:
			-- modifier_charmed_hero                           (Dark Ranger Charm - not advisable)
			-- modifier_incinerate_stack                       (Fire Lord Incinerate - not advisable)
			-- modifier_custom_rupture                         (Blood Mage Rupture - it would be lame if dispellable)
			-- modifier_bloodseeker_rupture                    -- it would be lame
			-- modifier_doom_bringer_doom                      -- it would be lame
			-- modifier_mana_transfer_leash_debuff             (Mana Transfer/Drain leash)
			-- modifier_bakedanuki_futatsuiwas_curse           -- it would be lame
		end

		target:Purge(bRemoveDispellableBuffs, bRemoveAlmostAllDebuffs, BuffsCreatedThisFrameOnly, RemoveStuns, RemoveExceptions)
	else
		print("Target for Super Strong Dispel is nil.")
	end
end

-- Finding units in a trapezoid shape area
function FindUnitsinTrapezoid(team_number, vDirection, start_position, cache_unit, start_radius, end_radius, distance, target_team, target_type, target_flags, order, cache)
	if cache == nil then
		cache = false
	end
	if not order then
		order = FIND_ANY_ORDER
	end
	if not target_flags then
		print("Invalid number of arguments for FindUnitsinTrapezoid!")
		return
	end
	local circle = FindUnitsInRadius(team_number, start_position, cache_unit, distance+end_radius, target_team, target_type, target_flags, order, cache)
	local direction = vDirection
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

	local unit_table = {}

	for _, unit in pairs(circle) do
		if unit then
			local unit_location = unit:GetAbsOrigin()
			local vector1p = unit_location - vertex1
			local vector2p = unit_location - vertex2
			local vector3p = unit_location - vertex3
			local vector4p = unit_location - vertex4
			local cross1 = vector1.x * vector1p.y - vector1.y * vector1p.x
			local cross2 = vector2.x * vector2p.y - vector2.y * vector2p.x
			local cross3 = vector3.x * vector4p.y - vector3.y * vector4p.x
			local cross4 = vector4.x * vector3p.y - vector4.y * vector3p.x
			if (cross1 > 0 and cross2 > 0 and cross3 > 0 and cross4 > 0) or (cross1 < 0 and cross2 < 0 and cross3 < 0 and cross4 < 0) then
				table.insert(unit_table, unit)
			end
		end
    end
	return unit_table
end

-- Custom Cleave function
-- Required arguments: main_damage, damage_percent, cleave_origin, start_radius, end_radius, distance;
-- If start_radius is 0, it will be cone-shaped;
function CustomCleaveAttack(attacker, target, ability, main_damage, damage_percent, cleave_origin, start_radius, end_radius, distance, particle_cleave)
	if not distance then
		distance = 0
	end
	if not end_radius then
		print("Invalid number of arguments for CustomCleaveAttack!")
		return
	end
	if not attacker or attacker:IsNull() then
		print("Attacker/Cleaver is nil for CustomCleaveAttack!")
		return
	end
	if attacker.GetTeamNumber == nil or attacker.GetForwardVector == nil then
		print("Attacker/Cleaver is an invalid entity for CustomCleaveAttack!")
		return
	end
	local team_number = attacker:GetTeamNumber()
	local direction = attacker:GetForwardVector()
	local order = FIND_ANY_ORDER -- search order for FindUnitsInRadius

	local damage_table = {}
	damage_table.attacker = attacker

	local target_team
	local target_type
	local target_flags

	if ability then
		if ability.GetAbilityTargetTeam == nil then
			print("Ability is invalid for CustomCleaveAttack!")
			return
		end
		target_team = ability:GetAbilityTargetTeam()
		target_type = ability:GetAbilityTargetType()
		target_flags = ability:GetAbilityTargetFlags()
		damage_table.damage_type = ability:GetAbilityDamageType()
		damage_table.ability = ability
	else
		target_team = DOTA_UNIT_TARGET_TEAM_ENEMY
		target_type = bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
		target_flags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
		damage_table.damage_type = DAMAGE_TYPE_PHYSICAL
	end

	if not target or target:IsNull() then
		print("Attacked target is nil for CustomCleaveAttack!")
		return
	end

	-- Check for existence of GetUnitName method to determine if target is a unit or an item
	-- items don't have that method -> nil; if the target is an item, don't continue
	if target.GetUnitName == nil then
		--print("Cleave doesn't work when attacking items or runes!")
		return
	end

	if target:GetTeamNumber() == team_number and target_team == DOTA_UNIT_TARGET_TEAM_ENEMY then
		--print("Cleave doesn't work when attacking allies!")
		return
	end

	if target:IsTower() or target:IsBarracks() or target:IsBuilding() then
		--print("Cleave doesn't work when attacking buildings!")
		return
	end

	if target:IsOther() then
		--print("Cleave doesn't work when attacking ward-type units!")
		return
	end

	local affected_units = FindUnitsinTrapezoid(team_number, direction, cleave_origin, nil, start_radius, end_radius, distance, target_team, target_type, target_flags, order, false)

	-- Calculating damage and setting damage flags (this Cleave ignores armor!)
	damage_table.damage = main_damage*damage_percent/100
	damage_table.damage_flags = bit.bor(DOTA_DAMAGE_FLAG_IGNORES_PHYSICAL_ARMOR, DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL)

	for _, unit in pairs(affected_units) do
		if unit ~= target and unit ~= attacker then
			damage_table.victim = unit
			ApplyDamage(damage_table)
		end
	end

	-- Particles
	if particle_cleave then
		if particle_cleave == "particles/units/heroes/hero_kunkka/kunkka_spell_tidebringer.vpcf" then
			for _, unit in pairs(affected_units) do
				if unit ~= attacker then
					local tidebringer_hit_fx = ParticleManager:CreateParticle(particle_cleave, PATTACH_CUSTOMORIGIN, attacker)
					ParticleManager:SetParticleControlEnt(tidebringer_hit_fx, 0, unit, PATTACH_OVERHEAD_FOLLOW, "attach_hitloc", unit:GetAbsOrigin(), true)
					ParticleManager:SetParticleControlEnt(tidebringer_hit_fx, 1, unit, PATTACH_OVERHEAD_FOLLOW, "attach_hitloc", unit:GetAbsOrigin(), true)
					ParticleManager:SetParticleControlEnt(tidebringer_hit_fx, 2, unit, PATTACH_OVERHEAD_FOLLOW, "attach_hitloc", unit:GetAbsOrigin(), true)
					ParticleManager:ReleaseParticleIndex(tidebringer_hit_fx)
				end
			end
		else
			local cleave_pfx = ParticleManager:CreateParticle(particle_cleave, PATTACH_CUSTOMORIGIN, attacker)
			ParticleManager:SetParticleControl(cleave_pfx, 0, cleave_origin)
			ParticleManager:SetParticleControl(cleave_pfx, 2, cleave_origin)
			ParticleManager:SetParticleControl(cleave_pfx, 3, cleave_origin)
			ParticleManager:SetParticleControl(cleave_pfx, 4, cleave_origin)
			ParticleManager:SetParticleControl(cleave_pfx, 5, cleave_origin)
			ParticleManager:SetParticleControlForward(cleave_pfx, 0, direction)
			for _, unit in pairs(affected_units) do
				if unit ~= attacker and unit ~= target then
					for i = 6, 17 do
						ParticleManager:SetParticleControlEnt(cleave_pfx, i, unit, PATTACH_POINT, "attach_hitloc", unit:GetAbsOrigin(), true)
					end
				end
			end
			ParticleManager:ReleaseParticleIndex(cleave_pfx)
		end
	end
end

-- Probably not needed
function HasOtherUniqueAttackModifiers(unit)

	local list_of_passive_orbs ={
		"modifier_item_mask_of_death",
	}

	local list_of_autocast_orbs ={
		"modifier_dark_arrow",
		"modifier_incinerate_orb",
		"modifier_glaives_of_silence_orb",
	}

	if unit then
		for i = 1, #list_of_passive_orbs do
			if unit:HasModifier(list_of_passive_orbs[i]) then
				return true
			end
		end

		for j = 1, #list_of_autocast_orbs do
			local current_modifier_name = list_of_autocast_orbs[j]
			if unit:HasModifier(current_modifier_name) then
				local modifier = unit:FindModifierByName(current_modifier_name)
				if modifier then
					local ability = modifier:GetAbility()
					if ability then
						if ability:GetAutoCastState() then
							return true
						end
					end
				end
			end
		end

		return false
	end
end

function HasBit(flags, specific_flag)
	return bit.band(flags, specific_flag) == specific_flag
end
