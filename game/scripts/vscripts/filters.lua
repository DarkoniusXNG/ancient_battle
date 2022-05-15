-- Order Filter; order can be casting an ability, moving, clicking to attack, using radar, glyph etc.
function ancient_battle_gamemode:OrderFilter(filter_table)
	local order = filter_table.order_type
	local units = filter_table.units
	local playerID = filter_table.issuer_player_id_const

	-- If the order is an ability
	if order == DOTA_UNIT_ORDER_CAST_POSITION or order == DOTA_UNIT_ORDER_CAST_TARGET or order == DOTA_UNIT_ORDER_CAST_NO_TARGET or order == DOTA_UNIT_ORDER_CAST_TOGGLE or order == DOTA_UNIT_ORDER_CAST_TOGGLE_AUTO then
		local ability_index = filter_table.entindex_ability
		local ability = EntIndexToHScript(ability_index)
		local caster = EntIndexToHScript(units["0"])
		
		if caster:HasModifier("modifier_anti_magic_field_debuff") and (not ability:IsItem()) then
			ability:UseResources(true,false,true)
			local playerID = caster:GetPlayerOwnerID()
			SendErrorMessage(playerID, "Used Spell has no effect!")
			return false
		end

		if caster:HasModifier("modifier_drunken_haze_fizzle") and (not ability:IsItem()) then
			ability:UseResources(true,false,true)
			local playerID = caster:GetPlayerOwnerID()
			SendErrorMessage(playerID, "Used Spell has no effect!")
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
	local inflictor = keys.entindex_inflictor_const	-- keys.entindex_inflictor_const is nil if damage is not caused by an ability
	local damage_after_reductions = keys.damage 	-- keys.damage is damage after reductions without spell amplifications

	local damaging_ability
	if inflictor then
		damaging_ability = EntIndexToHScript(inflictor)
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
	
	if damage_after_reductions <= 0 then
		return false
	end
	
	-- Axe Blood Mist Power: Converting physical and magical damage of SPELLS to pure damage
	if damaging_ability and attacker:HasModifier("modifier_blood_mist_power_buff") then
		
		local ability = attacker:FindAbilityByName("axe_custom_blood_mist_power")
		if ability and ability ~= damaging_ability then
			
			-- Doesn't convert damage from items
			if (not damaging_ability:IsItem()) then
				
				-- Nullifying the damage of the spell (It will be reapplied later)
				keys.damage = 0
				
				-- Calculating original damage
				local original_damage = CalculateDamageBeforeReductions(victim, damage_after_reductions, damage_type)

				local damage_table = {}
				damage_table.victim = victim
				damage_table.attacker = attacker
				damage_table.damage_type = DAMAGE_TYPE_PURE
				damage_table.ability = ability
				damage_table.damage = math.floor(original_damage)
		
				ApplyDamage(damage_table)

				return false
			end
		end
	end
	
	-- Bane Enfeeble debuff: Reducing ALL damage of SPELLS by the percentage (It doesn't show properly on client)
	if damaging_ability and attacker:HasModifier("modifier_custom_enfeeble_debuff") then
		-- Doesn't reduce damage from items
		if not damaging_ability:IsItem() then
			local modifier = attacker:FindModifierByName("modifier_custom_enfeeble_debuff")
			local reduction
			if modifier then
				reduction = modifier.spell_damage_reduction
				local ability = modifier:GetAbility()
				if reduction == nil then
					if ability then
						reduction = ability:GetSpecialValueFor("spell_damage_reduction")
					else
						print("bane_custom_enfeeble not found.")
						reduction = 0
					end
				end
			else
				print("modifier_custom_enfeeble_debuff not found on attacker.")
				reduction = 0
			end
			
			-- Reduce damage
			keys.damage = math.floor(damage_after_reductions*(1-(reduction/100)))
		end
	end
	
	-- Orb of Reflection: Damage prevention and Reflecting all damage before reductions as Pure damage to the attacker
	-- if victim:HasModifier("modifier_item_orb_of_reflection_active_reflect") then

		-- -- Nullifying the damage to victim
		-- keys.damage = 0
		
		-- -- Reflect or not
		-- if not dont_reflect_flag then	
			-- local ability
			-- for i = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_9 do
				-- local this_item = victim:GetItemInSlot(i)
				-- if this_item then
					-- if this_item:GetName() == "item_orb_of_reflection" then
						-- ability = this_item
					-- end
				-- end
			-- end
			
			-- -- Initializing the value of original damage
			-- local original_damage = damage_after_reductions
			
			-- if damaging_ability then
				-- -- Damage came from an ability (spell or item)
				-- original_damage = CalculateDamageBeforeReductions(victim, damage_after_reductions, damage_type)
			-- else
				-- -- Damage came from a physical attack
				-- original_damage = math.max(attacker:GetAverageTrueAttackDamage(victim), CalculateDamageBeforeReductions(victim, damage_after_reductions, damage_type))
			-- end

			-- if ability and ability ~= damaging_ability and attacker ~= victim and (not attacker:IsTower()) and (not attacker:IsFountain()) then
				-- -- Reflect damage to the attacker
				-- local damage_table = {}
				-- damage_table.victim = attacker
				-- damage_table.attacker = victim
				-- damage_table.damage_type = DAMAGE_TYPE_PURE
				-- damage_table.ability = ability
				-- damage_table.damage = original_damage
				-- damage_table.damage_flags = bit.bor(DOTA_DAMAGE_FLAG_REFLECTION, DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL)
		
				-- ApplyDamage(damage_table)
				
				-- return false
			-- end
		-- end
	-- end
	
	if attacker:IsNull() or victim:IsNull() then
		return false
	end
	
	-- Blood Mirror: Damage redirection
	-- if victim:HasModifier("modifier_custom_blood_mirror_buff_ally_redirect") then
		-- local modifier = victim:FindModifierByName("modifier_custom_blood_mirror_buff_ally_redirect")
		
		-- local reduction
		-- local new_victim
		-- if modifier then
			-- reduction = modifier.damage_redirect_percent
			-- new_victim = modifier.redirect_target
		-- else
			-- print("modifier_custom_blood_mirror_buff_ally_redirect not found on victim.")
			-- reduction = 0
			-- new_victim = nil
		-- end
		
		-- if reduction == nil then
			-- reduction = 0
		-- end
		-- -- Reducing damage on victim
		-- keys.damage = math.floor(damage_after_reductions*(1-(reduction/100)))

		-- -- Calculating how much of the damage is redirected
		-- local damage_to_redirect = damage_after_reductions*reduction/100
		
		-- local damage_table = {}
		-- damage_table.attacker = attacker
		-- damage_table.damage_type = damage_type
		-- damage_table.damage_flags = DOTA_DAMAGE_FLAG_REFLECTION
		
		-- if damaging_ability then
			-- damage_table.ability = damaging_ability
		-- end
		
		-- if new_victim then
			-- -- Checking if the redirect_target has a debuff (just in case)
			-- if new_victim:HasModifier("modifier_custom_blood_mirror_debuff_caster") and damage_to_redirect > 0 then
				-- damage_table.victim = new_victim
				-- damage_table.damage = damage_to_redirect
				-- ApplyDamage(damage_table)
			-- end
		-- else
			-- print("redirect_target for Blood Mirror is nil")
		-- end
	-- end
	
	-- if victim:HasModifier("modifier_custom_blood_mirror_buff_caster_redirect") then
		-- local modifier = victim:FindModifierByName("modifier_custom_blood_mirror_buff_caster_redirect")

		-- local reduction
		-- local new_victim
		-- if modifier then
			-- reduction = modifier.damage_redirect_percent
			-- new_victim = modifier.redirect_target
		-- else
			-- print("modifier_custom_blood_mirror_buff_caster_redirect not found on victim.")
			-- reduction = 0
			-- new_victim = nil
		-- end
		
		-- if reduction == nil then
			-- reduction = 0
		-- end
		-- -- Reducing damage on victim
		-- keys.damage = math.floor(damage_after_reductions*(1-(reduction/100)))

		-- -- Calculating how much of the damage is redirected
		-- local damage_to_redirect = damage_after_reductions*reduction/100

		-- -- Creating a damage table
		-- local damage_table = {}
		-- damage_table.attacker = victim
		-- damage_table.damage_type = damage_type
		-- damage_table.damage_flags = DOTA_DAMAGE_FLAG_REFLECTION

		-- if damaging_ability then
			-- damage_table.ability = damaging_ability
		-- end

		-- if new_victim and not new_victim:IsNull() then
			-- -- Checking if the redirect_target has a debuff because it can be dispelled
			-- if new_victim:HasModifier("modifier_custom_blood_mirror_debuff_enemy") and damage_to_redirect > 0 then
				-- damage_table.victim = new_victim
				-- damage_table.damage = damage_to_redirect
				-- ApplyDamage(damage_table)
			-- end
		-- else
			-- print("redirect_target for Blood Mirror is nil")
		-- end
	-- end
	
	-- Orb of Reflection: Partial Damage return to the attacker (DOESN'T WORK ON ILLUSIONS!)
	-- if victim:HasModifier("item_modifier_orb_of_reflection_passive_return") and (not victim:HasModifier("modifier_item_orb_of_reflection_active_reflect")) and victim:IsRealHero() then

		-- -- Return or not
		-- if not dont_reflect_flag then	
			-- local ability
			-- for i = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_9 do
				-- local this_item = victim:GetItemInSlot(i)
				-- if this_item then
					-- if this_item:GetName() == "item_orb_of_reflection" then
						-- ability = this_item
					-- end
				-- end
			-- end
			
			-- -- Fetch the damage return amount/percentage
			-- local ability_level = ability:GetLevel() - 1
			-- local damage_return = ability:GetLevelSpecialValueFor("passive_damage_return", ability_level)
			
			-- -- Calculating damage that will be returned to attacker
			-- local new_damage = damage_after_reductions*damage_return/100
			
			-- if attacker:IsNull() or victim:IsNull() then
				-- return false
			-- end
			
			-- if ability and ability ~= damaging_ability and attacker ~= victim and (not attacker:IsTower()) and (not attacker:IsFountain()) then
				-- -- Returning Damage to the attacker
				-- local damage_table = {}
				-- damage_table.victim = attacker
				-- damage_table.attacker = victim
				-- damage_table.damage_type = damage_type
				-- damage_table.ability = ability
				-- damage_table.damage = new_damage
				-- damage_table.damage_flags = bit.bor(DOTA_DAMAGE_FLAG_REFLECTION, DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL, DOTA_DAMAGE_FLAG_BYPASSES_BLOCK)
				
				-- ApplyDamage(damage_table)
			-- end
		-- end
	-- end
	
	--if attacker:IsNull() or victim:IsNull() then
		--return false
	--end
	
	-- Infused Robe passive Damage Blocking any damage type after all reductions (DOESN'T WORK ON ILLUSIONS!)
	if victim:HasModifier("item_modifier_infused_robe_damage_block") and (not victim:HasModifier("item_modifier_infused_robe_damage_barrier")) and victim:IsRealHero() and victim ~= attacker then
		
		local ability
		for i = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_9 do
			local this_item = victim:GetItemInSlot(i)
			if this_item then
				if this_item:GetName() == "item_infused_robe" then
					ability = this_item
				end
			end
		end
		-- Fetch the damage block amount
		local ability_level = ability:GetLevel() - 1
		local block_chance = ability:GetLevelSpecialValueFor("damage_block_chance", ability_level)
		local damage_block = ability:GetLevelSpecialValueFor("damage_block", ability_level)
		
		if RollPercentage(block_chance) then
			-- Calculating new/reduced damage and blocked damage
			local new_damage = math.max(keys.damage - damage_block, 0)
			local blocked_damage = keys.damage - new_damage -- max(blocked_damage) = damage_block
			
			if attacker:IsNull() or victim:IsNull() then
				return false
			end
			
			if (not attacker:IsTower()) and (not attacker:IsFountain()) then
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
	end
	
	if attacker:IsNull() or victim:IsNull() then
		return false
	end
	
	-- Infused Robe Divine Barrier (Anti-Damage Shield/Shell)
	if victim:HasModifier("item_modifier_infused_robe_damage_barrier") and keys.damage > 0 then
		
		local ability
		for i = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_9 do
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
	
	-- Update the gold bounty of the hero before he dies
	if USE_CUSTOM_HERO_GOLD_BOUNTY then
		if attacker:IsControllableByAnyPlayer() and victim:IsRealHero() and keys.damage >= victim:GetHealth() then
			-- Get his killing streak
			local hero_streak = victim:GetStreak()
			-- Get his level
			local hero_level = victim:GetLevel()
			-- Adjust Gold bounty
			local gold_bounty
			if hero_streak > 2 then
				gold_bounty = HERO_KILL_GOLD_BASE + hero_level*HERO_KILL_GOLD_PER_LEVEL + (hero_streak-2)*HERO_KILL_GOLD_PER_STREAK
			else
				gold_bounty = HERO_KILL_GOLD_BASE + hero_level*HERO_KILL_GOLD_PER_LEVEL
			end

			victim:SetMinimumGoldBounty(gold_bounty)
			victim:SetMaximumGoldBounty(gold_bounty)
		end
	end

	-- Increase xp bounty of neutrals
	if victim:IsNeutralUnitType() and keys.damage >= victim:GetHealth() and not victim.changed_xp_bounty then
		local old_xp_bounty = victim:GetDeathXP()
		local xp_multiplier = 1.1
		local new_xp_bounty = old_xp_bounty * xp_multiplier

		victim:SetDeathXP(math.ceil(new_xp_bounty))
		victim.changed_xp_bounty = true
	end
	
	if keys.damage <= 0 then
		return false
	end
	
	return true
end

-- Modifier (buffs, debuffs) filter function
function ancient_battle_gamemode:ModifierFilter(keys)
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

	local xp_multiplier = 1.17
	if reason == DOTA_ModifyXP_CreepKill then
		--if GetMapName() == "two_vs_two" then
			--xp_multiplier = 1.5
		--end
		keys.experience = experience * xp_multiplier
	end

	return true
end

-- Tracking Projectile (attack and spell projectiles) filter function
function ancient_battle_gamemode:ProjectileFilter(keys)
	local can_be_dodged = keys.dodgeable				-- values: 1 for yes or 0 for no
	local ability_index = keys.entindex_ability_const	-- value if not ability: -1
	local source_index = keys.entindex_source_const
	local target_index = keys.entindex_target_const
	local expire_time = keys.expire_time
	local is_an_attack_projectile = keys.is_attack		-- values: 1 for yes or 0 for no
	local max_impact_time = keys.max_impact_time
	local projectile_speed = keys.move_speed

	return true
end

-- Bounty Rune Filter, can be used to modify Alchemist's Greevil Greed for example
function ancient_battle_gamemode:BountyRuneFilter(keys)
	return true
end

-- Healing Filter, can be used to modify how much hp regen and healing a unit is gaining
-- Triggers every time a unit gains health
function ancient_battle_gamemode:HealingFilter(keys)
	--PrintTable(keys)

	local healing_target_index = keys.entindex_target_const
	local heal_amount = keys.heal -- heal amount of the ability or health restored with hp regen during server tick

	local healer_index
	if keys.entindex_healer_const then
		healer_index = keys.entindex_healer_const
	end

	local healing_ability_index
	if keys.entindex_inflictor_const then
		healing_ability_index = keys.entindex_inflictor_const
	end
	
	local healing_target = EntIndexToHScript(healing_target_index)
	
	-- Find the source of the heal - the healer
	local healer
	if healer_index then
		healer = EntIndexToHScript(healer_index)
	else
		healer = healing_target -- hp regen
	end
	
	-- Find healing ability
	-- Abilities that give bonus hp regen don't count as healing abilities!!!
	local healing_ability
	if healing_ability_index then
		healing_ability = EntIndexToHScript(healing_ability_index)
	else
		healing_ability = nil -- hp regen
	end

	return true
end

-- Gold filter, can be used to modify how much gold player gains/loses
function ancient_battle_gamemode:GoldFilter(keys)
	--PrintTable(keys)

	local gold = keys.gold
    local playerID = keys.player_id_const
    local reason = keys.reason_const

	-- Disable all hero kill gold
	if DISABLE_ALL_GOLD_FROM_HERO_KILLS then
		if reason == DOTA_ModifyGold_HeroKill then
			return false
		end
	end

	return true
end

-- Inventory filter, triggers every time a unit picks up or buys an item, doesn't trigger when you change item's slot inside inventory
function ancient_battle_gamemode:InventoryFilter(keys)
	--PrintTable(keys)

	local unit_with_inventory_index = keys.inventory_parent_entindex_const -- -1 if not defined
	local item_index = keys.item_entindex_const
	local owner_index = keys.item_parent_entindex_const -- -1 if not defined
	local item_slot = keys.suggested_slot -- slot in which the item should be put, usually its -1 meaning put in first free slot

	--Item slots:
	-- Inventory slots: DOTA_ITEM_SLOT_1 - DOTA_ITEM_SLOT_9
	-- Backpack slots: DOTA_ITEM_SLOT_7 - DOTA_ITEM_SLOT_9
	-- Stash slots: DOTA_STASH_SLOT_1 - DOTA_STASH_SLOT_6

	local unit_with_inventory
	local unit_name
	if unit_with_inventory_index ~= -1 then
		unit_with_inventory = EntIndexToHScript(unit_with_inventory_index)
		unit_name = unit_with_inventory:GetUnitName()
	end

	local item = EntIndexToHScript(item_index)
	local item_name = item:GetName()

	local owner_of_this_item
	if owner_index ~= -1 then
		-- not reliable
		owner_of_this_item = EntIndexToHScript(owner_index)
	else
		owner_of_this_item = item:GetPurchaser()
	end

	local owner_name
	if owner_of_this_item then
		owner_name = owner_of_this_item:GetUnitName()
	end

	return true
end

-- For calculating damage of abilities before reductions
-- It can be used for calculating damage of attacks but it doesn't include damage block
function CalculateDamageBeforeReductions(unit, damage_after_reductions, damage_type)
	if damage_after_reductions == 0 then
		-- Unable to calculate damage before reductions if damage after reductions is 0
		return 0
	end
	if unit == nil then
		return nil
	end
	local original_damage = damage_after_reductions
	-- Is the damage_type physical or magical?
	if damage_type == DAMAGE_TYPE_PHYSICAL then
		-- Armor of the unit
		local armor = unit:GetPhysicalArmorValue(false)
		-- Physical damage is reduced by armor
		local damage_armor_reduction = 1-(armor*0.06/(1+0.06*(math.abs(armor))))
		-- In case the unit has infinite armor for some reason (to prevent division by zero)
		if damage_armor_reduction == 0 then
			damage_armor_reduction = 0.01
		end
		-- Physical damage equation: damage_after_reductions = original_damage * damage_armor_reduction
		original_damage = damage_after_reductions/damage_armor_reduction
	elseif damage_type == DAMAGE_TYPE_MAGICAL then
		-- Magic Resistance of the unit
		local magic_resistance = unit:GetMagicalArmorValue()
		-- Magical damage is reduced by magic resistance
		local damage_magic_resist_reduction = 1-magic_resistance
		-- In case the unit has 100% magic resistance (to prevent division by zero)
		if damage_magic_resist_reduction == 0 then
			damage_magic_resist_reduction = 0.01
		end
		-- Magical damage equation: damage_after_reductions = original_damage * damage_magic_resist_reduction
		original_damage = damage_after_reductions/damage_magic_resist_reduction
	end
	
	return original_damage
end
